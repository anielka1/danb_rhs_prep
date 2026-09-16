import '../domain/models/answer_attempt.dart';

class FreePracticeState {
  const FreePracticeState(
      {this.answeredCount = 0,
      this.completionPaywallShown = false,
      this.sessionIds = const {}});
  final int answeredCount;
  final bool completionPaywallShown;
  final Set<String> sessionIds;
  int get remaining => (5 - answeredCount).clamp(0, 5);
  bool get completed => remaining == 0;
}

/// The answer write and trial consumption must commit together. Implementations
/// retain the allowance across progress resets; it is installation-level access.
abstract interface class FreePracticeStore {
  Future<FreePracticeState> read();
  Future<void> registerSession(String id);
  Future<void> record(
      AnswerAttempt attempt, Future<void> Function() writeAnswer);
  Future<void> markCompletionPaywallShown();
}
