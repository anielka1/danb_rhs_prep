import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/question_state.dart';

void main() {
  test('an unseen question has no answer history', () {
    final state = QuestionState.unseen(examId: 'danb-rhs', questionId: 'q1');

    expect(state.hasBeenAnswered, isFalse);
    expect(state.timesSeen, 0);
    expect(state.lastAnsweredAt, isNull);
  });

  test('a correct attempt increments seen, correct, and streak counts', () {
    final unseen = QuestionState.unseen(examId: 'danb-rhs', questionId: 'q1');
    final answeredAt = DateTime.utc(2026, 1, 1);

    final state = unseen.withAttempt(isCorrect: true, answeredAt: answeredAt);

    expect(state.timesSeen, 1);
    expect(state.timesCorrect, 1);
    expect(state.timesIncorrect, 0);
    expect(state.consecutiveCorrect, 1);
    expect(state.hasBeenAnswered, isTrue);
    expect(state.lastAnsweredAt, answeredAt);
  });

  test('an incorrect attempt resets the correct streak', () {
    final streaking = QuestionState.unseen(examId: 'danb-rhs', questionId: 'q1')
        .withAttempt(isCorrect: true, answeredAt: DateTime.utc(2026, 1, 1))
        .withAttempt(isCorrect: true, answeredAt: DateTime.utc(2026, 1, 2));
    expect(streaking.consecutiveCorrect, 2);

    final broken = streaking.withAttempt(
      isCorrect: false,
      answeredAt: DateTime.utc(2026, 1, 3),
    );

    expect(broken.consecutiveCorrect, 0);
    expect(broken.timesSeen, 3);
    expect(broken.timesIncorrect, 1);
  });

  test('copyWith preserves identity fields and overrides the rest', () {
    final state = QuestionState.unseen(examId: 'danb-rhs', questionId: 'q1');
    final bookmarked = state.copyWith(bookmarked: true);

    expect(bookmarked.examId, state.examId);
    expect(bookmarked.questionId, state.questionId);
    expect(bookmarked.bookmarked, isTrue);
  });

  test('correct plus incorrect counts exceeding seen violates the invariant',
      () {
    expect(
      () => QuestionState(
        examId: 'danb-rhs',
        questionId: 'q1',
        bookmarked: false,
        timesSeen: 1,
        timesCorrect: 1,
        timesIncorrect: 1,
        consecutiveCorrect: 0,
        lastAnsweredAt: DateTime.utc(2026, 1, 1),
      ),
      throwsArgumentError,
    );
  });

  test('a seen question without lastAnsweredAt violates the invariant', () {
    expect(
      () => QuestionState(
        examId: 'danb-rhs',
        questionId: 'q1',
        bookmarked: false,
        timesSeen: 1,
        timesCorrect: 1,
        timesIncorrect: 0,
        consecutiveCorrect: 1,
      ),
      throwsArgumentError,
    );
  });
}
