import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/main.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';

void main() {
  Future<void> launchToHome(
      WidgetTester tester, ThemeModeController controller) async {
    await tester.pumpWidget(DanbRhsPrepApp(themeModeController: controller));
    // Flush the splash screen's navigation timer to reach the main shell.
    await tester.pump(const Duration(seconds: 2));
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

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(controller.value, ThemeMode.dark);
    expect(Theme.of(tester.element(find.text('Settings'))).brightness,
        Brightness.dark);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(controller.value, ThemeMode.light);
    expect(Theme.of(tester.element(find.text('Settings'))).brightness,
        Brightness.light);

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
    final SegmentedButton<ThemeMode> segmented =
        tester.widget(find.byType(SegmentedButton<ThemeMode>));
    expect(segmented.selected, {ThemeMode.dark});
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
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    // Rebuilding MainShell (e.g. switching tabs) must not touch the
    // application-level controller.
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();

    expect(controller.value, ThemeMode.dark);
  });
}
