import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/progress_repository.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';
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

  test(
      'a genuine double-submit (two concurrent calls, e.g. a rapid '
      'double-tap before the UI disables Submit — not the sequential '
      're-answer above) records exactly one attempt, and both calls '
      'resolve to the same result (PREP-664)', () async {
    final repo = InMemoryProgressRepository();
    final controller = buildController(repo);
    final String questionId = controller.currentQuestion.id;
    final String correctId = controller.currentQuestion.correctAnswerId;

    final Future<bool> first = controller.submitAnswer(correctId);
    final Future<bool> second = controller.submitAnswer(correctId);
    final List<bool> results = await Future.wait([first, second]);

    expect(results, [true, true]);
    final List<AnswerAttempt> attempts =
        await repo.answerAttemptsForExam(DebugDemoEnvironment.demoExamId);
    expect(attempts.where((a) => a.questionId == questionId), hasLength(1),
        reason: 'the second, concurrent call must reuse the first\'s '
            'in-flight result rather than recording a second attempt for '
            'one logical submission');
  });

  group('resume (PREP-665)', () {
    test(
        'restores answered/correct state from repository history — the '
        'plain constructor alone cannot, since that state is pure '
        'in-memory and a fresh instance (e.g. after a restart) starts '
        'with none', () async {
      final repo = InMemoryProgressRepository();
      final firstController = buildController(repo);
      final Question q0 = firstController.questions[0];
      final Question q1 = firstController.questions[1];

      await firstController.submitAnswer(q0.correctAnswerId);
      firstController.moveTo(1);
      final String wrongAnswerForQ1 =
          q1.answers.firstWhere((a) => a.id != q1.correctAnswerId).id;
      await firstController.submitAnswer(wrongAnswerForQ1);

      final resumed = await PracticeSessionController.resume(
        session: firstController.session,
        questions: firstController.questions,
        progressRepository: repo,
        now: () => DateTime.utc(2026, 1, 1, 0, 10),
      );

      expect(resumed.answeredCount, 2);
      expect(resumed.isAnswered(q0.id), isTrue);
      expect(resumed.isCorrectFor(q0.id), isTrue);
      expect(resumed.selectedAnswerFor(q0.id), q0.correctAnswerId);
      expect(resumed.isAnswered(q1.id), isTrue);
      expect(resumed.isCorrectFor(q1.id), isFalse);
      expect(resumed.selectedAnswerFor(q1.id), wrongAnswerForQ1);
      expect(resumed.isAnswered(resumed.questions[2].id), isFalse);
    });

    test(
        'resumes at the first not-yet-answered question, not back at '
        'question one', () async {
      final repo = InMemoryProgressRepository();
      final firstController = buildController(repo);
      await firstController
          .submitAnswer(firstController.currentQuestion.correctAnswerId);
      firstController.moveTo(1);
      await firstController
          .submitAnswer(firstController.currentQuestion.correctAnswerId);

      final resumed = await PracticeSessionController.resume(
        session: firstController.session,
        questions: firstController.questions,
        progressRepository: repo,
      );

      expect(resumed.currentIndex, 2);
    });

    test(
        'when every question is already answered, resumes at the last '
        'question rather than an out-of-range index', () async {
      final repo = InMemoryProgressRepository();
      final firstController = buildController(repo);
      for (var i = 0; i < firstController.totalQuestions; i++) {
        await firstController
            .submitAnswer(firstController.currentQuestion.correctAnswerId);
        if (i < firstController.totalQuestions - 1) {
          firstController.moveTo(i + 1);
        }
      }

      final resumed = await PracticeSessionController.resume(
        session: firstController.session,
        questions: firstController.questions,
        progressRepository: repo,
      );

      expect(resumed.currentIndex, resumed.totalQuestions - 1);
      expect(resumed.answeredCount, resumed.totalQuestions);
    });

    test(
        'restores only the latest attempt for a question answered more '
        'than once in the same session, matching what actually '
        'determines QuestionState today', () async {
      final repo = InMemoryProgressRepository();
      final firstController = buildController(repo);
      final Question q0 = firstController.questions[0];
      final String wrongAnswer =
          q0.answers.firstWhere((a) => a.id != q0.correctAnswerId).id;

      await firstController.submitAnswer(wrongAnswer);
      // Re-answer the same question with the correct choice — a genuine
      // "changed my mind" correction, not a double-submit.
      await firstController.submitAnswer(q0.correctAnswerId);

      final resumed = await PracticeSessionController.resume(
        session: firstController.session,
        questions: firstController.questions,
        progressRepository: repo,
      );

      expect(resumed.selectedAnswerFor(q0.id), q0.correctAnswerId);
      expect(resumed.isCorrectFor(q0.id), isTrue);
    });

    test(
        'ignores attempts from a different session for the same exam — '
        'only this session\'s own history is restored', () async {
      final repo = InMemoryProgressRepository();
      final firstController = buildController(repo);
      final Question q0 = firstController.questions[0];
      await firstController.submitAnswer(q0.correctAnswerId);

      final otherSession = PracticeSession(
        id: 'session-2',
        examId: DebugDemoEnvironment.demoExamId,
        mode: PracticeMode.quickPractice,
        questionIds: firstController.session.questionIds,
        status: SessionStatus.inProgress,
        startedAt: DateTime.utc(2026, 2, 1),
      );

      final resumed = await PracticeSessionController.resume(
        session: otherSession,
        questions: firstController.questions,
        progressRepository: repo,
      );

      expect(resumed.answeredCount, 0,
          reason: 'the other session answered a question in this exam, '
              'but never in the session being resumed here');
      expect(resumed.currentIndex, 0);
    });

    test(
        'a failing repository read leaves a fully usable controller with '
        'an empty answered map, matching submitAnswer\'s own best-effort '
        'reasoning — restoring history must never crash the interactive '
        'flow', () async {
      final resumed = await PracticeSessionController.resume(
        session: buildController(InMemoryProgressRepository()).session,
        questions: DebugDemoEnvironment.demoQuestions,
        progressRepository: _ThrowingProgressRepository(),
      );

      expect(resumed.answeredCount, 0);
      expect(resumed.currentIndex, 0);
      expect(
          await resumed.submitAnswer(resumed.currentQuestion.correctAnswerId),
          isTrue);
    });
  });
}

