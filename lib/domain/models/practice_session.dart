/// How the question set for a [PracticeSession] was chosen.
enum PracticeMode {
  quickPractice,
  weakAreas,
  incorrectQuestions,
  bookmarked,
  unseen,
  browseDomain,
  customQuiz,
  diagnostic,
}

/// Lifecycle state of a [PracticeSession].
enum SessionStatus { inProgress, completed, abandoned }

/// A single practice (including diagnostic) session: the ordered set of
/// questions offered and how far the user has progressed through it.
///
/// Invariant, enforced by the constructor (throws [ArgumentError] if
/// violated): [completedAt] is non-null exactly when [status] is
/// [SessionStatus.completed].
class PracticeSession {
  PracticeSession({
    required this.id,
    required this.examId,
    required this.mode,
    required List<String> questionIds,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.contentVersion,
  }) : questionIds = List.unmodifiable(questionIds) {
    if ((completedAt != null) != (status == SessionStatus.completed)) {
      throw ArgumentError(
        'completedAt must be set if and only if the session is completed.',
      );
    }
  }

  final String id;
  final String examId;
  final PracticeMode mode;
  final List<String> questionIds;
  final SessionStatus status;

  /// Always stored in UTC.
  final DateTime startedAt;

  /// Always stored in UTC. Null unless [status] is completed.
  final DateTime? completedAt;

  /// The content package version [questionIds] were drawn from
  /// (`ContentPackage.contentVersion`) — the same concept
  /// [MockAttempt.contentVersion] already tracks per mock attempt. Null
  /// for a session recorded before this field existed, or a caller with
  /// no content version to give (e.g. a test). See
  /// [AnswerAttempt.contentVersion]'s doc comment for why this matters.
  final String? contentVersion;

  PracticeSession copyWith({
    SessionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return PracticeSession(
      id: id,
      examId: examId,
      mode: mode,
      questionIds: questionIds,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      contentVersion: contentVersion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PracticeSession &&
        other.id == id &&
        other.examId == examId &&
        other.mode == mode &&
        _listEquals(other.questionIds, questionIds) &&
        other.status == status &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        other.contentVersion == contentVersion;
  }

  @override
  int get hashCode => Object.hash(
        id,
        examId,
        mode,
        Object.hashAll(questionIds),
        status,
        startedAt,
        completedAt,
        contentVersion,
      );
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
