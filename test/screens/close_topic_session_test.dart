import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import '../study_plan/fixtures.dart';

class FailingCompletionRepository extends InMemoryProgressRepository {
  bool failCompletion = false;
  @override
  Future<void> savePracticeSession(PracticeSession session) async {
    if (failCompletion && session.status == SessionStatus.completed) {
      throw StateError('write failed');
    }
    await super.savePracticeSession(session);
  }
}

void main() {
  for (final mode in [
    PracticeMode.topicPractice,
    PracticeMode.browseDomain,
    PracticeMode.quickPractice
  ]) {
    testWidgets(
        'resumed $mode Close uses persisted mode without a topic callback',
        (tester) async {
      final package = fixture(count: 3);
      final repo = FailingCompletionRepository();
      final controller = PracticeSessionController(
          session: PracticeSession(
              id: 'resumed',
              examId: package.exam.id,
              mode: mode,
              questionIds: package.questions.map((q) => q.id).toList(),
              status: SessionStatus.inProgress,
              startedAt: DateTime.utc(2026)),
          questions: package.questions,
          progressRepository: repo);
      await controller.saveSession();
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
          navigatorKey: nav,
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: Text('Home'))));
      nav.currentState!.push(MaterialPageRoute<void>(
          builder: (_) => PracticeSessionScope(
              controller: controller, child: const PracticeQuestionScreen())));
      await tester.pumpAndSettle();
      if (mode != PracticeMode.quickPractice) {
        repo.failCompletion = true;
        await tester.tap(find.bySemanticsLabel('Close'));
        await tester.pumpAndSettle();
        expect(find.text('Leave without saving?'), findsOneWidget);
        await tester.tap(find.text('Stay here'));
        await tester.pumpAndSettle();
        expect(
            await repo.inProgressPracticeSession(package.exam.id), isNotNull);
        repo.failCompletion = false;
      }
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(
          controller.session.status,
          mode == PracticeMode.quickPractice
              ? SessionStatus.inProgress
              : SessionStatus.completed);
      expect(await repo.answerAttemptsForExam(package.exam.id), isEmpty);
    });
  }

  for (final fail in [false, true]) {
    testWidgets(
        'Close ends partial topic session, unwinds routes, save failure=$fail',
        (tester) async {
      final package = fixture(count: 3);
      final repo = FailingCompletionRepository();
      final controller = PracticeSessionController(
        session: PracticeSession(
            id: 'topic-close',
            examId: package.exam.id,
            mode: PracticeMode.quickPractice,
            questionIds: package.questions.map((q) => q.id).toList(),
            status: SessionStatus.inProgress,
            startedAt: DateTime.utc(2026)),
        questions: package.questions,
        progressRepository: repo,
      );
      await controller.saveSession();
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
          navigatorKey: nav,
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: Text('Topic selection'))));
      Widget question() => PracticeSessionScope(
          controller: controller,
          returnToTopics: () =>
              nav.currentState!.popUntil((route) => route.isFirst),
          child: const PracticeQuestionScreen());
      nav.currentState!
          .push(MaterialPageRoute<void>(builder: (_) => question()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Correct fixture answer'));
      await tester.pump();
      await tester.ensureVisible(find.text('Submit Answer'));
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next Question'));
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();
      // A stale question layer must not turn Close into one-question Back.
      nav.currentState!
          .push(MaterialPageRoute<void>(builder: (_) => question()));
      await tester.pumpAndSettle();
      repo.failCompletion = fail;
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      if (fail) {
        expect(find.text('Leave without saving?'), findsOneWidget);
        await tester.tap(find.text('Stay here'));
        await tester.pumpAndSettle();
        expect(find.byType(PracticeQuestionScreen), findsOneWidget);
        expect(
            await repo.inProgressPracticeSession(package.exam.id), isNotNull);
        repo.failCompletion = false;
        await tester.tap(find.bySemanticsLabel('Close'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Topic selection'), findsOneWidget);
      expect(find.byType(PracticeQuestionScreen), findsNothing);
      expect(controller.session.status, SessionStatus.completed);
      expect(await repo.inProgressPracticeSession(package.exam.id), isNull);
      expect((await repo.answerAttemptsForExam(package.exam.id)).length, 1);
      expect(controller.answeredCount, 1);
    });
  }
}
