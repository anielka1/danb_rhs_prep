import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';

void main() {
  AnswerAttempt buildAttempt({
    String id = 'attempt-1',
    bool isCorrect = true,
    String? contentVersion,
  }) {
    return AnswerAttempt(
      id: id,
      examId: 'danb-rhs',
      questionId: 'q1',
      domainId: 'radiation-protection',
      topicId: 'shielding',
      difficulty: 3,
      sessionId: 'session-1',
      sessionType: AttemptSessionType.practice,
      selectedAnswerId: 'a1',
      isCorrect: isCorrect,
      answeredAt: DateTime.utc(2026, 1, 1, 12),
      contentVersion: contentVersion,
    );
  }

  test('equal field values produce equal instances and hash codes', () {
    final a = buildAttempt();
    final b = buildAttempt();
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('a different outcome produces an unequal attempt', () {
    final a = buildAttempt(isCorrect: true);
    final b = buildAttempt(isCorrect: false);
    expect(a, isNot(equals(b)));
  });

  test('a different id produces an unequal attempt', () {
    final a = buildAttempt(id: 'attempt-1');
    final b = buildAttempt(id: 'attempt-2');
    expect(a, isNot(equals(b)));
  });

  test('contentVersion defaults to null and participates in equality', () {
    final withoutVersion = buildAttempt();
    expect(withoutVersion.contentVersion, isNull);

    final withVersion = buildAttempt(contentVersion: '2026.1');
    expect(withVersion, isNot(equals(withoutVersion)));
    expect(withVersion.contentVersion, '2026.1');
    expect(withVersion, equals(buildAttempt(contentVersion: '2026.1')));
  });
}
