import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/answer_explanation_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

/// A [ProgressRepository] whose reads/writes always throw — for proving
/// the bookmark toggle is genuinely best-effort (PREP-460), the same
/// philosophy already established for submitAnswer/resume.
class _ThrowingProgressRepository implements ProgressRepository {
  @override
  Future<QuestionState> questionState(String examId, String questionId) {
    throw StateError('offline');
  }

  @override
  Future<void> saveQuestionState(QuestionState state) {
    throw StateError('offline');
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used by this test');
}

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.lightTheme, home: child);

  PracticeSessionController buildController({ProgressRepository? repo}) {
    final questions = DebugDemoEnvironment.demoQuestions;
    final session = PracticeSession(
      id: 'bookmark-test-session',
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

  group('AnswerExplanationScreen bookmark (PREP-460)', () {
    testWidgets(
        'starts unbookmarked, and tapping it bookmarks the question — '
        'real icon/color/label change, and it persists via '
        'ProgressRepository', (tester) async {
      final repo = InMemoryProgressRepository();
      final controller = buildController(repo: repo);
      final String questionId = controller.currentQuestion.id;
      await controller.submitAnswer(controller.currentQuestion.correctAnswerId);

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const AnswerExplanationScreen(),
      )));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Bookmark question'), findsOneWidget,
          reason: 'starts unbookmarked — no seeded QuestionState exists');
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Bookmark question'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Remove bookmark'), findsOneWidget,
          reason: 'the label itself changes, not just the icon/color — '
              'never relying on color alone');
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

      final QuestionState persisted =
          await repo.questionState(DebugDemoEnvironment.demoExamId, questionId);
      expect(persisted.bookmarked, isTrue,
          reason: 'the toggle must actually reach ProgressRepository, not '
              'just flip a local, throwaway bool');
    });

    testWidgets('tapping a bookmarked question again removes the bookmark',
        (tester) async {
      final repo = InMemoryProgressRepository();
      final controller = buildController(repo: repo);
      await controller.submitAnswer(controller.currentQuestion.correctAnswerId);

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const AnswerExplanationScreen(),
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Bookmark question'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Remove bookmark'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Bookmark question'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

      final QuestionState persisted = await repo.questionState(
          DebugDemoEnvironment.demoExamId, controller.currentQuestion.id);
      expect(persisted.bookmarked, isFalse);
    });

    testWidgets(
        'shows a question that was already bookmarked in an earlier '
        'session as bookmarked from the start', (tester) async {
      final String questionId = DebugDemoEnvironment.demoQuestions.first.id;
      final repo = InMemoryProgressRepository(seedQuestionStates: [
        QuestionState(
          examId: DebugDemoEnvironment.demoExamId,
          questionId: questionId,
          bookmarked: true,
          timesSeen: 1,
          timesCorrect: 1,
          timesIncorrect: 0,
          consecutiveCorrect: 1,
          lastAnsweredAt: DateTime.utc(2025, 12, 1),
        ),
      ]);
      final controller = buildController(repo: repo);
      await controller.submitAnswer(controller.currentQuestion.correctAnswerId);

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const AnswerExplanationScreen(),
      )));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Remove bookmark'), findsOneWidget,
          reason: 'the persisted bookmark from a prior session must be '
              'loaded and shown, not silently reset to unbookmarked');
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });

    testWidgets(
        'with no ProgressRepository at all, the toggle still updates the '
        'interactive UI (just doesn\'t persist) — never crashes',
        (tester) async {
      final controller = buildController();
      await controller.submitAnswer(controller.currentQuestion.correctAnswerId);

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const AnswerExplanationScreen(),
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Bookmark question'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Remove bookmark'), findsOneWidget);
    });

    testWidgets(
        'a ProgressRepository that fails to read/write never crashes the '
        'toggle — the interactive result stands even though nothing '
        'persisted', (tester) async {
      final controller = buildController(repo: _ThrowingProgressRepository());
      await controller.submitAnswer(controller.currentQuestion.correctAnswerId);

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const AnswerExplanationScreen(),
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Bookmark question'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Remove bookmark'), findsOneWidget,
          reason: 'the local, optimistic toggle still reflects the tap '
              'even though persistence failed');
    });
  });
}
