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
import 'package:danb_rhs_prep/study_plan/planned_session_service.dart';
import '../data/local/schema_v2_snapshot.dart';
import 'fixtures.dart';
import 'package:danb_rhs_prep/practice_session/practice_generator.dart';

void main() {
  final package = fixture(), day = DateTime.utc(2026, 9, 10);
  final premium = Entitlement(
      tier: EntitlementTier.premium,
      source: EntitlementSource.promotional,
      lastVerifiedAt: day);
  final prefs =
      StudyPlanPreferences(weekdays: [1, 2, 3, 4, 5, 6, 7], minutes: 30);
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
      'starting-check mistakes feed actual weak-topic practice and do not consume the free practice limit',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftProgressRepository(db);
    final c = await const PlannedSessionService().start(
        package: package,
        repository: repo,
        entitlement: Entitlement.free(lastVerifiedAt: day),
        now: () => day,
        diagnostic: true);
    final q = c.currentQuestion;
    await c.submitAnswer(
        q.answers.firstWhere((a) => a.id != q.correctAnswerId).id);
    final states = await repo.questionStatesForExam(package.exam.id);
    expect(states.single.timesIncorrect, 1);
    final weak = PracticeGenerator.select(
        package: package,
        questionStates: states,
        focus: PracticeFocus.weakAreas,
        requestedCount: 10);
    expect(weak.questions.every((item) => item.topicId == q.topicId), isTrue);
    expect(
        practiceAttemptsAnsweredToday(
            attempts: await repo.answerAttemptsForExam(package.exam.id),
            now: day),
        0);
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
    expect(db.schemaVersion, 5);
    expect(history.single.id, 'old');
    expect(history.single.contentVersion, 'old');
    expect(history.single.confident, isNull);
    expect(history.single.activeDurationSeconds, isNull);
    expect(history.single.localAnsweredDate, isNull);
    expect(await repo.studySchedule(package.exam.id), isEmpty);
  });
}
