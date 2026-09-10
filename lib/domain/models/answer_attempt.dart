/// The kind of session an [AnswerAttempt] was recorded during.
enum AttemptSessionType { diagnostic, practice, mock }

/// A single, append-only record of a user answering one question.
///
/// Attempts are never mutated after creation; correcting or retrying a
/// question produces a new attempt rather than editing an existing one.
class AnswerAttempt {
  const AnswerAttempt({
    required this.id,
    required this.examId,
    required this.questionId,
    required this.domainId,
    required this.topicId,
    required this.difficulty,
    required this.sessionId,
    required this.sessionType,
    required this.selectedAnswerId,
    required this.isCorrect,
    required this.answeredAt,
    this.contentVersion,
    this.questionVersion,
    this.correctAnswerId,
    this.explanation,
    this.confident,
    this.activeDurationSeconds,
    this.localAnsweredDate,
  });

  /// Null means not measured/declared, including all pre-migration attempts.
  final bool? confident;
  final int? activeDurationSeconds;

  /// ISO calendar date captured at submission, independent of later timezone changes.
  final String? localAnsweredDate;

  final String id;
  final String examId;
  final String questionId;
  final String domainId;
  final String topicId;
  final int difficulty;
  final String sessionId;
  final AttemptSessionType sessionType;
  final String selectedAnswerId;
  final bool isCorrect;

  /// Always stored in UTC.
  final DateTime answeredAt;

  /// The content package version [questionId] belonged to when this
  /// attempt was recorded (`ContentPackage.contentVersion`, the same
  /// concept [MockAttempt.contentVersion] already tracks per mock
  /// attempt) — never a "current" value re-read later. Null for an
  /// attempt recorded before this field existed, or a caller with no
  /// content version to give (e.g. a test). Without this, a later
  /// content update that changes or retires a question makes historical
  /// attempts against it ambiguous about what was actually asked; PREP-664
  /// added this specifically so content retirement never has to delete
  /// historical attempts to stay honest.
  final String? contentVersion;

  /// [Question.version] at the moment this attempt was evaluated. Null
  /// for an attempt recorded before this field existed (schema < 3,
  /// PREP-668), or a caller with no version to give (e.g. a test).
  ///
  /// This, [correctAnswerId], and [explanation] together are what let a
  /// later [PracticeSessionController.resume] rebuild the exact
  /// [AnswerFeedback] this attempt was originally evaluated against —
  /// without them, resuming a session after a restart could only ever
  /// reconstruct feedback from *today's* `Question` content, which can
  /// silently disagree with what was actually shown/graded if the
  /// question's content changed in between. See [AnswerFeedback]'s own
  /// doc comment.
  final int? questionVersion;

  /// [Question.correctAnswerId] at the moment this attempt was
  /// evaluated — see [questionVersion]'s doc comment for why this is
  /// persisted redundantly here rather than looked up later.
  final String? correctAnswerId;

  /// [Question.explanation] at the moment this attempt was evaluated —
  /// see [questionVersion]'s doc comment.
  final String? explanation;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnswerAttempt &&
        other.id == id &&
        other.examId == examId &&
        other.questionId == questionId &&
        other.domainId == domainId &&
        other.topicId == topicId &&
        other.difficulty == difficulty &&
        other.sessionId == sessionId &&
        other.sessionType == sessionType &&
        other.selectedAnswerId == selectedAnswerId &&
        other.isCorrect == isCorrect &&
        other.answeredAt == answeredAt &&
        other.contentVersion == contentVersion &&
        other.questionVersion == questionVersion &&
        other.correctAnswerId == correctAnswerId &&
        other.explanation == explanation &&
        other.confident == confident &&
        other.activeDurationSeconds == activeDurationSeconds &&
        other.localAnsweredDate == localAnsweredDate;
  }

  @override
  int get hashCode => Object.hash(
        id,
        examId,
        questionId,
        domainId,
        topicId,
        difficulty,
        sessionId,
        sessionType,
        selectedAnswerId,
        isCorrect,
        answeredAt,
        contentVersion,
        questionVersion,
        correctAnswerId,
        explanation,
        confident,
        activeDurationSeconds,
        localAnsweredDate,
      );
}
