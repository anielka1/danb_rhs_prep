/// Aggregated, per-question progress used for bookmarking, review, and the
/// adaptive question selector.
///
/// Invariants, enforced by the constructor (throws [ArgumentError] if
/// violated): [timesCorrect] + [timesIncorrect] never exceeds [timesSeen],
/// and [lastAnsweredAt] is non-null exactly when the question has been
/// answered at least once.
class QuestionState {
  QuestionState({
    required this.examId,
    required this.questionId,
    required this.bookmarked,
    required this.timesSeen,
    required this.timesCorrect,
    required this.timesIncorrect,
    required this.consecutiveCorrect,
    this.lastAnsweredAt,
  }) {
    if (timesCorrect + timesIncorrect > timesSeen) {
      throw ArgumentError(
        'timesCorrect + timesIncorrect must not exceed timesSeen.',
      );
    }
    if ((lastAnsweredAt != null) != (timesSeen > 0)) {
      throw ArgumentError(
        'lastAnsweredAt must be set if and only if the question has been seen.',
      );
    }
  }

  /// A question that has never been shown to the user.
  factory QuestionState.unseen({
    required String examId,
    required String questionId,
  }) {
    return QuestionState(
      examId: examId,
      questionId: questionId,
      bookmarked: false,
      timesSeen: 0,
      timesCorrect: 0,
      timesIncorrect: 0,
      consecutiveCorrect: 0,
    );
  }

  final String examId;
  final String questionId;
  final bool bookmarked;
  final int timesSeen;
  final int timesCorrect;
  final int timesIncorrect;
  final int consecutiveCorrect;

  /// Always stored in UTC. Null when [timesSeen] is zero.
  final DateTime? lastAnsweredAt;

  bool get hasBeenAnswered => timesSeen > 0;

  QuestionState copyWith({
    bool? bookmarked,
    int? timesSeen,
    int? timesCorrect,
    int? timesIncorrect,
    int? consecutiveCorrect,
    DateTime? lastAnsweredAt,
  }) {
    return QuestionState(
      examId: examId,
      questionId: questionId,
      bookmarked: bookmarked ?? this.bookmarked,
      timesSeen: timesSeen ?? this.timesSeen,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      timesIncorrect: timesIncorrect ?? this.timesIncorrect,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      lastAnsweredAt: lastAnsweredAt ?? this.lastAnsweredAt,
    );
  }

  /// Returns the state after recording one more attempt.
  QuestionState withAttempt({
    required bool isCorrect,
    required DateTime answeredAt,
  }) {
    return QuestionState(
      examId: examId,
      questionId: questionId,
      bookmarked: bookmarked,
      timesSeen: timesSeen + 1,
      timesCorrect: timesCorrect + (isCorrect ? 1 : 0),
      timesIncorrect: timesIncorrect + (isCorrect ? 0 : 1),
      consecutiveCorrect: isCorrect ? consecutiveCorrect + 1 : 0,
      lastAnsweredAt: answeredAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionState &&
        other.examId == examId &&
        other.questionId == questionId &&
        other.bookmarked == bookmarked &&
        other.timesSeen == timesSeen &&
        other.timesCorrect == timesCorrect &&
        other.timesIncorrect == timesIncorrect &&
        other.consecutiveCorrect == consecutiveCorrect &&
        other.lastAnsweredAt == lastAnsweredAt;
  }

  @override
  int get hashCode => Object.hash(
        examId,
        questionId,
        bookmarked,
        timesSeen,
        timesCorrect,
        timesIncorrect,
        consecutiveCorrect,
        lastAnsweredAt,
      );
}
