import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
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
  for (final preference in ThemePreference.values) {
    testWidgets(
        'persisted ${preference.name} restores shared Home colors on restart',
        (tester) async {
      final boot = readyAppBootstrap();
      Widget app() => DanbRhsPrepApp(
          bootstrapService: AppBootstrapService(
              contentRepository: const RealFileContentRepository(),
              localStore: boot.localStore),
          localStore: boot.localStore);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await openSettings(tester);
      await tester.ensureVisible(find.text('Dark'));
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      final label = switch (preference) {
        ThemePreference.system => 'System',
        ThemePreference.light => 'Light',
        ThemePreference.dark => 'Dark'
      };
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(await boot.localStore.readThemePreference(), preference);
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      void checkHome() {
        final context = tester.element(find.byType(HomeScreen));
        final theme = Theme.of(context);
        expect(
            theme.brightness,
            preference == ThemePreference.dark
                ? Brightness.dark
                : Brightness.light);
        final card = tester.widget<AppCard>(find.ancestor(
            of: find.text('Your progress'), matching: find.byType(AppCard)));
        expect(card.backgroundColor, theme.colorScheme.primaryContainer);
        expect(tester.widget<Text>(find.text('Your progress')).style!.color,
            theme.colorScheme.onPrimaryContainer);
        final scaffold = tester.widget<Scaffold>(find
            .descendant(
                of: find.byType(HomeScreen), matching: find.byType(Scaffold))
            .first);
        expect(scaffold.backgroundColor, theme.colorScheme.surface);
      }

      checkHome();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      checkHome();
      expect(tester.takeException(), isNull);
    });
  }
}
