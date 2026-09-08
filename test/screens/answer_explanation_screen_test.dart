import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/answer_explanation_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

import '../support/practice_session_test_support.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.lightTheme, home: child);

  group('no active session', () {
    testWidgets('shows an honest empty state, not fake review content',
        (tester) async {
      await tester.pumpWidget(wrap(const AnswerExplanationScreen()));

      expect(find.text('No active practice session'), findsOneWidget);
      expect(find.textContaining('National Council on Radiation Protection'),
          findsNothing);
    });
  });

  group('reproduces the audited defect', () {
    testWidgets(
        'the explanation and correct/incorrect highlighting reflect the '
        'real question and the answer actually submitted', (tester) async {
      final controller = buildDemoPracticeSessionController();
      final firstQuestion = DebugDemoEnvironment.demoQuestions.first;
      // Deliberately the *wrong* answer — before the fix, this screen
      // always showed the same fixed "Correct Explanation" content
      // regardless of what was picked.
      await controller.submitAnswer(firstQuestion.answers[1].id);

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const AnswerExplanationScreen(),
      )));

      expect(find.text(firstQuestion.questionText), findsOneWidget);
      expect(find.text(firstQuestion.explanation), findsOneWidget);
      expect(controller.isCorrectFor(firstQuestion.id), isFalse);
    });
  });

  group('Next Question', () {
    testWidgets(
        'advances to the next real question when not the last, by '
        'popping back to the real underlying PracticeQuestionScreen '
        'route, not stacking a new one on top (PREP-457)', (tester) async {
      // A real root screen with PracticeQuestionScreen pushed *onto* it —
      // exactly like production (ExamOverviewScreen pushes
      // PracticeQuestionScreen, which then pushes this screen on top of
      // itself on Submit) — pumping AnswerExplanationScreen alone as the
      // navigator root, as this test used to, could never catch the
      // orphaned-route bug this regression test exists for: there was
      // nothing underneath it to leave behind, and no root to prove
      // Close actually reaches.
      final controller = buildDemoPracticeSessionController();
      final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Center(child: Text('Exam Overview root'))),
      ));
      navigatorKey.currentState!.push(MaterialPageRoute(
        builder: (_) => PracticeSessionScope(
          controller: controller,
          child: const PracticeQuestionScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(
          find.text(DebugDemoEnvironment.demoQuestions[0].answers.first.text));
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      expect(find.byType(AnswerExplanationScreen), findsOneWidget);

      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      expect(controller.currentIndex, 1);
      expect(find.byType(AnswerExplanationScreen), findsNothing);
      expect(find.byType(PracticeQuestionScreen), findsOneWidget);
      expect(
        find.text(DebugDemoEnvironment.demoQuestions[1].questionText),
        findsOneWidget,
      );

      // A second question answered and advanced past — the original bug
      // compounded with every question (one extra dead route each time),
      // so a single cycle alone wasn't strong enough proof; this is what
      // actually matched the reported symptom of needing to tap Close
      // more than once, worsening the longer a session went on.
      await tester.tap(
          find.text(DebugDemoEnvironment.demoQuestions[1].answers.first.text));
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      expect(find.byType(AnswerExplanationScreen), findsOneWidget);
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();
      expect(controller.currentIndex, 2);
      expect(
        find.text(DebugDemoEnvironment.demoQuestions[2].questionText),
        findsOneWidget,
      );

      // The real regression: closing out now must take exactly one tap,
      // not one per question already answered — before this fix, each
      // "Next Question" left a dead PracticeQuestionScreen route behind
      // via pushReplacement, so Close only unwound one dead layer at a
      // time instead of exiting.
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeQuestionScreen), findsNothing);
      expect(find.byType(AnswerExplanationScreen), findsNothing);
      expect(find.text('Exam Overview root'), findsOneWidget,
          reason: 'one tap of Close must exit all the way back to the '
              'screen practice was started from, even after two '
              'questions worth of Next Question transitions');
    });

    testWidgets(
        'completes the session and opens a real Summary on the '
        'last question', (tester) async {
      final controller = buildDemoPracticeSessionController();
      final int lastIndex = controller.totalQuestions - 1;
      controller.moveTo(lastIndex);
      await controller.submitAnswer(
          DebugDemoEnvironment.demoQuestions[lastIndex].correctAnswerId);

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const AnswerExplanationScreen(),
      )));

      expect(find.text('Finish'), findsOneWidget);
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      expect(controller.session.status, SessionStatus.completed);
      expect(controller.session.completedAt, isNotNull);
      expect(find.byType(PracticeSummaryScreen), findsOneWidget);
    });
  });
}
