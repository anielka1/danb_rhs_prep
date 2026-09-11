import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/study_plan_preferences.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/study_plan/study_plan.dart';
import 'package:danb_rhs_prep/study_plan/study_metrics.dart';
import 'fixtures.dart';

void main() {
  final package = fixture(),
      today = DateTime.utc(2026, 9, 10),
      policy = const StudyPlanPolicy();
  final preferences =
      StudyPlanPreferences(weekdays: [1, 2, 3, 4, 5, 6, 7], minutes: 45);
  test('success intervals 1/3/7/14; same-day and retry no extra stage', () {
    final q = package.questions.first;
    final h = <AnswerAttempt>[];
    for (var i = 0; i < 4; i++) {
      final day = today.add(Duration(days: i * 10));
      h.add(answer(q, day, confident: true));
      final r =
          policy.reviewQueue(attempts: h, preferences: preferences).single;
      expect(r.stage, i + 1);
      expect(r.dueDate.difference(day).inDays, [1, 3, 7, 14][i]);
    }
    h.add(h.last);
    h.add(answer(q, today.add(const Duration(days: 30)),
        id: 'same-day', confident: true));
    expect(
        policy.reviewQueue(attempts: h, preferences: preferences).single.stage,
        4);
    h.add(answer(q, today.add(const Duration(days: 31)), confident: false));
    expect(
        policy.reviewQueue(attempts: h, preferences: preferences).single.stage,
        0);
  });
  test('neutral confidence does not assert mastery and weekends shift', () {
    final prefs = StudyPlanPreferences(weekdays: [1], minutes: 15);
    final r = policy.reviewQueue(
        attempts: [answer(package.questions.first, today)],
        preferences: prefs).single;
    expect(r.stage, 0);
    expect(r.dueDate.weekday, DateTime.monday);
  });
  test(
      'first accuracy separate from review accuracy and tiny samples not retained',
      () {
    final q = package.questions.first;
    final history = [
      answer(q, today, correct: false),
      answer(q, today.add(const Duration(days: 1)), correct: true)
    ];
    final metrics = StudyMetrics(
        pool: package.questions,
        history: history,
        reviews:
            policy.reviewQueue(attempts: history, preferences: preferences),
        today: today);
    expect(metrics.firstAccuracy, 0);
    expect(metrics.reviewAccuracy, 1);
    expect(metrics.topics.first.status, isNot(TopicLearningStatus.retained));
  });
  test('availability codec rejects corrupt values and never invents minutes',
      () {
    expect(StudyPlanPreferences.decode(null), isNull);
    expect(
        StudyPlanPreferences.decode('{"version":1,"weekdays":[],"minutes":10}'),
        isNull);
    expect(StudyPlanPreferences.decode(preferences.encode()), preferences);
  });
  test('same-day error then success cannot advance a review stage', () {
    final q = package.questions.first;
    final h = [
      answer(q, today, id: 'wrong', correct: false),
      answer(q, today, id: 'right', confident: true)
    ];
    expect(
        policy.reviewQueue(attempts: h, preferences: preferences).single.stage,
        0);
  });
}
