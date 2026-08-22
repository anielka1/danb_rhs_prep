import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';

void main() {
  MockAttempt buildAttempt({
    Map<String, String> answers = const {},
    Set<String> flagged = const {},
    MockAttemptStatus status = MockAttemptStatus.inProgress,
    DateTime? completedAt,
    int? correctCount,
  }) {
    return MockAttempt(
      id: 'mock-1',
      examId: 'danb-rhs',
      questionIds: const ['q1', 'q2', 'q3'],
      answers: answers,
      flaggedQuestionIds: flagged,
      status: status,
      startedAt: DateTime.utc(2026, 1, 1),
      durationMinutes: 60,
      completedAt: completedAt,
      correctCount: correctCount,
    );
  }

  test('equal field values produce equal instances and hash codes', () {
    final a = buildAttempt(answers: const {'q1': 'a1'});
    final b = buildAttempt(answers: const {'q1': 'a1'});
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('answers and flags are not modifiable', () {
    final attempt = buildAttempt(answers: const {'q1': 'a1'});
    expect(() => attempt.answers['q2'] = 'a2', throwsUnsupportedError);
    expect(
      () => attempt.flaggedQuestionIds.add('q2'),
      throwsUnsupportedError,
    );
  });

  test('answeredCount reflects the number of recorded answers', () {
    final attempt = buildAttempt(answers: const {'q1': 'a1', 'q2': 'a2'});
    expect(attempt.answeredCount, 2);
  });

  test('copyWith can complete an attempt with a score', () {
    final attempt = buildAttempt(answers: const {'q1': 'a1'});
    final completedAt = DateTime.utc(2026, 1, 1, 1);

    final completed = attempt.copyWith(
      status: MockAttemptStatus.completed,
      completedAt: completedAt,
      correctCount: 1,
    );

    expect(completed.status, MockAttemptStatus.completed);
    expect(completed.correctCount, 1);
  });

  test('an answer for a question outside the set violates the invariant', () {
    expect(
      () => buildAttempt(answers: const {'unknown-question': 'a1'}),
      throwsArgumentError,
    );
  });

  test('a flag for a question outside the set violates the invariant', () {
    expect(
      () => buildAttempt(flagged: const {'unknown-question'}),
      throwsArgumentError,
    );
  });

  test('a completed status without a correct count violates the invariant', () {
    expect(
      () => buildAttempt(
        status: MockAttemptStatus.completed,
        completedAt: DateTime.utc(2026, 1, 1, 1),
      ),
      throwsArgumentError,
    );
  });
}
