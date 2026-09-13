import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/main.dart';
import 'package:danb_rhs_prep/widgets/app_card.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';

import '../support/app_bootstrap_test_support.dart';

void main() {
  Future<void> launchToHome(
      WidgetTester tester, ThemeModeController controller) async {
    // onboardingComplete: true — a returning user, reaching Home directly
    // — since this file is about theme selection from Settings, not
    // onboarding routing.
    final boot = readyAppBootstrap();
    await tester.pumpWidget(DanbRhsPrepApp(
      themeModeController: controller,
      bootstrapService: boot.bootstrapService,
      localStore: boot.localStore,
    ));
    // Real async bootstrap completion, not a fixed-duration pump.
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'System, Light and Dark are all selectable and the whole app updates immediately',
      (tester) async {
    final controller = ThemeModeController();
    await launchToHome(tester, controller);
    await openSettings(tester);

    // Starts at System (the controller's default).
    expect(controller.value, ThemeMode.system);

    await tester.ensureVisible(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(controller.value, ThemeMode.dark);
    expect(Theme.of(tester.element(find.text('Settings'))).brightness,
        Brightness.dark);

    await tester.ensureVisible(find.text('Light'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(controller.value, ThemeMode.light);
    expect(Theme.of(tester.element(find.text('Settings'))).brightness,
        Brightness.light);

    await tester.ensureVisible(find.text('System'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(controller.value, ThemeMode.system);
  });

  testWidgets(
      'the theme selection survives navigating to another tab and back to Settings',
      (tester) async {
    final controller = ThemeModeController();
    await launchToHome(tester, controller);
    await openSettings(tester);

    await tester.ensureVisible(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(controller.value, ThemeMode.dark);

    // Close Settings, switch tabs, come back to Home, reopen Settings.
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await openSettings(tester);

    expect(controller.value, ThemeMode.dark);
    final AppCard selected = tester.widget(find.ancestor(
        of: find.text('Dark'),
        matching:
            find.byWidgetPredicate((w) => w is AppCard && w.selected != null)));
    expect(selected.selected, isTrue);
    // And the app is still actually dark, not just the stored value.
    expect(Theme.of(tester.element(find.text('Settings'))).brightness,
        Brightness.dark);
  });

  testWidgets(
      'the theme controller lives above MaterialApp, not inside ProfileSettingsScreen: '
      'MainShell rebuilding does not reset it', (tester) async {
    final controller = ThemeModeController();
    await launchToHome(tester, controller);
    await openSettings(tester);
    await tester.ensureVisible(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    // Rebuilding MainShell (e.g. switching tabs) must not touch the
    // application-level controller.
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();

    expect(controller.value, ThemeMode.dark);
  });
}
