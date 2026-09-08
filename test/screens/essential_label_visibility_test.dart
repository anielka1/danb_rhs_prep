import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/screens/answer_explanation_screen.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/mock_exam_results_screen.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_bottom_navigation.dart';

import '../support/dynamic_type_probe.dart';

/// Bottom-navigation labels and `AppScaffold` titles must render at the
/// device's real, requested text scale — never truncated with an
/// ellipsis, and never shrunk back down after the fact to make them fit
/// (a `FittedBox`/`Transform.scale` "fix" that visually overrides the
/// user's chosen accessibility text size is exactly as unacceptable as
/// truncating). This file inspects the real render tree to prove both
/// failure modes are absent, not just that some text happens to be
/// present:
///
///  - `RenderParagraph.didExceedMaxLines` catches silent line-truncation.
///  - Comparing `tester.getRect(...).size` (the label's real, final
///    on-screen size — the same "where does this actually appear"
///    lookup `pumpAndSettle`-based tap-location tests rely on) against
///    `tester.getSize(...)` (the label's own natural, pre-transform
///    layout size) catches a shrink. These two deliberately differ from
///    each other only when something between the label and the screen
///    — a `FittedBox`'s scale-down, a `Transform.scale` — repaints it
///    smaller than it laid out: `RenderParagraph.size` (what
///    `getSize` returns) reports its natural size regardless of such an
///    ancestor, since that transform is applied at paint time, on top,
///    which is exactly why naively checking `getSize` alone (as an
///    earlier version of this file did) cannot see a shrink — verified
///    empirically against a synthetic `FittedBox(fit: scaleDown)`
///    fixture before writing this the way it now is.
///  - An exact `find.text(label)` match confirms the complete label, not
///    an ellipsized fragment.
///  - `MediaQuery.textScalerOf` at the label's own location confirms the
///    device's requested 4.0x scale actually reached it.
void main() {
  RenderParagraph paragraphFor(WidgetTester tester, Finder textFinder) {
    return tester.renderObject<RenderParagraph>(textFinder);
  }

  void expectNoShrinkingAncestor(WidgetTester tester, Finder finder) {
    expect(
      find.ancestor(of: finder, matching: find.byType(FittedBox)),
      findsNothing,
      reason: 'a FittedBox ancestor would shrink this label after layout, '
          'overriding the requested text scale',
    );
    final Size naturalSize = tester.getSize(finder);
    final Size paintedSize = tester.getRect(finder).size;
    expect(
      paintedSize.height,
      moreOrLessEquals(naturalSize.height, epsilon: 0.5),
      reason: 'this label\'s real on-screen height (${paintedSize.height}) '
          'differs from its natural, laid-out height '
          '(${naturalSize.height}) — something between it and the screen '
          'is scaling it down from the requested text size',
    );
  }

  group('bottom navigation labels at 4.0x on a 320x568 viewport', () {
    const labels = ['Home', 'Practice', 'Mock Exam', 'Progress'];

    testWidgets('every label is present at full text, full scale, never shrunk',
        (tester) async {
      await pumpAtScale(
        tester,
        MaterialApp(theme: AppTheme.lightTheme, home: const MainShell()),
        viewport: ProbeViewport.exitCriteriaSmallPhone,
        textScale: 4.0,
      );

      for (final label in labels) {
        // find.text() searches the whole element tree regardless of
        // scroll position, so this holds whether the bar is currently
        // in its four-column layout or its scrollable one.
        final Finder finder = find.text(label);
        expect(finder, findsOneWidget,
            reason: '"$label" must render as its exact, complete text — '
                'not truncated with an ellipsis');

        final RenderParagraph paragraph = paragraphFor(tester, finder);
        expect(paragraph.didExceedMaxLines, isFalse,
            reason: '"$label" silently needed more lines than its cap '
                'allows, which would have been hidden rather than shown');

        expectNoShrinkingAncestor(tester, finder);

        expect(
          MediaQuery.textScalerOf(tester.element(finder)),
          const TextScaler.linear(4.0),
          reason: '"$label" must actually receive the requested 4.0x text '
              'scaler, not a clamped or overridden one',
        );
      }
    });

    testWidgets('all four tabs remain tappable and switch the shell',
        (tester) async {
      await pumpAtScale(
        tester,
        MaterialApp(theme: AppTheme.lightTheme, home: const MainShell()),
        viewport: ProbeViewport.exitCriteriaSmallPhone,
        textScale: 4.0,
      );

      AppTab currentTab() => tester
          .widget<AppBottomNavigation>(find.byType(AppBottomNavigation))
          .current;

      const order = [
        ('Practice', AppTab.practice),
        ('Mock Exam', AppTab.mockExam),
        ('Progress', AppTab.progress),
        ('Home', AppTab.home),
      ];

      for (final (label, tab) in order) {
        final Finder finder = find.text(label);
        // Scrolls the bar's own Scrollable into position when the
        // scrollable (non-four-column) layout is in use; a no-op when
        // it isn't, since there's then nothing to scroll.
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(currentTab(), tab,
            reason: 'tapping "$label" must select its tab');
      }
    });
  });

  group('AppScaffold titles at 4.0x on a 320x568 viewport', () {
    Widget appWith(Widget home) =>
        MaterialApp(theme: AppTheme.lightTheme, home: home);

    final titledScreens = <String, Widget Function()>{
      'Let’s practice.': () => const ExamOverviewScreen(),
      'Review Question': () => const AnswerExplanationScreen(),
      'Exam Results': () => const MockExamResultsScreen(),
      'Settings': () =>
          ProfileSettingsScreen(themeModeController: ThemeModeController()),
    };

    for (final entry in titledScreens.entries) {
      final String title = entry.key;
      testWidgets('"$title" is present at full text, full scale, never shrunk',
          (tester) async {
        await pumpAtScale(
          tester,
          appWith(entry.value()),
          viewport: ProbeViewport.exitCriteriaSmallPhone,
          textScale: 4.0,
        );

        final Finder finder = find.text(title);
        expect(finder, findsOneWidget,
            reason: 'the "$title" header must render as its exact, '
                'complete text — not truncated with an ellipsis');

        final RenderParagraph paragraph = paragraphFor(tester, finder);
        expect(paragraph.didExceedMaxLines, isFalse,
            reason: 'the "$title" header silently needed more lines than '
                'its cap allows, which would have been hidden rather than '
                'shown');

        expectNoShrinkingAncestor(tester, finder);

        expect(
          MediaQuery.textScalerOf(tester.element(finder)),
          const TextScaler.linear(4.0),
          reason: 'the "$title" header must actually receive the '
              'requested 4.0x text scaler, not a clamped or overridden one',
        );
      });
    }
  });
}
