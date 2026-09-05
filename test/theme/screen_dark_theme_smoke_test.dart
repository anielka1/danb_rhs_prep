import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/answer_explanation_screen.dart';
import 'package:danb_rhs_prep/screens/login_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_results_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

import '../support/practice_session_test_support.dart';

/// The full-theme task ("Pelny motyw jasny i ciemny") calls for manually
/// checking every screen under both themes. These five are the app's
/// heaviest users of the success/error/warning semantic-color roles
/// (correct/incorrect answer states, score bands, disabled auth rows) —
/// exactly where a missing `AppSemanticColors` lookup or an unreadable
/// color pairing would surface — yet none of them was ever pumped under
/// [AppTheme.darkTheme] anywhere in the suite before this file: every
/// existing reference (`disabled_controls_test.dart`,
/// `dynamic_type_test.dart`, `essential_label_visibility_test.dart`,
/// `focus_order_test.dart`) hardcodes [AppTheme.lightTheme]. Their
/// constituent widgets (AnswerOptionTile, PrimaryButton, AppCard, ...) do
/// have dark-theme widget tests, but that doesn't prove the *screens*
/// compose those widgets under dark without error — `context.semanticColors`
/// asserts non-null (`Theme.of(this).extension<AppSemanticColors>()!`),
/// so a theme that forgot to register the extension would only fail at
/// the screen level, under the theme that hits the affected code path.
void main() {
  Widget wrap(Widget child, ThemeData theme) =>
      MaterialApp(theme: theme, home: child);

  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    final String label = theme.brightness == Brightness.dark ? 'dark' : 'light';

    testWidgets('LoginScreen renders without error in $label theme',
        (tester) async {
      await tester.pumpWidget(wrap(const LoginScreen(), theme));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('AnswerExplanationScreen renders without error in $label theme',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
        PracticeSessionScope(
          controller: buildDemoPracticeSessionController(),
          child: const AnswerExplanationScreen(),
        ),
        theme,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Bookmark question'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('PracticeQuestionScreen renders without error in $label theme',
        (tester) async {
      await tester.pumpWidget(wrap(
        PracticeSessionScope(
          controller: buildDemoPracticeSessionController(),
          child: const PracticeQuestionScreen(),
        ),
        theme,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('MockExamResultsScreen renders without error in $label theme',
        (tester) async {
      await tester.pumpWidget(wrap(const MockExamResultsScreen(), theme));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('No completed mock exam'), findsOneWidget);
      expect(find.text('Review Answers'), findsNothing);
    });

    testWidgets('PracticeSummaryScreen renders without error in $label theme',
        (tester) async {
      await tester.pumpWidget(wrap(
        PracticeSessionScope(
          controller: buildDemoPracticeSessionController(),
          child: const PracticeSummaryScreen(),
        ),
        theme,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Review Mistakes'), findsOneWidget);
    });
  }
}
