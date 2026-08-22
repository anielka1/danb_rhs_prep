import '../models/answer_attempt.dart';
import '../models/mock_attempt.dart';
import '../models/practice_session.dart';
import '../models/question_state.dart';
import '../models/readiness_snapshot.dart';

/// Persists and retrieves everything the practice, mock exam, progress, and
/// readiness engines need, independent of the underlying storage.
abstract interface class ProgressRepository {
  Future<void> recordAnswerAttempt(AnswerAttempt attempt);
  Future<List<AnswerAttempt>> answerAttemptsForExam(String examId);

  Future<QuestionState> questionState(String examId, String questionId);
  Future<void> saveQuestionState(QuestionState state);
  Future<List<QuestionState>> questionStatesForExam(String examId);

  Future<void> savePracticeSession(PracticeSession session);

  /// The user's not-yet-finished session for this exam, if any, so it can
  /// be resumed instead of starting a new one.
  Future<PracticeSession?> inProgressPracticeSession(String examId);

  Future<void> saveMockAttempt(MockAttempt attempt);
  Future<MockAttempt?> mockAttempt(String attemptId);
  Future<List<MockAttempt>> mockAttemptsForExam(String examId);

  Future<void> saveReadinessSnapshot(ReadinessSnapshot snapshot);
  Future<ReadinessSnapshot?> latestReadinessSnapshot(String examId);
  Future<List<ReadinessSnapshot>> readinessSnapshotsForExam(String examId);
}
