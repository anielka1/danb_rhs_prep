import '../models/answer_attempt.dart';
import '../models/mock_attempt.dart';
import '../models/practice_session.dart';
import '../models/question_state.dart';
import '../models/readiness_snapshot.dart';

/// The precision [AnswerAttempt.answeredAt] is actually compared, and
/// persisted, at by every [ProgressRepository.recordAnswerAttempt]
/// implementation: whole seconds. This isn't an arbitrary domain rule —
/// it's dictated by the real Drift/SQLite-backed implementation, whose
/// `DateTimeColumn` storage silently truncates milliseconds/microseconds
/// on write (confirmed by direct reproduction, not assumed). Applying the
/// same truncation up front, before the very first save, is what lets
/// [canonicalizeAnswerAttempt]'s result be compared with plain `==`
/// safely everywhere — including the in-memory fake, which has no
/// storage-format reason of its own to lose that precision, but must
/// match the real implementation's behavior for
/// [ProgressRepository.recordAnswerAttempt]'s idempotency contract to
/// mean the same thing regardless of which implementation a caller (or a
/// test) is actually using. Without this, resubmitting the exact same
/// attempt — the safe-no-op case that contract promises — could be
/// misjudged as a conflicting different attempt merely because
/// `DateTime.now()` (or any other caller clock) carries sub-second
/// precision the database would have discarded anyway.
DateTime canonicalAnsweredAt(DateTime answeredAt) {
  final DateTime utc = answeredAt.toUtc();
  return DateTime.utc(
    utc.year,
    utc.month,
    utc.day,
    utc.hour,
    utc.minute,
    utc.second,
  );
}

/// [attempt] with [AnswerAttempt.answeredAt] replaced by
/// [canonicalAnsweredAt]'s result — see that function's doc comment.
/// Every [ProgressRepository.recordAnswerAttempt] implementation calls
/// this on its input before comparing against, or persisting alongside,
/// any existing attempt with the same id, so both the comparison and
/// what's actually stored/held agree at the same precision.
AnswerAttempt canonicalizeAnswerAttempt(AnswerAttempt attempt) {
  return AnswerAttempt(
    id: attempt.id,
    examId: attempt.examId,
    questionId: attempt.questionId,
    domainId: attempt.domainId,
    topicId: attempt.topicId,
    difficulty: attempt.difficulty,
    sessionId: attempt.sessionId,
    sessionType: attempt.sessionType,
    selectedAnswerId: attempt.selectedAnswerId,
    isCorrect: attempt.isCorrect,
    answeredAt: canonicalAnsweredAt(attempt.answeredAt),
    contentVersion: attempt.contentVersion,
    questionVersion: attempt.questionVersion,
    correctAnswerId: attempt.correctAnswerId,
    explanation: attempt.explanation,
  );
}

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
  ///   other field is identical to what's already stored, *after*
  ///   [canonicalizeAnswerAttempt] is applied to both sides (a caller, or
  ///   a future retry/sync path, unsure whether an earlier call actually
  ///   completed can always call this again with the same attempt,
  ///   regardless of the sub-second precision its clock happened to
  ///   carry); or
  /// * a loud failure when any field still differs after canonicalizing,
  ///   since that is silent corruption of a different attempt's history,
  ///   never a legitimate retry.
  Future<void> recordAnswerAttempt(AnswerAttempt attempt);

  /// Every attempt recorded for [examId], in the order they were
  /// recorded (PREP-665) — oldest first. This is a real contract, not an
  /// incidental detail: [PracticeSessionController.resume] relies on it
  /// to find each question's *latest* attempt within one session by
  /// taking the last matching entry in this list, since two attempts can
  /// carry the identical [AnswerAttempt.answeredAt] (see that field's own
  /// doc comment) with nothing else able to break the tie. See
  /// `DriftProgressRepository.answerAttemptsForExam`'s own doc comment
  /// for exactly how the real implementation guarantees this (SQLite
  /// `rowid` order, not `answeredAt` order) and the two conditions that
  /// keep it true.
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
