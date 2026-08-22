import '../../models/answer_attempt.dart';
import '../../models/mock_attempt.dart';
import '../../models/practice_session.dart';
import '../../models/question_state.dart';
import '../../models/readiness_snapshot.dart';
import '../progress_repository.dart';

/// An in-memory [ProgressRepository] for unit tests and previews.
class InMemoryProgressRepository implements ProgressRepository {
  final List<AnswerAttempt> _attempts = [];
  final Map<String, QuestionState> _questionStates = {};
  final Map<String, PracticeSession> _practiceSessions = {};
  final Map<String, MockAttempt> _mockAttempts = {};
  final List<ReadinessSnapshot> _readinessSnapshots = [];

  String _questionKey(String examId, String questionId) =>
      '$examId::$questionId';

  @override
  Future<void> recordAnswerAttempt(AnswerAttempt attempt) async {
    _attempts.add(attempt);
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
