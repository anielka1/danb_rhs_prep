/// Lifecycle state of a [MockAttempt].
enum MockAttemptStatus { inProgress, completed, abandoned }

/// A single mock exam attempt: the generated question set, the user's
/// answers and flags so far, and the outcome once finished.
///
/// Invariants, enforced by the constructor (throws [ArgumentError] if
/// violated):
/// * [completedAt] and [correctCount] are non-null exactly when [status] is
///   [MockAttemptStatus.completed].
/// * every key in [answers] and every entry in [flaggedQuestionIds] is one
///   of [questionIds].
class MockAttempt {
  MockAttempt({
    required this.id,
    required this.examId,
    required List<String> questionIds,
    required Map<String, String> answers,
    required Set<String> flaggedQuestionIds,
    required this.status,
    required this.startedAt,
    required this.durationMinutes,
    this.completedAt,
    this.correctCount,
  })  : questionIds = List.unmodifiable(questionIds),
        answers = Map.unmodifiable(answers),
        flaggedQuestionIds = Set.unmodifiable(flaggedQuestionIds) {
    if ((completedAt != null) != (status == MockAttemptStatus.completed)) {
      throw ArgumentError(
        'completedAt must be set if and only if the attempt is completed.',
      );
    }
    if ((correctCount != null) != (status == MockAttemptStatus.completed)) {
      throw ArgumentError(
        'correctCount must be set if and only if the attempt is completed.',
      );
    }
    if (!this.answers.keys.every(this.questionIds.contains)) {
      throw ArgumentError(
        'Every answered question must be part of questionIds.',
      );
    }
    if (!this.flaggedQuestionIds.every(this.questionIds.contains)) {
      throw ArgumentError(
        'Every flagged question must be part of questionIds.',
      );
    }
  }

  final String id;
  final String examId;
  final List<String> questionIds;

  /// Question ID to selected answer ID, for questions answered so far.
  final Map<String, String> answers;
  final Set<String> flaggedQuestionIds;
  final MockAttemptStatus status;

  /// Always stored in UTC.
  final DateTime startedAt;
  final int durationMinutes;

  /// Always stored in UTC. Null unless [status] is completed.
  final DateTime? completedAt;

  /// Null unless [status] is completed.
  final int? correctCount;

  int get answeredCount => answers.length;

  MockAttempt copyWith({
    Map<String, String>? answers,
    Set<String>? flaggedQuestionIds,
    MockAttemptStatus? status,
    DateTime? completedAt,
    int? correctCount,
  }) {
    return MockAttempt(
      id: id,
      examId: examId,
      questionIds: questionIds,
      answers: answers ?? this.answers,
      flaggedQuestionIds: flaggedQuestionIds ?? this.flaggedQuestionIds,
      status: status ?? this.status,
      startedAt: startedAt,
      durationMinutes: durationMinutes,
      completedAt: completedAt ?? this.completedAt,
      correctCount: correctCount ?? this.correctCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MockAttempt &&
        other.id == id &&
        other.examId == examId &&
        _listEquals(other.questionIds, questionIds) &&
        _mapEquals(other.answers, answers) &&
        _setEquals(other.flaggedQuestionIds, flaggedQuestionIds) &&
        other.status == status &&
        other.startedAt == startedAt &&
        other.durationMinutes == durationMinutes &&
        other.completedAt == completedAt &&
        other.correctCount == correctCount;
  }

  @override
  int get hashCode => Object.hash(
        id,
        examId,
        Object.hashAll(questionIds),
        Object.hashAllUnordered(
          answers.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        Object.hashAllUnordered(flaggedQuestionIds),
        status,
        startedAt,
        durationMinutes,
        completedAt,
        correctCount,
      );
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

bool _setEquals(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
