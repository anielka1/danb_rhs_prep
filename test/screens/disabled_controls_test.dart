import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_results_screen.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

import '../support/practice_session_test_support.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.lightTheme, home: child);

  group('ProfileSettingsScreen', () {
    testWidgets('Push Notifications and Sound Effects have no tap action',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
          ProfileSettingsScreen(themeModeController: ThemeModeController())));

      expect(find.text('Push Notifications'), findsNothing);
      expect(find.text('Sound Effects'), findsNothing);
      handle.dispose();
    });

    testWidgets('Push Notifications and Sound Effects switches are disabled',
        (tester) async {
      await tester.pumpWidget(wrap(
          ProfileSettingsScreen(themeModeController: ThemeModeController())));

      final switches = tester.widgetList<Switch>(find.byType(Switch));
      expect(switches, isEmpty);
      for (final s in switches) {
        expect(s.onChanged, isNull);
      }
    });
  });

  // AnswerExplanationScreen's bookmark control is no longer a no-op
  // (PREP-460): it's a real toggle now, covered by
  // test/screens/answer_explanation_bookmark_test.dart instead.

  group('HomeScreen', () {
    testWidgets('the floating action button has no tap action', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const HomeScreen()));

      expect(find.byType(FloatingActionButton), findsNothing);

      handle.dispose();
    });
  });

  group('MockExamResultsScreen and PracticeSummaryScreen', () {
    testWidgets('"Review Answers" / "Review Mistakes" have no tap action',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const MockExamResultsScreen()));
      expect(find.text('Review Answers'), findsNothing,
          reason:
              'No completed mock means no review action or invented result.');

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: buildDemoPracticeSessionController(),
        child: const PracticeSummaryScreen(),
      )));
      expect(find.text('Review Mistakes'), findsNothing);
      expect(find.text('No mistakes in this session'), findsOneWidget);

      handle.dispose();
    });
  });
}
