import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';

class _Repository extends InMemoryProgressRepository {
  bool failAnswers = false;
  bool failAfterRecordOnce = false;
  bool failSession = false;
  bool failBookmarks = false;
  final calls = <AnswerAttempt>[];
  final sessions = <PracticeSession>[];
  Completer<void>? bookmarkGate;
  Completer<void>? bookmarkReadStarted;

  @override
  Future<void> recordAnswerAttempt(AnswerAttempt attempt) async {
    calls.add(attempt);
    if (failAnswers) throw StateError('disk full');
    await super.recordAnswerAttempt(attempt);
    if (failAfterRecordOnce) {
      failAfterRecordOnce = false;
      throw StateError('response lost after commit');
    }
  }

  @override
  Future<void> savePracticeSession(PracticeSession session) async {
    sessions.add(session);
    if (failSession) throw StateError('disk full');
    await super.savePracticeSession(session);
  }

  @override
  Future<void> saveQuestionState(QuestionState state) async {
    if (failBookmarks) throw StateError('disk full');
    await super.saveQuestionState(state);
  }

  @override
  Future<QuestionState> questionState(String examId, String questionId) async {
    final gate = bookmarkGate;
    bookmarkGate = null;
    final value = await super.questionState(examId, questionId);
    if (gate != null) {
      bookmarkReadStarted!.complete();
      await gate.future;
    }
    return value;
  }
}

void main() {
  PracticeSessionController build(_Repository repo) {
    final session = DebugDemoEnvironment.demoInProgressPracticeSession;
    return PracticeSessionController(
        session: session,
        questions: [
          for (final id in session.questionIds)
            DebugDemoEnvironment.demoQuestions.firstWhere((q) => q.id == id)
        ],
        progressRepository: repo,
        now: () => DateTime.utc(2026, 9, 9, 12));
  }

  test(
      'retry after an uncertain commit reuses the exact attempt and counts once',
      () async {
    final repo = _Repository()..failAfterRecordOnce = true;
    final controller = build(repo);
    await controller.submitAnswer(controller.currentQuestion.correctAnswerId);
    expect(controller.hasUnsavedChanges, isTrue);
    final feedback = controller.feedbackFor(controller.currentQuestion.id);
    await Future.wait([controller.retrySaving(), controller.retrySaving()]);
    expect(repo.calls, hasLength(2));
    expect(repo.calls[0], repo.calls[1]);
    expect(await repo.answerAttemptsForExam(controller.session.examId),
        hasLength(1));
    expect(
        (await repo.questionState(
                controller.session.examId, controller.currentQuestion.id))
            .timesSeen,
        1);
    expect(
        controller.feedbackFor(controller.currentQuestion.id), same(feedback));
    expect(controller.hasUnsavedChanges, isFalse);
  });

  test('failed attempts retain their order and original evaluations', () async {
    final repo = _Repository()..failAnswers = true;
    final controller = build(repo);
    final first = controller.currentQuestion;
    await controller.submitAnswer(first.correctAnswerId);
    controller.moveTo(1);
    final second = controller.currentQuestion;
    final wrong =
        second.answers.firstWhere((a) => a.id != second.correctAnswerId).id;
    await controller.submitAnswer(wrong);
    expect(
        await repo.answerAttemptsForExam(controller.session.examId), isEmpty);
    repo.failAnswers = false;
    await controller.retrySaving();
    final attempts =
        await repo.answerAttemptsForExam(controller.session.examId);
    expect(attempts.map((a) => a.questionId), [first.id, second.id]);
    expect(attempts.map((a) => a.isCorrect), [true, false]);
    expect(controller.correctCount, 1);
    expect(controller.hasUnsavedChanges, isFalse);
  });

  test('retry retains a completed session timestamp after start/save failure',
      () async {
    final repo = _Repository()..failSession = true;
    final controller = build(repo);
    await controller.saveSession();
    expect(controller.hasUnsavedChanges, isTrue);
    await controller.complete();
    final completed = controller.session;
    repo.failSession = false;
    await controller.retrySaving();
    expect(repo.sessions.last, completed);
    expect(repo.sessions.last.status, SessionStatus.completed);
    expect(controller.hasUnsavedChanges, isFalse);
  });

  test(
      'a failed bookmark retries its latest value without losing answer totals',
      () async {
    final repo = _Repository()..failBookmarks = true;
    final controller = build(repo);
    final id = controller.currentQuestion.id;
    await controller.submitAnswer(controller.currentQuestion.correctAnswerId);
    await controller.persistBookmark(id, controller.toggleBookmarkLocally(id));
    expect(controller.hasUnsavedChanges, isTrue);
    await controller.persistBookmark(id, controller.toggleBookmarkLocally(id));
    repo.failBookmarks = false;
    await controller.retrySaving();
    final state = await repo.questionState(controller.session.examId, id);
    expect(state.bookmarked, isFalse);
    expect(state.timesSeen, 1);
    expect(state.timesCorrect, 1);
    expect(controller.hasUnsavedChanges, isFalse);
  });

  test('overlapping bookmark and answer writes preserve both results',
      () async {
    final repo = _Repository();
    final controller = build(repo);
    final gate = Completer<void>();
    repo.bookmarkGate = gate;
    repo.bookmarkReadStarted = Completer<void>();
    final first =
        controller.persistBookmark(controller.currentQuestion.id, true);
    await repo.bookmarkReadStarted!.future;
    final second =
        controller.persistBookmark(controller.currentQuestion.id, false);
    final answer =
        controller.submitAnswer(controller.currentQuestion.correctAnswerId);
    gate.complete();
    await Future.wait([first, second, answer]);
    final state = await repo.questionState(
        controller.session.examId, controller.currentQuestion.id);
    expect(state.bookmarked, isFalse);
    expect(state.timesSeen, 1);
    expect(state.timesCorrect, 1);
  });
}
