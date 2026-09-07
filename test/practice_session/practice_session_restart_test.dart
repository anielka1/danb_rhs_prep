import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';

/// PREP-665: proves a practice session survives a restart *mid-session*
/// against the real, Drift/SQLite-backed `DriftProgressRepository` — not
/// `InMemoryProgressRepository` (which by definition can't lose state
/// across a restart) and not a fake repository *object* kept alive
/// across a "restarted" controller (which only proves the controller's
/// own reload logic, never real file durability). "Restart" here means
/// exactly what it does elsewhere in this suite
/// (`app_database_test.dart`'s "restart durability" group): close this
/// `AppDatabase` connection and open a genuinely new one — over the same
/// on-disk file — before continuing.
void main() {
  test(
      'answering some but not all questions, then restarting, resumes '
      'the same in-progress session with every attempt and question '
      'state recorded so far still present — and none of the '
      'not-yet-answered questions counted', () async {
    final questions = DebugDemoEnvironment.demoQuestions;
    const examId = DebugDemoEnvironment.demoExamId;

    final Directory tempDir =
        Directory.systemTemp.createTempSync('practice_session_restart_test');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final File dbFile = File('${tempDir.path}/app.sqlite');

    final AppDatabase first = AppDatabase.forTesting(NativeDatabase(dbFile));
    final firstRepo = DriftProgressRepository(first);

    final PracticeSession session = PracticeSession(
      id: 'session-1',
      examId: examId,
      mode: PracticeMode.quickPractice,
      questionIds: questions.map((q) => q.id).toList(),
      status: SessionStatus.inProgress,
      startedAt: DateTime.utc(2026, 1, 1),
      contentVersion: 'demo-1',
    );
    await firstRepo.savePracticeSession(session);

    final PracticeSessionController firstController = PracticeSessionController(
      session: session,
      questions: questions,
      progressRepository: firstRepo,
      now: () => DateTime.utc(2026, 1, 1, 0, 5),
    );

    // Answer only the first two of the (at least three) demo questions —
    // "mid-session", not finished.
    expect(questions.length, greaterThanOrEqualTo(3));
    await firstController
        .submitAnswer(firstController.currentQuestion.correctAnswerId);
    firstController.moveTo(1);
    await firstController.submitAnswer(firstController.currentQuestion.answers
        .firstWhere(
            (a) => a.id != firstController.currentQuestion.correctAnswerId)
        .id);

    // Simulates the app/process being killed mid-session: the connection
    // is genuinely closed, not merely left in scope.
    await first.close();

    // "Restart": a brand new AppDatabase and DriftProgressRepository,
    // over the same file — nothing here is the same Dart object as
    // above.
    final AppDatabase reopened = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(reopened.close);
    final reopenedRepo = DriftProgressRepository(reopened);

    final PracticeSession? resumedSession =
        await reopenedRepo.inProgressPracticeSession(examId);
    expect(resumedSession, isNotNull);
    expect(resumedSession!.id, session.id);
    expect(resumedSession.status, SessionStatus.inProgress,
        reason: 'a session interrupted mid-way must not be silently '
            'marked complete or abandoned by surviving a restart');
    expect(resumedSession.contentVersion, 'demo-1');

    final List<AnswerAttempt> attempts =
        await reopenedRepo.answerAttemptsForExam(examId);
    expect(attempts, hasLength(2),
        reason: 'both attempts recorded before the restart must survive '
            'it, and no more than those two');

    final QuestionState firstQuestionState =
        await reopenedRepo.questionState(examId, questions[0].id);
    expect(firstQuestionState.timesSeen, 1);
    expect(firstQuestionState.timesCorrect, 1);
    final QuestionState secondQuestionState =
        await reopenedRepo.questionState(examId, questions[1].id);
    expect(secondQuestionState.timesSeen, 1);
    expect(secondQuestionState.timesIncorrect, 1);
    final QuestionState thirdQuestionState =
        await reopenedRepo.questionState(examId, questions[2].id);
    expect(thirdQuestionState.hasBeenAnswered, isFalse,
        reason: 'a question never reached before the restart must stay '
            'honestly unseen, not fabricated as answered');

    // The resumed controller genuinely continues where it left off —
    // proving the whole stack (repository + controller), not just the
    // repository's own raw rows. PracticeSessionController.resume (not
    // the plain constructor) is what actually restores this from the
    // repository's recorded attempts — see its own doc comment.
    final PracticeSessionController resumedController =
        await PracticeSessionController.resume(
      session: resumedSession,
      questions: questions,
      progressRepository: reopenedRepo,
      now: () => DateTime.utc(2026, 1, 1, 0, 10),
    );
    expect(resumedController.answeredCount, 2);
    expect(resumedController.isAnswered(questions[0].id), isTrue);
    expect(resumedController.isAnswered(questions[1].id), isTrue);
    expect(resumedController.isAnswered(questions[2].id), isFalse);
    expect(resumedController.isCorrectFor(questions[0].id), isTrue);
    expect(resumedController.isCorrectFor(questions[1].id), isFalse);
    expect(resumedController.currentIndex, 2,
        reason: 'a resumed session should land on the first '
            'not-yet-answered question, not back at question one');
  });

  test(
      'the same question answered twice within the same second, then a '
      'real close and reopen of the database, restores the *second* '
      'answer — proving DriftProgressRepository.answerAttemptsForExam\'s '
      'rowid-based ordering (PREP-665), not answeredAt, is what survives '
      'a genuine restart', () async {
    final questions = DebugDemoEnvironment.demoQuestions;
    const examId = DebugDemoEnvironment.demoExamId;

    final Directory tempDir = Directory.systemTemp
        .createTempSync('practice_session_restart_same_second_test');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final File dbFile = File('${tempDir.path}/app.sqlite');

    final AppDatabase first = AppDatabase.forTesting(NativeDatabase(dbFile));
    final firstRepo = DriftProgressRepository(first);

    final PracticeSession session = PracticeSession(
      id: 'session-1',
      examId: examId,
      mode: PracticeMode.quickPractice,
      questionIds: questions.map((q) => q.id).toList(),
      status: SessionStatus.inProgress,
      startedAt: DateTime.utc(2026, 1, 1),
    );
    await firstRepo.savePracticeSession(session);

    // A clock fixed to the exact same instant for both submissions —
    // deliberately reproducing the tie `DriftProgressRepository`'s own
    // doc comment describes: two attempts for the same question, in the
    // same session, with an identical (whole-second) answeredAt.
    final PracticeSessionController firstController = PracticeSessionController(
      session: session,
      questions: questions,
      progressRepository: firstRepo,
      now: () => DateTime.utc(2026, 1, 1, 0, 5, 30),
    );
    final Question q0 = firstController.currentQuestion;
    final String wrongAnswer =
        q0.answers.firstWhere((a) => a.id != q0.correctAnswerId).id;

    await firstController.submitAnswer(wrongAnswer);
    // A genuine "changed my mind" correction — not a double-submit —
    // recorded within the same second as the first.
    await firstController.submitAnswer(q0.correctAnswerId);

    final List<AnswerAttempt> beforeRestart =
        await firstRepo.answerAttemptsForExam(examId);
    expect(beforeRestart, hasLength(2));
    expect(beforeRestart[0].answeredAt, beforeRestart[1].answeredAt,
        reason: 'both attempts must genuinely tie on answeredAt for this '
            'test to actually exercise the rowid tie-break, not merely '
            'assume it');

    // Simulates the app/process being killed: the connection is
    // genuinely closed, not merely left in scope.
    await first.close();

    // "Restart": a brand new AppDatabase and DriftProgressRepository,
    // over the same file.
    final AppDatabase reopened = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(reopened.close);
    final reopenedRepo = DriftProgressRepository(reopened);

    final List<AnswerAttempt> afterRestart =
        await reopenedRepo.answerAttemptsForExam(examId);
    expect(afterRestart, hasLength(2));
    expect(afterRestart.last.selectedAnswerId, q0.correctAnswerId,
        reason: 'the real, on-disk row order — SQLite rowid, assigned at '
            'insertion — must place the second (correcting) attempt '
            'last, exactly as it was before the restart');

    final resumedSession = await reopenedRepo.inProgressPracticeSession(examId);
    final PracticeSessionController resumedController =
        await PracticeSessionController.resume(
      session: resumedSession!,
      questions: questions,
      progressRepository: reopenedRepo,
      now: () => DateTime.utc(2026, 1, 1, 0, 10),
    );

    expect(resumedController.selectedAnswerFor(q0.id), q0.correctAnswerId,
        reason: 'the resumed controller must show the second, correcting '
            'answer — not the first, wrong one it was changed from');
    expect(resumedController.isCorrectFor(q0.id), isTrue);
  });
}
