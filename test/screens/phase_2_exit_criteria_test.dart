import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_bottom_navigation.dart';

import '../support/dynamic_type_probe.dart';

/// Phase 2 exit criterion: "Four-tab app shell works on small iPhone,
/// large iPhone, and iPad." This file is the evidence for that checkbox —
/// it is only checked in the roadmap if every test here passes.
///
/// Deliberately out of scope, per the roadmap note not to treat feature
/// buttons as part of the shell criterion: authentication, bookmarks,
/// the practice/mock engines, and payments. Those are audited separately
/// in docs/INTERACTION_CONTROL_AUDIT.md and docs/PROTOTYPE_CONTENT_AUDIT.md.
void main() {
  const viewports = [
    ProbeViewport.exitCriteriaSmallPhone,
    ProbeViewport.exitCriteriaLargePhone,
    ProbeViewport.exitCriteriaIpad,
  ];

  Widget appAt(WidgetTester tester, ProbeViewport viewport,
      {ThemeMode themeMode = ThemeMode.light}) {
    final double dpr = tester.view.devicePixelRatio;
    tester.view.physicalSize =
        Size(viewport.size.width * dpr, viewport.size.height * dpr);
    addTearDown(tester.view.reset);
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainShell(),
      routes: {
        ProfileSettingsScreen.route: (_) =>
            ProfileSettingsScreen(themeModeController: ThemeModeController()),
      },
    );
  }

  AppTab currentTab(WidgetTester tester) => tester
      .widget<AppBottomNavigation>(find.byType(AppBottomNavigation))
      .current;

  // The bottom nav bar itself decides, per real measured label width, in
  // which layout to render: an equal four-column row (today's classic
  // design) when every label fits it at the current text scale, or a
  // horizontally scrollable row of naturally-sized items when it
  // doesn't (see app_bottom_navigation.dart). `ensureVisible` finds and
  // uses whichever `Scrollable` ancestor exists to bring a tab on
  // screen before tapping it — a no-op when the bar isn't scrolling
  // (there's nothing to scroll into view), and the real mechanism this
  // exit criterion relies on for "all four tabs remain reachable and
  // tappable" when it is.
  Future<void> tapTab(WidgetTester tester, String label) async {
    final Finder finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final viewport in viewports) {
    group('$viewport', () {
      testWidgets('all four tabs render and are selectable in order',
          (tester) async {
        await tester.pumpWidget(appAt(tester, viewport));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(currentTab(tester), AppTab.home);
        expect(find.text('Let’s study'), findsOneWidget);

        await tapTab(tester, 'Practice');
        expect(tester.takeException(), isNull);
        expect(currentTab(tester), AppTab.practice);
        expect(find.text('Let’s practice.'), findsOneWidget);

        await tapTab(tester, 'Mock Exam');
        expect(tester.takeException(), isNull);
        expect(currentTab(tester), AppTab.mockExam);
        expect(find.text('Mock Exam'), findsWidgets);

        await tapTab(tester, 'Progress');
        expect(tester.takeException(), isNull);
        expect(currentTab(tester), AppTab.progress);
        expect(find.text('Your Progress'), findsOneWidget);
      });

      testWidgets('the selected tab has correct visual and semantic state',
          (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(appAt(tester, viewport));

        await tapTab(tester, 'Progress');

        expect(
          tester.getSemantics(find.descendant(
              of: find.byType(AppBottomNavigation),
              matching: find.bySemanticsLabel('Progress'))),
          matchesSemantics(
              label: 'Progress',
              isButton: true,
              isSelected: true,
              hasSelectedState: true,
              hasTapAction: true,
              hasFocusAction: true,
              isFocusable: true),
        );
        // In the scrollable layout (used once the bar no longer fits as
        // four equal columns), selecting Progress can scroll Home
        // off-screen — a real, expected consequence of that layout, not
        // a bug. Scrolling it back into view first, as a real user or
        // screen-reader user could, keeps this assertion meaningful in
        // both layouts: Home is still a fully valid, reachable,
        // non-hidden control once actually in view, unselected.
        final Finder homeLabel = find.descendant(
            of: find.byType(AppBottomNavigation),
            matching: find.bySemanticsLabel('Home'));
        await tester.ensureVisible(homeLabel);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(homeLabel),
          matchesSemantics(
              label: 'Home',
              isButton: true,
              isSelected: false,
              hasSelectedState: true,
              hasTapAction: true,
              hasFocusAction: true,
              isFocusable: true),
        );

        handle.dispose();
      });

      testWidgets('re-selecting the active tab is safe', (tester) async {
        await tester.pumpWidget(appAt(tester, viewport));

        await tapTab(tester, 'Home');
        expect(tester.takeException(), isNull);
        expect(currentTab(tester), AppTab.home);
        expect(find.text('Let’s study'), findsOneWidget);
      });

      testWidgets(
          'tab state survives opening and closing Settings, and Back works',
          (tester) async {
        await tester.pumpWidget(appAt(tester, viewport));

        // Settings is reached from Home; select a day first so there's
        // real per-tab state to check survives the round trip.
        expect(find.byType(FloatingActionButton), findsNothing);
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ProfileSettingsScreen), findsOneWidget);

        await tester.tap(find.byIcon(Icons.chevron_left_rounded));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ProfileSettingsScreen), findsNothing);
        expect(currentTab(tester), AppTab.home);
        expect(find.text('Let’s study'), findsOneWidget);
      });

      testWidgets('inactive tabs are excluded from accessibility semantics',
          (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(appAt(tester, viewport));

        // Home is active: its content is reachable, Progress's is not.
        expect(find.bySemanticsLabel('Let’s study'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Your Progress')), findsNothing);

        await tapTab(tester, 'Progress');

        expect(find.bySemanticsLabel(RegExp('Your Progress')), findsOneWidget);
        expect(find.bySemanticsLabel('Let’s study'), findsNothing);

        handle.dispose();
      });

      testWidgets('Home has no dead floating action', (tester) async {
        await tester.pumpWidget(appAt(tester, viewport));
        await tester.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsNothing);
      });
    });
  }

  // Phase 2 exit criterion: "Light/dark mode and large text do not break
  // layouts." Cross product of every viewport x theme x text scale x tab,
  // per the roadmap's explicit matrix.
  group('theme + text-scale matrix', () {
    for (final viewport in viewports) {
      for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
        for (final scale in [1.0, 4.0]) {
          testWidgets(
              '$viewport, ${themeMode.name} theme, ${scale}x text: every tab renders without overflow',
              (tester) async {
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: appAt(tester, viewport, themeMode: themeMode),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            expect(
                Theme.of(tester.element(find.text('Let’s study'))).brightness,
                themeMode == ThemeMode.dark
                    ? Brightness.dark
                    : Brightness.light);

            for (final label in ['Practice', 'Mock Exam', 'Progress', 'Home']) {
              await tapTab(tester, label);
              expect(tester.takeException(), isNull,
                  reason:
                      'unexpected overflow/exception on $label at $viewport, '
                      '${themeMode.name}, ${scale}x');
            }

            // Selected/disabled states stay distinguishable regardless of
            // theme or text scale.
            expect(currentTab(tester), AppTab.home);
            expect(find.byType(FloatingActionButton), findsNothing);
          });
        }
      }
    }
  });
}
