import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/study_plan/planned_session_service.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'fixtures.dart';

class _FlakyRepository extends InMemoryProgressRepository {
  bool failNextAnswer = false;
  @override
  Future<void> recordAnswerAttempt(AnswerAttempt answer) async {
    if (failNextAnswer) {
      failNextAnswer = false;
      throw StateError('transient answer write');
    }
    await super.recordAnswerAttempt(answer);
  }

  int historyReads = 0;
  int? failHistoryRead;
  bool failNextSave = false;
  bool persistBeforeFailure = false;
  int saveCalls = 0;

  @override
  Future<List<AnswerAttempt>> answerAttemptsForExam(String examId) async {
    historyReads++;
    if (historyReads == failHistoryRead) {
      throw StateError('transient history read failure');
    }
    return super.answerAttemptsForExam(examId);
  }

  @override
  Future<void> savePracticeSession(PracticeSession session) async {
    saveCalls++;
    if (failNextSave) {
      failNextSave = false;
      if (persistBeforeFailure) await super.savePracticeSession(session);
      throw StateError('transient session save failure');
    }
    await super.savePracticeSession(session);
  }
}

void main() {
  final now = DateTime.utc(2026, 9, 12);
  final package = fixture();
  final entitlement = Entitlement.free(lastVerifiedAt: now);

  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.lightTheme, home: child);

  Future<PracticeSessionController> savedSession(
      _FlakyRepository repo, PracticeMode mode) async {
    final questions = package.questions.take(3).toList();
    final saved = PracticeSession(
        id: 'existing-${mode.name}',
        examId: package.exam.id,
        mode: mode,
        questionIds: questions.map((q) => q.id).toList(),
        status: SessionStatus.inProgress,
        startedAt: now,
        contentVersion: 'historical-content',
        planDate: '2026-09-12');
    await repo.savePracticeSession(saved);
    final c = PracticeSessionController(
        session: saved,
        questions: questions,
        progressRepository: repo,
        now: () => now);
    await c.submitAnswer('b', confident: false);
    return c;
  }

  for (final mode in PracticeMode.values) {
    test('second history read fails closed and retry restores ${mode.name}',
        () async {
      final repo = _FlakyRepository();
      final original = await savedSession(repo, mode);
      final feedback = original.feedbackFor(original.questions.first.id)!;
      repo.failHistoryRead = 2;
      Future<PracticeSessionController> start() =>
          const PlannedSessionService().start(
              package: package,
              repository: repo,
              entitlement: entitlement,
              now: () => now,
              diagnostic: mode == PracticeMode.diagnostic);
      // The service's first read succeeds; resume's second read fails.
      await expectLater(start(), throwsStateError);
      expect(repo.historyReads, 2);
      expect(repo.saveCalls, 1);
      expect((await repo.practiceSessionsForExam(package.exam.id)).single.id,
          original.session.id);
      final retried = await start();
      expect(retried.session.id, original.session.id);
      expect(retried.session.mode, mode);
      expect(retried.session.questionIds, original.session.questionIds);
      expect(retried.answeredCount, 1);
      expect(retried.currentIndex, 1);
      final restored = retried.feedbackFor(original.questions.first.id)!;
      expect(restored.selectedAnswerId, feedback.selectedAnswerId);
      expect(restored.correctAnswerId, feedback.correctAnswerId);
      expect(restored.explanation, feedback.explanation);
      expect(restored.questionVersion, feedback.questionVersion);
      expect(restored.contentVersion, 'historical-content');
      expect(restored.isCorrect, isFalse);
      expect(await repo.answerAttemptsForExam(package.exam.id), hasLength(1));
      expect(repo.saveCalls, 1);
    });
  }

  testWidgets(
      'practice setup catches resume failure and retries existing answers',
      (tester) async {
    final repo = _FlakyRepository();
    final original = await savedSession(repo, PracticeMode.quickPractice);
    await tester.pumpWidget(wrap(ExamOverviewScreen(
        contentPackage: package, progressRepository: repo, now: () => now)));
    await tester.pumpAndSettle();
    repo.failHistoryRead = repo.historyReads + 1;
    await tester.ensureVisible(find.text('Start Practice Exam'));
    await tester.tap(find.text('Start Practice Exam'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeQuestionScreen), findsNothing);
    expect(find.text('Could not restore your saved answers. Please try again.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Start Practice Exam'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeQuestionScreen), findsOneWidget);
    final c = PracticeSessionScope.of(
        tester.element(find.byType(PracticeQuestionScreen)));
    expect(c.session.id, original.session.id);
    expect(c.answeredCount, 1);
    expect(c.currentIndex, 1);
    expect(repo.saveCalls, 1);
  });
}
