import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/study_plan_preferences.dart';
import 'package:danb_rhs_prep/study_plan/study_plan.dart';
import 'fixtures.dart';

void main() {
  final package = fixture(), today = DateTime.utc(2026, 9, 10);
  final prefs =
      StudyPlanPreferences(weekdays: [1, 2, 3, 4, 5, 6, 7], minutes: 45);
  const policy = StudyPlanPolicy();
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
