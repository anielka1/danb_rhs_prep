import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';

void main() {
  PracticeSessionController buildController(InMemoryProgressRepository repo) {
    final questions = DebugDemoEnvironment.demoQuestions;
    final session = PracticeSession(
      id: 'session-1',
      examId: DebugDemoEnvironment.demoExamId,
      mode: PracticeMode.quickPractice,
      questionIds: questions.map((q) => q.id).toList(),
      status: SessionStatus.inProgress,
      startedAt: DateTime.utc(2026, 1, 1),
    );
    return PracticeSessionController(
      session: session,
      questions: questions,
      progressRepository: repo,
      now: () => DateTime.utc(2026, 1, 1, 0, 5),
    );
  }

  test(
      'answering the same question twice records two attempts with '
      'distinct, stable ids — never a collision that a real database\'s '
      'primary key would reject or silently overwrite', () async {
    final repo = InMemoryProgressRepository();
    final controller = buildController(repo);
    final String questionId = controller.currentQuestion.id;
    final String correctId = controller.currentQuestion.correctAnswerId;

    await controller.submitAnswer(correctId);
    // Simulates a double-submit (e.g. a rapid double-tap before the UI
    // disables the button) rather than a real product flow — the point
    // is the repository/id layer must tolerate it safely regardless.
    await controller.submitAnswer(correctId);

    final List<AnswerAttempt> attempts =
        await repo.answerAttemptsForExam(DebugDemoEnvironment.demoExamId);
    final List<AnswerAttempt> forThisQuestion =
        attempts.where((a) => a.questionId == questionId).toList();

    expect(forThisQuestion, hasLength(2));
    expect(forThisQuestion[0].id, isNot(forThisQuestion[1].id));
    expect(forThisQuestion[0].id, isNotEmpty);
  });

  test('submitAnswer returns whether the selected answer was correct',
      () async {
    final controller = buildController(InMemoryProgressRepository());
    final String correctId = controller.currentQuestion.correctAnswerId;
    final String wrongId = controller.currentQuestion.answers
        .firstWhere((a) => a.id != correctId)
        .id;

    expect(await controller.submitAnswer(wrongId), isFalse);
  });
}
