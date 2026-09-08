import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/answer_explanation_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

import '../support/practice_session_test_support.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.lightTheme, home: child);

  group('no active session', () {
    testWidgets('shows an honest empty state, not a fake question',
        (tester) async {
      await tester.pumpWidget(wrap(const PracticeQuestionScreen()));

      expect(find.text('No active practice session'), findsOneWidget);
      // The old hardcoded prototype content must be gone entirely, not
      // just unreachable — there is nothing left to accidentally show it.
      expect(find.textContaining('maximum permissible dose'), findsNothing);
      expect(find.text('Submit Answer'), findsNothing);
      expect(find.text('Previous'), findsNothing);
      expect(find.text('Next'), findsNothing);
    });
  });

  group('reproduces the audited defect', () {
    testWidgets(
        'the question text and position counter reflect the real session, '
        'not a hardcoded literal', (tester) async {
      final controller = buildDemoPracticeSessionController();

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const PracticeQuestionScreen(),
      )));

      // Before the fix this screen always showed the same fixed question
      // text and "QUESTION 12 OF 100", no matter what session/question was
      // active — asserting against the real, distinct demo content (5
      // questions, not 100) is what a hardcoded screen could never satisfy.
      expect(
        find.text(DebugDemoEnvironment.demoQuestions.first.questionText),
        findsOneWidget,
      );
      expect(find.text('QUESTION 1 OF 5'), findsOneWidget);

      // Answer the first question and move to the second — the displayed
      // question must change to match, proving the content is driven by
      // controller state rather than a static literal.
      controller.moveTo(0);
      await controller
          .submitAnswer(DebugDemoEnvironment.demoQuestions[0].correctAnswerId);
      controller.moveTo(1);
      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const PracticeQuestionScreen(),
      )));

      expect(
        find.text(DebugDemoEnvironment.demoQuestions[1].questionText),
        findsOneWidget,
      );
      expect(find.text('QUESTION 2 OF 5'), findsOneWidget);
    });
  });

  group('answering a question', () {
    testWidgets('Submit is disabled until an option is selected',
        (tester) async {
      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: buildDemoPracticeSessionController(),
        child: const PracticeQuestionScreen(),
      )));

      final ElevatedButton button = tester.widget(find.ancestor(
        of: find.text('Submit Answer'),
        matching: find.byType(ElevatedButton),
      ));
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'selecting an option then Submit records the answer and opens '
        'the real explanation for that exact question', (tester) async {
      final controller = buildDemoPracticeSessionController();
      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const PracticeQuestionScreen(),
      )));

      final firstQuestion = DebugDemoEnvironment.demoQuestions.first;
      await tester.tap(find.text(firstQuestion.answers.first.text));
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      expect(controller.isAnswered(firstQuestion.id), isTrue);
      expect(find.byType(AnswerExplanationScreen), findsOneWidget);
      expect(find.text(firstQuestion.explanation), findsOneWidget);
    });

    testWidgets(
        'a rapid double-tap on Submit Answer records exactly one '
        'AnswerAttempt, never two (PREP-457)', (tester) async {
      final repo = InMemoryProgressRepository();
      final questions = DebugDemoEnvironment.demoQuestions;
      final session = PracticeSession(
        id: 'double-submit-test-session',
        examId: DebugDemoEnvironment.demoExamId,
        mode: PracticeMode.quickPractice,
        questionIds: questions.map((q) => q.id).toList(),
        status: SessionStatus.inProgress,
        startedAt: DateTime.utc(2026, 1, 1),
      );
      final controller = PracticeSessionController(
        session: session,
        questions: questions,
        progressRepository: repo,
        now: () => DateTime.utc(2026, 1, 1, 0, 5),
      );

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const PracticeQuestionScreen(),
      )));

      final firstQuestion = questions.first;
      await tester.tap(find.text(firstQuestion.answers.first.text));
      await tester.pump();

      // Invoked directly, twice, with no `pump()` between them — a real
      // rapid double-tap before the button's own `isLoading` guard has
      // had a frame to visually disable it. `tester.tap()` twice in a
      // row would hit-test against a tree that's already navigated away
      // after the first (a harmless but noisy warning); calling the
      // exact same callback the first tap would have triggered is the
      // precise way to simulate two competing activations of one
      // control, matching how the controller-level test already
      // exercises this same guard directly.
      final ElevatedButton button = tester.widget(find.ancestor(
        of: find.text('Submit Answer'),
        matching: find.byType(ElevatedButton),
      ));
      button.onPressed!();
      button.onPressed!();
      await tester.pumpAndSettle();

      final List<AnswerAttempt> attempts =
          await repo.answerAttemptsForExam(DebugDemoEnvironment.demoExamId);
      expect(
        attempts.where((a) => a.questionId == firstQuestion.id),
        hasLength(1),
        reason: 'PracticeSessionController.submitAnswer\'s own in-flight '
            'guard (PREP-664) must prevent a second recorded attempt for '
            'one logical tap, exercised here through the real screen and '
            'button, not just called directly on the controller',
      );
    });
  });

  group('Previous and Next', () {
    testWidgets('are disabled at the start of a fresh session', (tester) async {
      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: buildDemoPracticeSessionController(),
        child: const PracticeQuestionScreen(),
      )));

      final TextButton previous = tester.widget(find.ancestor(
        of: find.text('Previous'),
        matching: find.byType(TextButton),
      ));
      final TextButton next = tester.widget(find.ancestor(
        of: find.text('Next'),
        matching: find.byType(TextButton),
      ));
      expect(previous.onPressed, isNull);
      expect(next.onPressed, isNull);
    });

    testWidgets('Previous returns to an already-answered question in review',
        (tester) async {
      final controller = buildDemoPracticeSessionController();
      await controller
          .submitAnswer(DebugDemoEnvironment.demoQuestions[0].correctAnswerId);
      controller.moveTo(1);

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const PracticeQuestionScreen(),
      )));
      expect(find.text('QUESTION 2 OF 5'), findsOneWidget);

      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 1 OF 5'), findsOneWidget);
      // Already answered: Submit Answer is replaced by a review action,
      // and the options are shown read-only rather than re-selectable.
      expect(find.text('View Explanation'), findsOneWidget);
      expect(find.text('Submit Answer'), findsNothing);
    });

    testWidgets(
        'after Previous, Next actually returns to the not-yet-answered '
        'question you came from (PREP-460 regression — Next used to stay '
        'disabled forever once you stepped back from it)', (tester) async {
      final controller = buildDemoPracticeSessionController();
      await controller
          .submitAnswer(DebugDemoEnvironment.demoQuestions[0].correctAnswerId);
      controller.moveTo(1);

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const PracticeQuestionScreen(),
      )));
      expect(find.text('QUESTION 2 OF 5'), findsOneWidget);

      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(find.text('QUESTION 1 OF 5'), findsOneWidget);

      final TextButton next = tester.widget(find.ancestor(
        of: find.text('Next'),
        matching: find.byType(TextButton),
      ));
      expect(next.onPressed, isNotNull,
          reason: 'Q2 was already reached this session (that is where '
              'Previous just came from) — Next must not be permanently '
              'disabled just because Q2 itself was never answered');

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 2 OF 5'), findsOneWidget);
      expect(find.text('Submit Answer'), findsOneWidget,
          reason: 'Q2 genuinely has not been answered, so returning to it '
              'shows the normal interactive Submit flow, not a fake '
              'review state');
    });
  });

  group('bookmark (PREP-460)', () {
    testWidgets(
        'is available and works while looking at the question itself, '
        'not only afterward on AnswerExplanationScreen', (tester) async {
      final controller = buildDemoPracticeSessionController();
      final String questionId = controller.currentQuestion.id;

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const PracticeQuestionScreen(),
      )));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Bookmark question'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Bookmark question'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Remove bookmark'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(controller.isBookmarked(questionId), isTrue,
          reason: 'the same PracticeSessionController state '
              'AnswerExplanationScreen reads must reflect the toggle '
              'made here');
    });

    testWidgets(
        'reflects a bookmark made on AnswerExplanationScreen when '
        'returning to the same question via Previous', (tester) async {
      final controller = buildDemoPracticeSessionController();
      final String firstQuestionId = controller.currentQuestion.id;
      await controller.submitAnswer(controller.currentQuestion.correctAnswerId);
      // Bookmark from the explanation screen's own controller methods —
      // exercising the same shared state without needing to pump that
      // screen too.
      final bool newValue = controller.toggleBookmarkLocally(firstQuestionId);
      await controller.persistBookmark(firstQuestionId, newValue);
      controller.moveTo(1);

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const PracticeQuestionScreen(),
      )));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Bookmark question'), findsOneWidget,
          reason: 'Q2 was never bookmarked');

      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Remove bookmark'), findsOneWidget,
          reason: 'back on Q1, the bookmark made through the controller '
              '(as AnswerExplanationScreen would) must still show');
    });
  });
}
