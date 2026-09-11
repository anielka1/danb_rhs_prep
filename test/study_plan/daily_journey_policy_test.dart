import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/study_plan_preferences.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/study_plan/study_plan.dart';
import 'fixtures.dart';

void main() {
  final p = fixture(), now = DateTime.utc(2026, 9, 11);
  final prefs =
      StudyPlanPreferences(weekdays: [1, 2, 3, 4, 5, 6, 7], minutes: 30);
  test(
      'whole-session estimate includes explanation reading; quick taps cannot collapse pace',
      () {
    final plan = const StudyPlanPolicy().project(
        now: now,
        localToday: now,
        timezone: 'Test',
        exam: p.exam,
        preferences: prefs,
        pool: p.questions,
        attempts: [
          for (var i = 0; i < 5; i++) answer(p.questions[i], now, seconds: 5)
        ]);
    expect(plan.newSeconds, greaterThanOrEqualTo(90));
    expect(plan.reviewSeconds, greaterThan(45));
    expect(plan.days.first.budgetSeconds, lessThan(1800 - 25));
  });
  test('historical partial day keeps its unfinished saved task IDs', () {
    final yesterday = now.subtract(const Duration(days: 1));
    final saved = PracticeSession(
        id: 'session-${yesterday.day}',
        examId: p.exam.id,
        mode: PracticeMode.planned,
        questionIds: p.questions.take(3).map((q) => q.id).toList(),
        status: SessionStatus.inProgress,
        startedAt: yesterday,
        planDate: dateKey(yesterday));
    final plan = const StudyPlanPolicy().project(
        now: now,
        localToday: now,
        timezone: 'Test',
        exam: p.exam,
        preferences: prefs,
        pool: p.questions,
        attempts: [answer(p.questions.first, yesterday)],
        sessions: [saved]);
    final old = plan.days.first;
    expect(old.recordedAnswers, 1);
    expect(old.questionIds, p.questions.skip(1).take(2).map((q) => q.id));
  });
}
