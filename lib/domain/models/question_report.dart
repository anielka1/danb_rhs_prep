/// The kind of problem a user is flagging about a question.
enum QuestionReportCategory {
  incorrectAnswer,
  incorrectExplanation,
  outdated,
  typo,
  unclear,
  other,
}

/// Delivery state of a [QuestionReport], since submission may need to be
/// queued while offline.
enum QuestionReportStatus { pendingSubmission, submitted, failed }

/// A user-submitted content-quality report for a single question.
class QuestionReport {
  const QuestionReport({
    required this.id,
    required this.examId,
    required this.questionId,
    required this.questionVersion,
    required this.contentVersion,
    required this.appVersion,
    required this.category,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String examId;
  final String questionId;
  final int questionVersion;
  final String contentVersion;
  final String appVersion;
  final QuestionReportCategory category;
  final QuestionReportStatus status;

  /// Always stored in UTC.
  final DateTime createdAt;

  final String? notes;

  QuestionReport copyWith({
    QuestionReportStatus? status,
  }) {
    return QuestionReport(
      id: id,
      examId: examId,
      questionId: questionId,
      questionVersion: questionVersion,
      contentVersion: contentVersion,
      appVersion: appVersion,
      category: category,
      status: status ?? this.status,
      createdAt: createdAt,
      notes: notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionReport &&
        other.id == id &&
        other.examId == examId &&
        other.questionId == questionId &&
        other.questionVersion == questionVersion &&
        other.contentVersion == contentVersion &&
        other.appVersion == appVersion &&
        other.category == category &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        examId,
        questionId,
        questionVersion,
        contentVersion,
        appVersion,
        category,
        status,
        createdAt,
        notes,
      );
}
