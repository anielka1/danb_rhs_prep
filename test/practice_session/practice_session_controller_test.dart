import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/answer_feedback.dart';
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

  test(
      'submitAnswer returns an immutable AnswerFeedback carrying whether '
      'the selected answer was correct (PREP-668)', () async {
    final controller = buildController(InMemoryProgressRepository());
    final Question question = controller.currentQuestion;
    final String correctId = question.correctAnswerId;
    final String wrongId =
        question.answers.firstWhere((a) => a.id != correctId).id;

    final AnswerFeedback feedback = await controller.submitAnswer(wrongId);

    expect(feedback.isCorrect, isFalse);
    expect(feedback.questionId, question.id);
    expect(feedback.questionVersion, question.version);
    expect(feedback.selectedAnswerId, wrongId);
    expect(feedback.correctAnswerId, correctId);
    expect(feedback.explanation, question.explanation);
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

    final Future<AnswerFeedback> first = controller.submitAnswer(correctId);
    final Future<AnswerFeedback> second = controller.submitAnswer(correctId);
    final List<AnswerFeedback> results = await Future.wait([first, second]);

    expect(results.map((f) => f.isCorrect), [true, true]);
    expect(identical(results[0], results[1]), isTrue,
        reason: 'both calls must resolve to the exact same in-flight '
            'result, not two separately-built (even if equal) objects');
    final List<AnswerAttempt> attempts =
        await repo.answerAttemptsForExam(DebugDemoEnvironment.demoExamId);
    expect(attempts.where((a) => a.questionId == questionId), hasLength(1),
        reason: 'the second, concurrent call must reuse the first\'s '
            'in-flight result rather than recording a second attempt for '
            'one logical submission');
  });

  group('AnswerFeedback snapshot (PREP-668)', () {
    test('feedbackFor is null before a question is answered', () {
      final controller = buildController(InMemoryProgressRepository());
      expect(controller.feedbackFor(controller.currentQuestion.id), isNull);
    });

    test(
        'feedbackFor returns the exact object submitAnswer returned, and '
        'every field comes from the same question snapshot that was '
        'actually evaluated', () async {
      final questions = DebugDemoEnvironment.demoQuestions;
      final session = PracticeSession(
        id: 'session-with-version',
        examId: DebugDemoEnvironment.demoExamId,
        mode: PracticeMode.quickPractice,
        questionIds: questions.map((q) => q.id).toList(),
        status: SessionStatus.inProgress,
        startedAt: DateTime.utc(2026, 1, 1),
        contentVersion: 'content-v7',
      );
      final controller = PracticeSessionController(
        session: session,
        questions: questions,
        progressRepository: InMemoryProgressRepository(),
        now: () => DateTime.utc(2026, 1, 1, 0, 5),
      );
      final Question question = controller.currentQuestion;
      final String wrongAnswer = question.answers
          .firstWhere((a) => a.id != question.correctAnswerId)
          .id;

      final AnswerFeedback returned = await controller.submitAnswer(
        wrongAnswer,
      );
      final AnswerFeedback? cached = controller.feedbackFor(question.id);

      expect(cached, same(returned),
          reason: 'the UI must be able to read the exact same immutable '
              'result later (e.g. Previous back into this question) that '
              'submitAnswer originally returned, not a re-derived copy');
      expect(returned.questionId, question.id);
      expect(returned.questionVersion, question.version);
      expect(returned.selectedAnswerId, wrongAnswer);
      expect(returned.correctAnswerId, question.correctAnswerId);
      expect(returned.isCorrect, isFalse);
      expect(returned.explanation, question.explanation);
      expect(returned.contentVersion, 'content-v7',
          reason: 'the returned feedback and the persisted AnswerAttempt '
              'must share the same contentVersion snapshot');
      expect(returned.answeredAt, DateTime.utc(2026, 1, 1, 0, 5));
    });
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
        'reconstructs feedbackFor from persisted attempts, so a resumed '
        'session can show View Explanation for an already-answered '
        'question without re-evaluating it (PREP-668)', () async {
      final repo = InMemoryProgressRepository();
      final firstController = buildController(repo);
      final Question q0 = firstController.questions[0];
      final String wrongAnswer =
          q0.answers.firstWhere((a) => a.id != q0.correctAnswerId).id;
      await firstController.submitAnswer(wrongAnswer);

      final resumed = await PracticeSessionController.resume(
        session: firstController.session,
        questions: firstController.questions,
        progressRepository: repo,
      );

      final AnswerFeedback? feedback = resumed.feedbackFor(q0.id);
      expect(feedback, isNotNull);
      expect(feedback!.questionId, q0.id);
      expect(feedback.questionVersion, q0.version);
      expect(feedback.selectedAnswerId, wrongAnswer);
      expect(feedback.correctAnswerId, q0.correctAnswerId);
      expect(feedback.isCorrect, isFalse,
          reason: 'the persisted verdict is trusted as-is, never '
              're-evaluated on resume');
      expect(feedback.explanation, q0.explanation);
    });

    // Deliberately NOT a test of "a question retired from the active
    // content package while session.questionIds still names it" — that
    // different, real product scenario is handled (as a crash guard,
    // not a full resolution) at
    // ExamOverviewScreen._startOrResumePractice's own questionsById
    // lookup, not here. This test is purely a controller-level
    // data-integrity check: a record sharing this session's id but
    // naming a questionId that was never actually part of
    // session.questionIds (a foreign or corrupted row) must be ignored,
    // never counted.
    test(
        "ignores an attempt whose questionId isn't part of this "
        "session's own questionIds, even though it shares the "
        "session's id — and doesn't let it inflate answeredCount/"
        'correctCount either (PREP-668)', () async {
      final repo = InMemoryProgressRepository();
      final firstController = buildController(repo);
      final Question q0 = firstController.questions[0];
      await firstController.submitAnswer(q0.correctAnswerId);

      const String foreignQuestionId = 'not-actually-in-this-session';
      await repo.recordAnswerAttempt(AnswerAttempt(
        id: 'foreign-attempt',
        examId: firstController.session.examId,
        questionId: foreignQuestionId,
        domainId: q0.domainId,
        topicId: q0.topicId,
        difficulty: q0.difficulty,
        sessionId: firstController.session.id,
        sessionType: AttemptSessionType.practice,
        selectedAnswerId: 'x',
        isCorrect: true,
        answeredAt: DateTime.utc(2026, 1, 1, 0, 6),
        questionVersion: 1,
        correctAnswerId: 'x',
        explanation: 'n/a',
      ));

      final resumed = await PracticeSessionController.resume(
        session: firstController.session,
        questions: firstController.questions,
        progressRepository: repo,
      );

      expect(resumed.feedbackFor(foreignQuestionId), isNull);
      expect(resumed.answeredCount, 1,
          reason: 'only q0 is genuinely part of this session; the '
              "foreign record must not inflate the count");
      expect(resumed.correctCount, 1);
    });

    test(
        'skips reconstructing feedback for a legacy attempt recorded '
        'before schema 3 (no persisted questionVersion/correctAnswerId/'
        'explanation), rather than fabricating one from today\'s '
        'Question (PREP-668)', () async {
      final repo = InMemoryProgressRepository();
      final firstController = buildController(repo);
      final Question q0 = firstController.questions[0];
      // Simulates a pre-PREP-668 row: recorded directly, bypassing
      // submitAnswer, with none of the three new columns set.
      await repo.recordAnswerAttempt(AnswerAttempt(
        id: 'legacy-attempt',
        examId: firstController.session.examId,
        questionId: q0.id,
        domainId: q0.domainId,
        topicId: q0.topicId,
        difficulty: q0.difficulty,
        sessionId: firstController.session.id,
        sessionType: AttemptSessionType.practice,
        selectedAnswerId: q0.correctAnswerId,
        isCorrect: true,
        answeredAt: DateTime.utc(2025, 1, 1),
      ));

      final resumed = await PracticeSessionController.resume(
        session: firstController.session,
        questions: firstController.questions,
        progressRepository: repo,
      );

      expect(resumed.feedbackFor(q0.id), isNull,
          reason: 'no genuine snapshot exists for this legacy row — it '
              'must not be silently filled in from the current Question');
    });

    test(
        'resuming with a changed Question (different correctAnswerId, '
        'explanation, and version, same id) still restores the exact '
        'feedback the original answer was evaluated against, not the '
        'new content — the immutable-snapshot guarantee holds across a '
        'restart, not just within one live session (PREP-668 regression)',
        () async {
      final repo = InMemoryProgressRepository();
      final firstController = buildController(repo);
      final Question v1 = firstController.questions[0];

      await firstController.submitAnswer(v1.correctAnswerId);

      final Question v2 = Question(
        id: v1.id,
        examId: v1.examId,
        domainId: v1.domainId,
        topicId: v1.topicId,
        questionText: v1.questionText,
        answers: v1.answers,
        // A different correct answer than v1 had.
        correctAnswerId:
            v1.answers.firstWhere((a) => a.id != v1.correctAnswerId).id,
        explanation: 'A revised explanation, written after v1 was answered.',
        references: v1.references,
        difficulty: v1.difficulty,
        status: v1.status,
        version: v1.version + 1,
        updatedAt: DateTime.utc(2026, 6, 1),
        sourceVersion: v1.sourceVersion,
        tags: v1.tags,
      );
      final List<Question> questionsWithV2 = [
        v2,
        ...firstController.questions.skip(1),
      ];

      final resumed = await PracticeSessionController.resume(
        session: firstController.session,
        questions: questionsWithV2,
        progressRepository: repo,
      );

      final AnswerFeedback? feedback = resumed.feedbackFor(v1.id);
      expect(feedback, isNotNull);
      expect(feedback!.questionVersion, v1.version,
          reason: 'must reflect the version actually evaluated, not v2\'s');
      expect(feedback.correctAnswerId, v1.correctAnswerId,
          reason: 'must reflect what was actually correct when answered, '
              'not the (different) answer v2 now considers correct');
      expect(feedback.explanation, v1.explanation,
          reason: 'must reflect the explanation actually shown, not the '
              'revised one v2 now carries');
      expect(feedback.isCorrect, isTrue,
          reason: 'the original verdict — answered v1\'s real correct '
              'answer — must not be re-judged against v2');
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
      final AnswerFeedback feedback =
          await resumed.submitAnswer(resumed.currentQuestion.correctAnswerId);
      expect(feedback.isCorrect, isTrue);
    });
  });

  group('Previous/Next navigation (PREP-460 regression)', () {
    test(
        'after answering Q1 and advancing to Q2, using Previous to browse '
        'back to Q1 does not permanently disable Next — it must still be '
        'able to return to Q2, the not-yet-answered question you came '
        'from', () async {
      final controller = buildController(InMemoryProgressRepository());

      // The real forward path: answer Q1, then advance — exactly what
      // AnswerExplanationScreen's "Next Question" does
      // (moveTo(currentIndex + 1)), landing on Q2, unanswered.
      await controller.submitAnswer(controller.currentQuestion.correctAnswerId);
      controller.moveTo(controller.currentIndex + 1);
      expect(controller.currentIndex, 1);
      expect(controller.isAnswered(controller.currentQuestion.id), isFalse,
          reason: 'Q2 has not been answered yet — this is the exact '
              'position the bug left the user stranded from');

      // Previous, from Q2 back to (answered) Q1 — this part already
      // worked before the fix.
      expect(controller.canGoToPrevious, isTrue);
      controller.moveTo(controller.currentIndex - 1);
      expect(controller.currentIndex, 0);

      // The actual regression: Next, from Q1, must be able to return to
      // Q2 — before the fix, canGoToNext required Q2 to be *answered*,
      // which it never was, permanently disabling Next here.
      expect(controller.canGoToNext, isTrue,
          reason: 'Q2 was already reached this session (it is where the '
              'user came from via Previous), so Next must return there '
              'even though Q2 itself was never answered');
      controller.moveTo(controller.currentIndex + 1);
      expect(controller.currentIndex, 1);
    });

    test(
        'Next still refuses to skip ahead to genuinely fresh content past '
        'the furthest point ever reached, even after browsing Previous',
        () async {
      final controller = buildController(InMemoryProgressRepository());
      await controller.submitAnswer(controller.currentQuestion.correctAnswerId);
      controller.moveTo(controller.currentIndex + 1); // now at Q2 (index 1)
      controller.moveTo(controller.currentIndex - 1); // back to Q1 (index 0)

      // Q3 (index 2) was never reached at all — Next must not be able to
      // jump straight there merely because Previous/Next were used.
      expect(controller.currentIndex, 0);
      controller.moveTo(1); // legitimate: returns to the furthest point
      expect(controller.canGoToNext, isFalse,
          reason: 'Q3 is genuinely fresh content — advancing there still '
              'requires submitting an answer for Q2 first, never a bare '
              'navigation tap');
    });

    test(
        'Previous/Next are both disabled at the very start of a fresh '
        'session', () {
      final controller = buildController(InMemoryProgressRepository());
      expect(controller.canGoToPrevious, isFalse);
      expect(controller.canGoToNext, isFalse);
    });

    test(
        'a resumed session can immediately browse Next across its already '
        'genuinely answered questions', () async {
      final repo = InMemoryProgressRepository();
      final firstController = buildController(repo);
      await firstController
          .submitAnswer(firstController.currentQuestion.correctAnswerId);
      firstController.moveTo(1);
      await firstController
          .submitAnswer(firstController.currentQuestion.correctAnswerId);
      // Now at index 2 (Q3), unanswered — matches a real resume point.

      final resumed = await PracticeSessionController.resume(
        session: firstController.session,
        questions: firstController.questions,
        progressRepository: repo,
      );

      expect(resumed.currentIndex, 2);
      resumed.moveTo(0);
      expect(resumed.canGoToNext, isTrue,
          reason: 'Q2 (index 1) was genuinely answered before the '
              'restart, so a resumed session must still let Next reach '
              'it from Q1');
      resumed.moveTo(1);
      expect(resumed.canGoToNext, isTrue,
          reason: 'Q3 (index 2) is exactly where the resumed session '
              'picked back up — the furthest point reached — so Next '
              'must still be able to reach it from Q2');
      resumed.moveTo(2);
      expect(resumed.canGoToNext, isFalse,
          reason: 'Q4 (index 3) is genuinely fresh, never-reached content '
              '— Next must not skip past Q3 without a real submission');
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
