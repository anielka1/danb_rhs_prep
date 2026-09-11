import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/study_plan_preferences.dart';
import 'package:danb_rhs_prep/study_plan/planned_session_service.dart';
import 'package:danb_rhs_prep/study_plan/study_plan.dart';
import 'fixtures.dart';

void main() {
  final package = fixture(), today = DateTime.utc(2026, 9, 10);
  final prefs =
      StudyPlanPreferences(weekdays: [1, 2, 3, 4, 5, 6, 7], minutes: 45);
  const policy = StudyPlanPolicy(initialNewSeconds: 60);
  test(
      'daily commitment survives partial answers, SQLite restart and completion',
      () async {
    final dir = Directory.systemTemp.createTempSync('plan-stability');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/progress.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    var repo = DriftProgressRepository(db);
    Future<StudyPlanProjection> project() async => policy.project(
        now: today,
        localToday: today,
        timezone: 'Test',
        exam: package.exam,
        preferences: prefs,
        pool: package.questions,
        attempts: await repo.answerAttemptsForExam(package.exam.id),
        sessions: await repo.practiceSessionsForExam(package.exam.id),
        examDate: today.add(const Duration(days: 30)));
    final initial = await project();
    expect(
        [initial.finalDays, initial.bufferDays, initial.studyDays], [5, 3, 22]);
    final target = initial.days.first.newIds.length;
    expect(target, 23);
    final premium = Entitlement(
        tier: EntitlementTier.premium,
        source: EntitlementSource.promotional,
        lastVerifiedAt: today);
    var controller = await const PlannedSessionService().start(
        package: package,
        repository: repo,
        entitlement: premium,
        now: () => today,
        day: initial.days.first);
    final assigned = controller.session.questionIds;
    for (var i = 0; i < 18; i++) {
      controller.moveTo(i);
      await controller.submitAnswer('a', activeDurationSeconds: 60);
    }
    final partial = await project();
    expect(18 + partial.days.first.newIds.length, target);
    expect(partial.days.first.newIds, assigned.skip(18));
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    repo = DriftProgressRepository(db);
    addTearDown(db.close);
    expect((await project()).days.first.newIds, assigned.skip(18));
    controller = await const PlannedSessionService().start(
        package: package,
        repository: repo,
        entitlement: premium,
        now: () => today);
    expect(controller.session.questionIds, assigned);
    for (var i = 18; i < target; i++) {
      controller.moveTo(i);
      await controller.submitAnswer('a', activeDurationSeconds: 5);
    }
    await controller.complete();
    expect((await project()).days.first.questionIds, isEmpty);
    expect((await project()).days.first.status, StudyDayStatus.completed);
  });
  test('changing today to a day off preserves recorded work in the calendar',
      () {
    final saved = PracticeSession(
        id: 'done',
        examId: package.exam.id,
        mode: PracticeMode.planned,
        questionIds: [package.questions.first.id],
        status: SessionStatus.completed,
        startedAt: today,
        completedAt: today,
        planDate: dateKey(today));
    final p = policy.project(
        now: today,
        localToday: today,
        timezone: 'Test',
        exam: package.exam,
        preferences: prefs,
        pool: package.questions,
        attempts: [answer(package.questions.first, today, seconds: 60)],
        sessions: [saved],
        overrides: {dateKey(today): StudyDayType.rest});
    expect(p.days.first.type, StudyDayType.rest);
    expect(p.days.first.recordedAnswers, 1);
    expect(p.days.first.spentSeconds, 60);
  });
  test('exhausted quota does not label an unfinished saved session completed',
      () {
    final saved = PracticeSession(
        id: 'active',
        examId: package.exam.id,
        mode: PracticeMode.planned,
        questionIds: package.questions.take(2).map((q) => q.id).toList(),
        status: SessionStatus.inProgress,
        startedAt: today,
        planDate: dateKey(today));
    final p = policy.project(
        now: today,
        localToday: today,
        timezone: 'Test',
        exam: package.exam,
        preferences: prefs,
        pool: package.questions,
        attempts: [answer(package.questions.first, today)],
        sessions: [saved],
        remainingUtcQuota: 0);
    expect(p.days.first.questionIds, isEmpty);
    expect(p.days.first.status, StudyDayStatus.inProgress);
  });
  final q = package.questions.first;
  List<AnswerAttempt> established() => [
        answer(q, today.subtract(const Duration(days: 20)), confident: true),
        answer(q, today.subtract(const Duration(days: 19)), confident: true),
        answer(q, today.subtract(const Duration(days: 16)), confident: true),
      ];
  test(
      'overdue neutral answer schedules short review, not inherited seven days',
      () {
    final h = established()..add(answer(q, today));
    final r = policy.reviewQueue(attempts: h, preferences: prefs).single;
    expect(r.stage, 3);
    expect(r.dueDate, today.add(const Duration(days: 1)));
  });
  test(
      'early neutral answer never delays existing due date and repeated neutrals stay short',
      () {
    final h = established();
    final early = today.subtract(const Duration(days: 15));
    h.add(answer(q, early));
    expect(policy.reviewQueue(attempts: h, preferences: prefs).single.dueDate,
        early.add(const Duration(days: 1)));
    for (var i = 0; i < 4; i++) {
      final d = today.add(Duration(days: i));
      h.add(answer(q, d));
      final r = policy.reviewQueue(attempts: h, preferences: prefs).single;
      expect(r.stage, 3);
      expect(r.dueDate, d.add(const Duration(days: 1)));
    }
  });
  test('same-day correction after error leaves stage zero and next study day',
      () {
    final h = established()
      ..add(answer(q, today, id: 'error', correct: false))
      ..add(answer(q, today, id: 'correction', confident: true));
    final r = policy.reviewQueue(attempts: h, preferences: prefs).single;
    expect(r.stage, 0);
    expect(r.dueDate, today.add(const Duration(days: 1)));
  });
}
