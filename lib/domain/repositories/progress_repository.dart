import '../models/answer_attempt.dart';
import '../models/mock_attempt.dart';
import '../models/practice_session.dart';
import '../models/question_state.dart';
import '../models/readiness_snapshot.dart';

/// Persists and retrieves everything the practice, mock exam, progress, and
/// readiness engines need, independent of the underlying storage.
abstract interface class ProgressRepository {
  /// Records [attempt] and updates the aggregate [QuestionState] for the
  /// question it answered — atomically (PREP-664): both persist, or
  /// neither does, so a crash between them can never leave a recorded
  /// attempt whose question-state totals don't reflect it. The updated
  /// state is derived from whatever is currently persisted for
  /// `(attempt.examId, attempt.questionId)`, read as part of the same
  /// atomic operation — never a value the caller read earlier and might
  /// now be stale — via [QuestionState.withAttempt].
  ///
  /// [attempt.id] must be a stable, caller-generated UUID unique to this
  /// one submission (see `IdGenerator`). This method is genuinely
  /// idempotent by that id, not just duplicate-safe: calling it again
  /// with an id that's already recorded is
  /// * a safe no-op — including skipping the question-state update
  ///   entirely, since it already applied the first time — when every
  ///   other field is identical to what's already stored (a caller, or a
  ///   future retry/sync path, unsure whether an earlier call actually
  ///   completed can always call this again with the same attempt); or
  /// * a loud failure when any field differs, since that is silent
  ///   corruption of a different attempt's history, never a legitimate
  ///   retry.
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
