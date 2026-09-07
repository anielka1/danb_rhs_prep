import '../../models/answer_attempt.dart';
import '../../models/mock_attempt.dart';
import '../../models/practice_session.dart';
import '../../models/question_state.dart';
import '../../models/readiness_snapshot.dart';
import '../progress_repository.dart';

/// An in-memory [ProgressRepository] for unit tests and previews.
///
/// Every `seed*` constructor parameter is available immediately through
/// the matching read methods — synchronously pre-populated rather than
/// requiring a caller to `await save...(...)` for each item first, which
/// matters for a caller (e.g. `DebugDemoEnvironment`) that needs a
/// fully-seeded repository back from a synchronous factory.
class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository({
    List<AnswerAttempt> seedAnswerAttempts = const [],
    List<QuestionState> seedQuestionStates = const [],
    List<PracticeSession> seedPracticeSessions = const [],
    List<MockAttempt> seedMockAttempts = const [],
    List<ReadinessSnapshot> seedReadinessSnapshots = const [],
  })  : _attempts = List.of(seedAnswerAttempts),
        _questionStates = {
          for (final state in seedQuestionStates)
            _questionKey(state.examId, state.questionId): state,
        },
        _practiceSessions = {
          for (final session in seedPracticeSessions) session.id: session,
        },
        _mockAttempts = {
          for (final attempt in seedMockAttempts) attempt.id: attempt,
        },
        _readinessSnapshots = List.of(seedReadinessSnapshots);

  final List<AnswerAttempt> _attempts;
  final Map<String, QuestionState> _questionStates;
  final Map<String, PracticeSession> _practiceSessions;
  final Map<String, MockAttempt> _mockAttempts;
  final List<ReadinessSnapshot> _readinessSnapshots;

  static String _questionKey(String examId, String questionId) =>
      '$examId::$questionId';

  @override
  Future<void> recordAnswerAttempt(AnswerAttempt attempt) async {
    // Matches DriftProgressRepository's genuinely-idempotent contract
    // (PREP-664) exactly, including calling the same
    // canonicalizeAnswerAttempt — see that class's, canonicalizeAnswerAttempt's,
    // and the interface method's own doc comments for why: without it,
    // this fake would (incorrectly) retain full sub-second precision the
    // real, Drift-backed implementation actually discards, so a
    // resubmission this fake would treat as identical could disagree
    // with what the real implementation decides. No `await` sits between
    // the check and the mutations below, so nothing else running on this
    // single-threaded fake can interleave and observe a half-applied
    // state.
    final AnswerAttempt canonical = canonicalizeAnswerAttempt(attempt);
    final AnswerAttempt? existing =
        _attempts.where((a) => a.id == canonical.id).firstOrNull;
    if (existing != null) {
      if (existing == canonical) {
        // Genuinely idempotent: re-recording the exact same attempt is a
        // safe no-op — critically, without re-running the question-state
        // update below, which already applied the first time.
        return;
      }
      throw StateError(
        'An answer attempt with id "${canonical.id}" already exists with '
        'different content.',
      );
    }
    _attempts.add(canonical);
    final String key = _questionKey(canonical.examId, canonical.questionId);
    final QuestionState prior = _questionStates[key] ??
        QuestionState.unseen(
          examId: canonical.examId,
          questionId: canonical.questionId,
        );
    _questionStates[key] = prior.withAttempt(
      isCorrect: canonical.isCorrect,
      answeredAt: canonical.answeredAt,
    );
  }

  @override
  Future<List<AnswerAttempt>> answerAttemptsForExam(String examId) async {
    return _attempts
        .where((attempt) => attempt.examId == examId)
        .toList(growable: false);
  }

  @override
  Future<QuestionState> questionState(
    String examId,
    String questionId,
  ) async {
    return _questionStates[_questionKey(examId, questionId)] ??
        QuestionState.unseen(examId: examId, questionId: questionId);
  }

  @override
  Future<void> saveQuestionState(QuestionState state) async {
    _questionStates[_questionKey(state.examId, state.questionId)] = state;
  }

  @override
  Future<List<QuestionState>> questionStatesForExam(String examId) async {
    return _questionStates.values
        .where((state) => state.examId == examId)
        .toList(growable: false);
  }

  @override
  Future<void> savePracticeSession(PracticeSession session) async {
    _practiceSessions[session.id] = session;
  }

  @override
  Future<PracticeSession?> inProgressPracticeSession(String examId) async {
    for (final session in _practiceSessions.values) {
      if (session.examId == examId &&
          session.status == SessionStatus.inProgress) {
        return session;
      }
    }
    return null;
  }

  @override
  Future<void> saveMockAttempt(MockAttempt attempt) async {
    _mockAttempts[attempt.id] = attempt;
  }

  @override
  Future<MockAttempt?> mockAttempt(String attemptId) async {
    return _mockAttempts[attemptId];
  }

  @override
  Future<List<MockAttempt>> mockAttemptsForExam(String examId) async {
    return _mockAttempts.values
        .where((attempt) => attempt.examId == examId)
        .toList(growable: false);
  }

  @override
  Future<void> saveReadinessSnapshot(ReadinessSnapshot snapshot) async {
    _readinessSnapshots.add(snapshot);
  }

  @override
  Future<ReadinessSnapshot?> latestReadinessSnapshot(String examId) async {
    ReadinessSnapshot? latest;
    for (final snapshot in _readinessSnapshots) {
      if (snapshot.examId != examId) continue;
      if (latest == null ||
          snapshot.calculatedAt.isAfter(latest.calculatedAt)) {
        latest = snapshot;
      }
    }
    return latest;
  }

  @override
  Future<List<ReadinessSnapshot>> readinessSnapshotsForExam(
    String examId,
  ) async {
    return _readinessSnapshots
        .where((snapshot) => snapshot.examId == examId)
        .toList(growable: false);
  }
}
