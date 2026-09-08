import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/answer_explanation_screen.dart';
import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_results_screen.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

import '../support/practice_session_test_support.dart';

/// Every one of these controls is reachable in the running app but has no
/// backing feature yet (no auth, no session/attempt storage, no
/// notification/audio system). They must not expose a tap action to
/// assistive services — a control with a tap action but no effect is
/// exactly the "silently does nothing" case this suite guards against.
bool _hasTapAction(SemanticsNode node) =>
    node.getSemanticsData().hasAction(SemanticsAction.tap);

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.lightTheme, home: child);

  group('ProfileSettingsScreen', () {
    testWidgets('Push Notifications and Sound Effects have no tap action',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
          ProfileSettingsScreen(themeModeController: ThemeModeController())));

      expect(
          _hasTapAction(
              tester.getSemantics(find.bySemanticsLabel('Push Notifications'))),
          isFalse);
      expect(
          _hasTapAction(
              tester.getSemantics(find.bySemanticsLabel('Sound Effects'))),
          isFalse);
      // "Edit Profile"/"Change Password" no longer exist at all (PREP-459)
      // — this app is accountless with no sign-in and no plan to add one,
      // so there's no account row left to check for a disabled tap
      // action; see test/screens/accountless_no_login_test.dart for the
      // test guarding their absence.

      handle.dispose();
    });

    testWidgets('Push Notifications and Sound Effects switches are disabled',
        (tester) async {
      await tester.pumpWidget(wrap(
          ProfileSettingsScreen(themeModeController: ThemeModeController())));

      final switches = tester.widgetList<Switch>(find.byType(Switch));
      expect(switches, hasLength(2));
      for (final s in switches) {
        expect(s.onChanged, isNull);
      }
    });
  });

  group('AnswerExplanationScreen', () {
    testWidgets('bookmark has no tap action', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final controller = buildDemoPracticeSessionController();
      // Only reached, in practice, for an already-answered question
      // (PREP-668) — see this screen's own doc comment.
      await controller.submitAnswer(controller.currentQuestion.correctAnswerId);
      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const AnswerExplanationScreen(),
      )));

      expect(
          _hasTapAction(
              tester.getSemantics(find.bySemanticsLabel('Bookmark question'))),
          isFalse);

      handle.dispose();
    });
  });

  group('HomeScreen', () {
    testWidgets('the floating action button has no tap action', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const HomeScreen()));

      expect(
          _hasTapAction(tester.getSemantics(find.byType(FloatingActionButton))),
          isFalse);

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
      expect(_hasTapAction(tester.getSemantics(find.text('Review Mistakes'))),
          isFalse);

      handle.dispose();
    });
  });
}
