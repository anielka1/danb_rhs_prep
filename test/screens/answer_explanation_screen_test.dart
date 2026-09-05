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
    testWidgets('advances to the next real question when not the last',
        (tester) async {
      final controller = buildDemoPracticeSessionController();
      await controller
          .submitAnswer(DebugDemoEnvironment.demoQuestions[0].correctAnswerId);

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const AnswerExplanationScreen(),
      )));

      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      expect(controller.currentIndex, 1);
      expect(find.byType(PracticeQuestionScreen), findsOneWidget);
      expect(
        find.text(DebugDemoEnvironment.demoQuestions[1].questionText),
        findsOneWidget,
      );
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
