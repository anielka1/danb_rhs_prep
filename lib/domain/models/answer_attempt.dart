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
        other.contentVersion == contentVersion;
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
      );
}
