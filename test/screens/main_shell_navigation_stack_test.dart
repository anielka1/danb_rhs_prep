import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_bottom_navigation.dart';

import '../support/practice_session_test_support.dart';

/// PREP-654: verifies the per-tab navigation stacks `MainShell` gives
/// Home/Practice/Mock Exam/Progress — each tab keeps its own deep-flow
/// history independently, reselecting the active tab resets it, and the
/// system back gesture only ever affects the currently-visible tab. Uses
/// `ProgressScreen`'s own "Start Practicing" shortcut (real production
/// code, not a test double) to push a real second route onto a tab's own
/// nested `Navigator` without needing a content-package fixture —
/// `ExamOverviewScreen` renders its own honest "not available" state with
/// no content package, which is all this file needs to prove push/pop
/// behavior at the shell level.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      restorationScopeId: 'test_root',
      home: child,
      routes: {
        ProfileSettingsScreen.route: (_) =>
            ProfileSettingsScreen(themeModeController: ThemeModeController()),
      },
    );
  }

  AppTab currentTab(WidgetTester tester) => tester
      .widget<AppBottomNavigation>(find.byType(AppBottomNavigation))
      .current;

  Future<void> pushViaProgressStartPracticing(WidgetTester tester) async {
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Practicing'));
    await tester.pumpAndSettle();
    expect(find.byType(ExamOverviewScreen), findsOneWidget);
  }

  group('per-tab navigation stacks', () {
    testWidgets(
        'switching away and back preserves a deep push in the tab left '
        'behind', (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));

      await pushViaProgressStartPracticing(tester);

      await tester.tap(find.text('Mock Exam'));
      await tester.pumpAndSettle();
      expect(currentTab(tester), AppTab.mockExam);
      expect(find.byType(ExamOverviewScreen), findsNothing,
          reason: "Mock Exam's own tab must not show Progress's pushed "
              'screen');

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(currentTab(tester), AppTab.progress);
      expect(find.byType(ExamOverviewScreen), findsOneWidget,
          reason: 'switching tabs and back must not have reset the '
              "Progress tab's own pushed stack");
    });

    testWidgets('re-selecting the active tab pops its own stack to root',
        (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));

      await pushViaProgressStartPracticing(tester);

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(currentTab(tester), AppTab.progress);
      expect(find.byType(ExamOverviewScreen), findsNothing,
          reason: 're-selecting the already-active tab must pop its own '
              'stack back to root');
      expect(find.text('No progress yet'), findsOneWidget);
    });

    testWidgets(
        're-selecting a tab with nothing pushed remains a harmless no-op',
        (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(currentTab(tester), AppTab.home);
      expect(find.text('Small steps.\nSteady progress.'), findsOneWidget);
    });

    testWidgets(
        'the system back gesture pops within the current tab instead of '
        'leaving MainShell', (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));

      await pushViaProgressStartPracticing(tester);

      // Simulates the platform back gesture the same way `PopScope`'s own
      // test suite does: `maybePop` on the Navigator immediately above
      // `NavigatorPopHandler`'s `PopScope` — here, the app's root
      // Navigator, since `MainShell` is the app's own root-most screen.
      final NavigatorState rootNavigator = Navigator.of(
        tester.element(find.byType(MainShell)),
        rootNavigator: true,
      );
      final bool popped = await rootNavigator.maybePop();
      await tester.pumpAndSettle();

      expect(popped, isTrue,
          reason: 'NavigatorPopHandler must claim the pop on behalf of '
              "Progress's own nested Navigator");
      expect(find.byType(MainShell), findsOneWidget,
          reason: 'the back gesture must stay within the current tab, '
              'never closing MainShell itself');
      expect(currentTab(tester), AppTab.progress);
      expect(find.byType(ExamOverviewScreen), findsNothing,
          reason: "the back gesture must have popped Progress's own "
              'pushed screen');
      expect(find.text('No progress yet'), findsOneWidget);
    });

    testWidgets(
        'the system back gesture does not pop MainShell itself when no tab '
        'has anything to pop', (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));

      final NavigatorState rootNavigator = Navigator.of(
        tester.element(find.byType(MainShell)),
        rootNavigator: true,
      );
      final bool popped = await rootNavigator.maybePop();
      await tester.pumpAndSettle();

      expect(popped, isFalse,
          reason: 'with nothing pushed in any tab, the pop must fall '
              'through rather than being falsely claimed');
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets(
        'returning from Settings (reached from Home) leaves a different '
        "tab's own pushed screen and the active tab untouched", (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));

      // Settings is only ever reached from Home's own toolbar (see
      // `HomeScreen`'s doc comment) — push something in Progress first,
      // then switch to Home (a plain tab switch never resets the tab
      // being left) before opening Settings from there.
      await pushViaProgressStartPracticing(tester);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(currentTab(tester), AppTab.home);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileSettingsScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileSettingsScreen), findsNothing);
      expect(currentTab(tester), AppTab.home,
          reason: 'Settings must not have changed which tab is active');

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(find.byType(ExamOverviewScreen), findsOneWidget,
          reason: "Progress's own pushed stack must survive a round trip "
              "through Home's Settings, which lives on the root "
              'navigator');
    });

    testWidgets(
        "Back to Home resets whichever tab a session actually lives on "
        "(here, Home's own stack, as a cross-tab shortcut would leave it) "
        'rather than a hardcoded tab', (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));
      expect(currentTab(tester), AppTab.home);

      // Simulates what a cross-tab shortcut (e.g. Home's own "Start
      // Practicing") actually does: push the practice flow onto the
      // *caller's* own nested Navigator, never switching the active tab
      // to do it — so the finished PracticeSummaryScreen ends up living
      // on Home's stack, not Practice's, even though Practice is where
      // this flow "conceptually" belongs.
      final BuildContext homeContext = tester.element(find.byType(HomeScreen));
      Navigator.of(homeContext).push(MaterialPageRoute(
        builder: (_) => PracticeSessionScope(
          controller: buildDemoPracticeSessionController(),
          child: const PracticeSummaryScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSummaryScreen), findsOneWidget);

      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeSummaryScreen), findsNothing,
          reason: "Back to Home must reset the tab the session actually "
              'lives on (Home), not a hardcoded Practice tab that never '
              'had anything pushed');
      expect(currentTab(tester), AppTab.home);

      // Practice's own, entirely separate tab stack was never touched by
      // this — it still shows its normal root when visited.
      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
      expect(find.byType(ExamOverviewScreen), findsOneWidget);
      expect(find.byType(PracticeSummaryScreen), findsNothing);
    });
  });
}
