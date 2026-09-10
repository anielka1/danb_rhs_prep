import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/data/repositories/drift_user_settings_repository.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/study_plan_preferences.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/experience_level.dart';
import 'package:danb_rhs_prep/study_plan/study_plan.dart';
import 'package:danb_rhs_prep/study_plan/planned_session_service.dart';
import 'package:danb_rhs_prep/study_plan/study_schedule_service.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_controller.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import '../data/local/schema_v2_snapshot.dart';
import 'fixtures.dart';

void main() {
  final package = fixture(), day = DateTime.utc(2026, 9, 10);
  final premium = Entitlement(
      tier: EntitlementTier.premium,
      source: EntitlementSource.promotional,
      lastVerifiedAt: day);
  final prefs =
      StudyPlanPreferences(weekdays: [1, 2, 3, 4, 5, 6, 7], minutes: 30);
  test(
      'durable planned start, retry, restart, same order and reduced daily budget',
      () async {
    final dir = Directory.systemTemp.createTempSync('plan-flow');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/test.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    var repo = DriftProgressRepository(db);
    final plan = const StudyPlanPolicy().project(
        now: day,
        localToday: day,
        timezone: 'Test',
        exam: package.exam,
        preferences: prefs,
        pool: package.questions,
        attempts: [],
        examDate: day.add(const Duration(days: 30)));
    const service = PlannedSessionService();
    var c = await service.start(
        package: package,
        repository: repo,
        entitlement: premium,
        now: () => day,
        day: plan.days.first);
    final ids = c.session.questionIds;
    await c.submitAnswer('a', confident: true, activeDurationSeconds: 90);
    final attempt = (await repo.answerAttemptsForExam(package.exam.id)).single;
    await repo.recordAnswerAttempt(attempt);
    expect((await repo.answerAttemptsForExam(package.exam.id)).length, 1);
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    repo = DriftProgressRepository(db);
    addTearDown(db.close);
    c = await service.start(
        package: package,
        repository: repo,
        entitlement: premium,
        now: () => day,
        day: plan.days.last);
    expect(c.session.questionIds, ids);
    expect(c.answeredCount, 1);
    expect(c.currentIndex, 1);
    final history = await repo.answerAttemptsForExam(package.exam.id);
    expect(history.single.confident, true);
    expect(history.single.activeDurationSeconds, 90);
    final p = const StudyPlanPolicy().project(
        now: day,
        localToday: day,
        timezone: 'Test',
        exam: package.exam,
        preferences: prefs,
        pool: package.questions,
        attempts: history);
    expect(p.days.first.budgetSeconds, 1710);
    expect(p.reviews.single.stage, 1);
  });
  test('diagnostic writes diagnostic attempts and uses config quotas',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftProgressRepository(db);
    final c = await const PlannedSessionService().start(
        package: package,
        repository: repo,
        entitlement: premium,
        now: () => day,
        diagnostic: true);
    expect(c.questions.length, package.exam.freeTier.diagnosticQuestions);
    expect(
        c.questions
            .where((q) => q.domainId == package.exam.domains.first.id)
            .length,
        7);
    await c.submitAnswer('a');
    expect(
        (await repo.answerAttemptsForExam(package.exam.id)).single.sessionType,
        AttemptSessionType.diagnostic);
  });
  test(
      'reserve used by mock selector, measured before start, cancel releases, reset clears schedule',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftProgressRepository(db);
    const service = StudyScheduleService();
    final date = day.add(const Duration(days: 5));
    await service.change(
        repository: repo,
        package: package,
        entitlement: premium,
        now: day,
        date: date,
        type: StudyDayType.mock,
        mockMinutes: 60,
        reserveUnseen: true);
    final reserved =
        (await repo.studySchedule(package.exam.id)).single.reservedQuestionIds;
    expect(reserved.length, 75);
    final c = MockExamController(
        blueprint: MockExamBlueprint.fromPackage(package),
        repository: repo,
        entitlement: premium,
        now: () => day);
    await c.load();
    await c.start();
    expect(c.attempt!.questionIds.toSet(), reserved.toSet());
    expect(c.attempt!.seenBeforeStartCount, 0);
    await service.change(
        repository: repo,
        package: package,
        entitlement: premium,
        now: day,
        date: date,
        type: StudyDayType.rest);
    expect(
        (await repo.studySchedule(package.exam.id)).single.reservedQuestionIds,
        isEmpty);
    expect(
        (await repo.mockAttemptsForExam(package.exam.id))
            .single
            .questionIds
            .toSet(),
        reserved.toSet());
    await repo.resetProgressForExam(package.exam.id);
    expect(await repo.studySchedule(package.exam.id), isEmpty);
  });
  test('mock rejects a 30-minute slot and history cannot be moved', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftProgressRepository(db);
    await expectLater(
        const StudyScheduleService().change(
            repository: repo,
            package: package,
            entitlement: premium,
            now: day,
            date: day.add(const Duration(days: 2)),
            type: StudyDayType.mock,
            mockMinutes: 30),
        throwsStateError);
    await expectLater(
        const StudyScheduleService().change(
            repository: repo,
            package: package,
            entitlement: premium,
            now: day,
            date: day,
            type: StudyDayType.rest),
        throwsStateError);
  });
  test(
      'profile changes preserve availability, theme and original question goal',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftUserSettingsRepository(db);
    final old = UserProfile.fromOnboarding(
            examId: package.exam.id,
            experienceLevel: ExperienceLevel.retakingExam,
            examDateSelection:
                ExamDateSelection(precision: ExamDatePrecision.notScheduled),
            themePreference: ThemePreference.dark,
            now: day)
        .copyWith(studyPlanPreferences: prefs, dailyGoalQuestions: 17);
    await repo.saveProfile(old);
    final loaded = await repo.loadProfile(package.exam.id);
    final updated = UserProfile.fromOnboarding(
        examId: package.exam.id,
        experienceLevel: ExperienceLevel.studyingAlready,
        examDateSelection: ExamDateSelection(
            precision: ExamDatePrecision.exact, date: DateTime(2026, 10, 30)),
        themePreference: ThemePreference.dark,
        now: day,
        existing: loaded);
    await repo.saveProfile(updated);
    final actual = await repo.loadProfile(package.exam.id);
    expect(actual!.studyPlanPreferences, prefs);
    expect(actual.dailyGoalQuestions, 17);
    expect(actual.themePreference, ThemePreference.dark);
  });
  test(
      'real schema3 upgrades additive without invented confidence or availability',
      () async {
    final dir = Directory.systemTemp.createTempSync('plan-migration');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final old = SchemaV2Snapshot(NativeDatabase(file));
    await old.into(old.answerAttemptsV2).insert(
        AnswerAttemptsV2Companion.insert(
            id: 'old',
            examId: package.exam.id,
            questionId: 'old-q',
            domainId: 'd',
            topicId: 't',
            difficulty: 2,
            sessionId: 's',
            sessionType: 'practice',
            selectedAnswerId: 'a',
            isCorrect: true,
            answeredAt: day,
            contentVersion: const Value('old')));
    // Freeze the exact three columns added by the released v3 migration.
    await old.customStatement(
        'ALTER TABLE answer_attempts ADD COLUMN question_version INTEGER');
    await old.customStatement(
        'ALTER TABLE answer_attempts ADD COLUMN correct_answer_id TEXT');
    await old.customStatement(
        'ALTER TABLE answer_attempts ADD COLUMN explanation TEXT');
    await old.customStatement('PRAGMA user_version = 3');
    await old.close();
    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    final repo = DriftProgressRepository(db);
    final history = await repo.answerAttemptsForExam(package.exam.id);
    expect(db.schemaVersion, 4);
    expect(history.single.id, 'old');
    expect(history.single.contentVersion, 'old');
    expect(history.single.confident, isNull);
    expect(history.single.activeDurationSeconds, isNull);
    expect(history.single.localAnsweredDate, isNull);
    expect(await repo.studySchedule(package.exam.id), isEmpty);
  });
  test(
      'content retirement releases a reserve that would remove ordinary topic coverage',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftProgressRepository(db);
    await const StudyScheduleService().change(
        repository: repo,
        package: package,
        entitlement: premium,
        now: day,
        date: day.add(const Duration(days: 5)),
        type: StudyDayType.mock,
        mockMinutes: 60,
        reserveUnseen: true);
    final reserved = (await repo.studySchedule(package.exam.id))
        .single
        .reservedQuestionIds
        .toSet();
    final topic =
        package.questions.firstWhere((q) => reserved.contains(q.id)).topicId;
    final updated = ContentPackage(
        exam: package.exam,
        contentVersion: package.contentVersion,
        sourceVersion: package.sourceVersion,
        generatedAt: package.generatedAt,
        questions: package.questions
            .where((q) => q.topicId != topic || reserved.contains(q.id))
            .toList());
    expect(
        await effectiveMockReserve(
            repository: repo, package: updated, entitlement: premium, now: day),
        isEmpty);
  });
}
