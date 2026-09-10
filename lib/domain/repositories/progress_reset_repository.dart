/// Explicit destructive capability, separate from ordinary progress reads/writes.
abstract interface class ProgressResetRepository {
  /// Atomically removes answers, question states (including bookmarks), practice
  /// sessions, mock attempts and readiness history for this exam only.
  /// Other exams, profile/preferences, content and entitlements are preserved.
  /// Failure leaves all progress unchanged; repeating a reset is safe.
  /// Callers must retire active study controllers before invoking this operation:
  /// a stale controller must not be allowed to save deleted progress afterwards.
  Future<void> resetProgressForExam(String examId);
}