/// Every read/write throws — proves [PracticeSessionController.resume]'s
/// best-effort contract.
class _ThrowingProgressRepository implements ProgressRepository {
  @override
  Future<List<AnswerAttempt>> answerAttemptsForExam(String examId) async {
    throw StateError('offline');
  }

  @override
  Future<void> recordAnswerAttempt(AnswerAttempt attempt) async {}

  @override
  Future<QuestionState> questionState(String examId, String questionId) async {
    throw StateError('offline');
  }

  @override
  Future<void> saveQuestionState(QuestionState state) async {}

  @override
  Future<List<QuestionState>> questionStatesForExam(String examId) async {
    throw StateError('offline');
  }

  @override
  Future<void> savePracticeSession(PracticeSession session) async {}

  @override
  Future<PracticeSession?> inProgressPracticeSession(String examId) async {
    throw StateError('offline');
  }

  @override
  Future<void> saveMockAttempt(MockAttempt attempt) async {}

  @override
  Future<MockAttempt?> mockAttempt(String attemptId) async {
    throw StateError('offline');
  }

  @override
  Future<List<MockAttempt>> mockAttemptsForExam(String examId) async {
    throw StateError('offline');
  }

  @override
  Future<void> saveReadinessSnapshot(ReadinessSnapshot snapshot) async {}

  @override
  Future<ReadinessSnapshot?> latestReadinessSnapshot(String examId) async {
    throw StateError('offline');
  }

  @override
  Future<List<ReadinessSnapshot>> readinessSnapshotsForExam(
      String examId) async {
    throw StateError('offline');
  }
}
