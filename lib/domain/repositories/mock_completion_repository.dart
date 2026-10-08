import '../models/answer_attempt.dart';
import '../models/mock_attempt.dart';

/// Publishes a final mock score and its frozen, answered-question grades together.
/// Implementations must commit all rows/state aggregates or none, and accept an
/// identical retry without counting an answer twice. Historical mocks are not backfilled.
abstract interface class MockCompletionRepository {
  Future<void> completeMockAttempt(
      MockAttempt attempt, List<AnswerAttempt> answers);
}

void validateMockCompletion(MockAttempt attempt, List<AnswerAttempt> answers) {
  if (attempt.status != MockAttemptStatus.completed ||
      answers.length != attempt.answers.length ||
      answers.map((a) => a.questionId).toSet().length != answers.length ||
      answers.where((a) => a.isCorrect).length != attempt.correctCount ||
      answers.any((a) =>
          a.sessionType != AttemptSessionType.mock ||
          a.sessionId != attempt.id ||
          a.examId != attempt.examId ||
          attempt.answers[a.questionId] != a.selectedAnswerId)) {
    throw ArgumentError('Invalid mock completion details');
  }
}
