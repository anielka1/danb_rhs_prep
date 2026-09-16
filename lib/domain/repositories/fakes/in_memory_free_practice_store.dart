import '../../../subscription/free_practice_store.dart';
import '../../models/answer_attempt.dart';

class InMemoryFreePracticeStore implements FreePracticeStore {
  final Set<String> _attempts = {};
  final Set<String> _sessions = {};
  bool _shown = false;
  Future<void> _tail = Future.value();
  @override
  Future<FreePracticeState> read() async => FreePracticeState(
      answeredCount: _attempts.length,
      completionPaywallShown: _shown,
      sessionIds: Set.of(_sessions));
  @override
  Future<void> registerSession(String id) async {
    _sessions.add(id);
  }

  @override
  Future<void> markCompletionPaywallShown() async {
    _shown = true;
  }

  @override
  Future<void> record(
      AnswerAttempt attempt, Future<void> Function() writeAnswer) {
    final result = _tail.then((_) async {
      if (!_sessions.contains(attempt.sessionId) ||
          (!_attempts.contains(attempt.id) && _attempts.length >= 5)) {
        throw StateError('Trial unavailable');
      }
      await writeAnswer();
      _attempts.add(attempt.id);
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}
