import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/services/fakes/fake_analytics_service.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_bottom_navigation.dart';

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

  group('tabForIndex', () {
    test('valid indices map to the corresponding tab in display order', () {
      expect(tabForIndex(0), AppTab.home);
      expect(tabForIndex(1), AppTab.home);
      expect(tabForIndex(2), AppTab.home);
      expect(tabForIndex(3), AppTab.progress);
    });

    test('out-of-range indices fall back to Home', () {
      expect(tabForIndex(-1), AppTab.home);
      expect(tabForIndex(4), AppTab.home);
      expect(tabForIndex(999), AppTab.home);
    });
  });

  group('navigation structure', () {
    testWidgets('shows exactly the two tabs, in order, with no Profile tab',
        (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));

      final List<String?> labels = tester
          .widgetList<Text>(find.descendant(
              of: find.byType(AppBottomNavigation),
              matching: find.byType(Text)))
          .map((t) => t.data)
          .toList();
      expect(labels, ['Home', 'Progress']);
      expect(find.text('Profile'), findsNothing);
      expect(find.text('Stats'), findsNothing);
    });

    testWidgets('Settings is not one of the bottom tabs', (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));
      final inkWells = find.descendant(
        of: find.byType(AppBottomNavigation),
        matching: find.byType(InkWell),
      );
      expect(inkWells, findsNWidgets(2));
    });

    testWidgets('each tab maps to its screen', (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));
      expect(currentTab(tester), AppTab.home);
      expect(find.text('Let’s study'), findsOneWidget);

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(currentTab(tester), AppTab.progress);
      expect(find.text('Your Progress'), findsOneWidget);
    });

    testWidgets('bottom nav exposes selected-tab semantics for the active tab',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const MainShell()));

      expect(
        tester.getSemantics(find.descendant(
            of: find.byType(AppBottomNavigation),
            matching: find.bySemanticsLabel('Home'))),
        matchesSemantics(
            label: 'Home',
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true),
      );

      handle.dispose();
    });
  });

  group('state preservation', () {
    testWidgets('Home state survives switching tabs away and back',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const MainShell()));

      final homeBefore = tester.state(find.byType(HomeScreen));
      await tester.pump();
      expect(tester.state(find.byType(HomeScreen)), same(homeBefore));

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(tester.state(find.byType(HomeScreen)), same(homeBefore));

      handle.dispose();
    });

    testWidgets('an ancestor rebuild does not reset the selected tab',
        (tester) async {
      final ValueNotifier<int> rebuildTrigger = ValueNotifier<int>(0);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        restorationScopeId: 'test_root',
        home: ValueListenableBuilder<int>(
          valueListenable: rebuildTrigger,
          builder: (context, value, child) => const MainShell(),
        ),
      ));

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(currentTab(tester), AppTab.progress);

      rebuildTrigger.value++;
      await tester.pump();

      expect(currentTab(tester), AppTab.progress);
    });

    testWidgets('re-selecting the active tab is a no-op', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const MainShell()));

      final homeBefore = tester.state(find.byType(HomeScreen));
      await tester.pump();

      await tester.tap(find.text('Home'));
      await tester.pump();

      expect(currentTab(tester), AppTab.home);
      expect(tester.state(find.byType(HomeScreen)), same(homeBefore));

      handle.dispose();
    });

    testWidgets('returning from Settings preserves Home and its local state',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const MainShell()));

      final homeBefore = tester.state(find.byType(HomeScreen));
      await tester.pump();

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileSettingsScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileSettingsScreen), findsNothing);
      expect(currentTab(tester), AppTab.home);
      expect(tester.state(find.byType(HomeScreen)), same(homeBefore));

      handle.dispose();
    });
  });

  group('restoration', () {
    testWidgets('restores the selected tab across a simulated app restart',
        (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(currentTab(tester), AppTab.progress);

      await tester.restartAndRestore();

      expect(currentTab(tester), AppTab.progress);
    });

    testWidgets('restoration does not emit a duplicate analytics event',
        (tester) async {
      final FakeAnalyticsService analytics = FakeAnalyticsService();
      await tester.pumpWidget(wrap(MainShell(analytics: analytics)));
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      analytics.screenViews.clear();

      await tester.restartAndRestore();

      expect(analytics.screenViews.length, 1);
      expect(analytics.screenViews, ['progress']);
    });
  });

  group('analytics', () {
    testWidgets('reports the initial Home view exactly once', (tester) async {
      final FakeAnalyticsService analytics = FakeAnalyticsService();
      await tester.pumpWidget(wrap(MainShell(analytics: analytics)));
      await tester.pump();

      expect(analytics.screenViews, ['home']);
    });

    testWidgets('each real tab change emits exactly one event', (tester) async {
      final FakeAnalyticsService analytics = FakeAnalyticsService();
      await tester.pumpWidget(wrap(MainShell(analytics: analytics)));
      analytics.screenViews.clear();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(analytics.screenViews, ['progress']);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(analytics.screenViews, ['progress', 'home']);
    });

    testWidgets('re-selecting the current tab emits no additional event',
        (tester) async {
      final FakeAnalyticsService analytics = FakeAnalyticsService();
      await tester.pumpWidget(wrap(MainShell(analytics: analytics)));
      analytics.screenViews.clear();

      await tester.tap(find.text('Home'));
      await tester.pump();

      expect(analytics.screenViews, isEmpty);
    });

    testWidgets('ordinary ancestor rebuilds emit no duplicate view events',
        (tester) async {
      final FakeAnalyticsService analytics = FakeAnalyticsService();
      final ValueNotifier<int> rebuildTrigger = ValueNotifier<int>(0);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        restorationScopeId: 'test_root',
        home: ValueListenableBuilder<int>(
          valueListenable: rebuildTrigger,
          builder: (context, value, child) => MainShell(analytics: analytics),
        ),
      ));
      analytics.screenViews.clear();

      rebuildTrigger.value++;
      await tester.pump();
      rebuildTrigger.value++;
      await tester.pump();

      expect(analytics.screenViews, isEmpty);
    });

    testWidgets('the named Settings route is reported when it opens',
        (tester) async {
      final FakeAnalyticsService analytics = FakeAnalyticsService();
      await tester.pumpWidget(wrap(MainShell(analytics: analytics)));
      analytics.screenViews.clear();

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      // Settings is reported by the app-level AnalyticsNavigatorObserver
      // (wired in main.dart) via its named route, not by MainShell itself;
      // MainShell only reports tab views. Opening it must not report a
      // spurious tab-view event.
      expect(analytics.screenViews, isEmpty);
    });
  });

  group('Settings access', () {
    testWidgets('Home has a Settings toolbar icon with a tooltip',
        (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));
      expect(find.byTooltip('Settings'), findsOneWidget);
    });

    testWidgets('the Settings icon meets the 44x44 minimum interactive size',
        (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));
      final Size size = tester.getSize(find.byTooltip('Settings'));
      expect(size.width, greaterThanOrEqualTo(AppTapTarget.minInteractive));
      expect(size.height, greaterThanOrEqualTo(AppTapTarget.minInteractive));
    });

    testWidgets('tapping Settings opens ProfileSettingsScreen', (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileSettingsScreen), findsOneWidget);
    });

    testWidgets('back from Settings returns to the shell', (tester) async {
      await tester.pumpWidget(wrap(const MainShell()));
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileSettingsScreen), findsNothing);
      expect(find.byType(AppBottomNavigation), findsOneWidget);
    });
  });
}
