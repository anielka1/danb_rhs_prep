import '../domain/models/practice_session.dart';
import '../domain/repositories/progress_repository.dart';

/// Retires the removed starting check without completing it or rewriting grades.
/// A failed read/write propagates to the caller's Retry state; no new session
/// may start until the existing active slot has been safely released.
Future<PracticeSession?> resumablePracticeSession(
    ProgressRepository repository, String examId) async {
  final active = await repository.inProgressPracticeSession(examId);
  if (active?.mode != PracticeMode.diagnostic) return active;
  await repository
      .savePracticeSession(active!.copyWith(status: SessionStatus.abandoned));
  return null;
}
