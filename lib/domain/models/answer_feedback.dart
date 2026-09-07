/// The immutable result of evaluating one answer (PREP-668) —
/// [PracticeSessionController.submitAnswer]'s return value, and what
/// `AnswerExplanationScreen`/`PracticeQuestionScreen` read to render the
/// correct answer, explanation, and correct/incorrect state for an
/// already-answered question.
///
/// Every field here is captured from the exact same [Question] snapshot,
/// at the exact same instant, that produced the [AnswerAttempt] persisted
/// alongside it — never independently re-read later from whatever
/// `PracticeSessionController.questions` currently holds for that id. That
/// distinction only matters once content can change out from under a
/// live session (e.g. a future hot content-reload), but the engine's job
/// is to make the guarantee structural now, not to rely on
/// `questions` happening to stay unmodified for as long as that remains
/// incidentally true.
///
/// Deliberately narrow: only the fields that determine *evaluation*
/// correctness and its explanation. Presentational content that can't
/// itself be right or wrong — `questionText`, the answer option labels —
/// is still read from `PracticeSessionController.currentQuestion`/
/// `questions`, since duplicating already-immutable-per-session fields
/// here would add nothing.
class AnswerFeedback {
  const AnswerFeedback({
    required this.questionId,
    required this.questionVersion,
    required this.selectedAnswerId,
    required this.correctAnswerId,
    required this.isCorrect,
    required this.explanation,
    required this.answeredAt,
    this.contentVersion,
  });

  final String questionId;

  /// [Question.version] at the moment this was evaluated — lets a caller
  /// notice, later, that a question's content has since changed underneath
  /// a historical result (e.g. when reconstructing feedback for a resumed
  /// session against today's `questions`, see
  /// [PracticeSessionController.resume]'s own doc comment on the
  /// limits of that reconstruction).
  final int questionVersion;

  final String selectedAnswerId;
  final String correctAnswerId;
  final bool isCorrect;
  final String explanation;

  /// Always stored in UTC. The same instant recorded on the paired
  /// [AnswerAttempt].
  final DateTime answeredAt;

  /// The content package version [questionId] belonged to when this was
  /// evaluated — the same value recorded on the paired [AnswerAttempt]'s
  /// [AnswerAttempt.contentVersion]. See that field's own doc comment.
  final String? contentVersion;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnswerFeedback &&
        other.questionId == questionId &&
        other.questionVersion == questionVersion &&
        other.selectedAnswerId == selectedAnswerId &&
        other.correctAnswerId == correctAnswerId &&
        other.isCorrect == isCorrect &&
        other.explanation == explanation &&
        other.answeredAt == answeredAt &&
        other.contentVersion == contentVersion;
  }

  @override
  int get hashCode => Object.hash(
        questionId,
        questionVersion,
        selectedAnswerId,
        correctAnswerId,
        isCorrect,
        explanation,
        answeredAt,
        contentVersion,
      );
}
