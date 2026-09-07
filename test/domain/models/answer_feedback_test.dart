import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/answer_feedback.dart';

void main() {
  AnswerFeedback buildFeedback({
    String questionId = 'q1',
    int questionVersion = 1,
    bool isCorrect = true,
    String? contentVersion,
  }) {
    return AnswerFeedback(
      questionId: questionId,
      questionVersion: questionVersion,
      selectedAnswerId: 'a1',
      correctAnswerId: 'a1',
      isCorrect: isCorrect,
      explanation: 'Because reasons.',
      answeredAt: DateTime.utc(2026, 1, 1, 12),
      contentVersion: contentVersion,
    );
  }

  test('equal field values produce equal instances and hash codes', () {
    final a = buildFeedback();
    final b = buildFeedback();
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('a different outcome produces an unequal feedback', () {
    final a = buildFeedback(isCorrect: true);
    final b = buildFeedback(isCorrect: false);
    expect(a, isNot(equals(b)));
  });

  test('a different question version produces an unequal feedback', () {
    final a = buildFeedback(questionVersion: 1);
    final b = buildFeedback(questionVersion: 2);
    expect(a, isNot(equals(b)));
  });

  test('contentVersion defaults to null and participates in equality', () {
    final withoutVersion = buildFeedback();
    expect(withoutVersion.contentVersion, isNull);

    final withVersion = buildFeedback(contentVersion: '2026.1');
    expect(withVersion, isNot(equals(withoutVersion)));
    expect(withVersion.contentVersion, '2026.1');
    expect(withVersion, equals(buildFeedback(contentVersion: '2026.1')));
  });
}
