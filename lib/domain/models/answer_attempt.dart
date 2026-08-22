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
  });

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
        other.answeredAt == answeredAt;
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
      );
}
