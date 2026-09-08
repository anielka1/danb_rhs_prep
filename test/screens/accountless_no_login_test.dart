import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

/// Reproduces and guards the "[REWORK] Usun Login i Sign Out z accountless
/// flow" defect (PREP-645) and its PREP-652 follow-up: this app has no
/// working authentication, so PREP-645 removed LoginScreen's production
/// route and ProfileSettingsScreen's "Sign Out" button, but left
/// `lib/screens/login_screen.dart` itself in the tree, reachable by
/// nothing in the running app yet still carrying three of its own
/// no-op-shaped disabled controls (Forgot Password, Google and Apple
/// sign-in). PREP-652's interaction-control audit
/// (docs/INTERACTION_CONTROL_AUDIT.md) found these as the only remaining
/// no-op-shaped controls anywhere in the codebase, precisely because the
/// screen containing them could never be reached at all — so this test
/// now verifies the file itself, and every reference to it, are gone,
/// not merely that production doesn't route to it.
void main() {
  testWidgets(
      'ProfileSettingsScreen does not show a Sign Out control for the '
      'accountless guest', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: ProfileSettingsScreen(themeModeController: ThemeModeController()),
    ));

    // There is nothing for a guest who was never signed in to sign out
    // of, and the screen this used to lead to doesn't work either — the
    // control must not exist at all, not merely be disabled.
    expect(find.text('Sign Out'), findsNothing);
  });

  testWidgets(
      'ProfileSettingsScreen shows no account-management actions for the '
      'accountless guest (PREP-459)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: ProfileSettingsScreen(themeModeController: ThemeModeController()),
    ));

    // This app is accountless in V1, with no plan to add sign-in — a
    // guest who is explicitly told "Not signed in" must never also see
    // an "ACCOUNT" section suggesting an account exists to manage.
    // PREP-652 kept these two rows as *disabled* (reachable, but the
    // feature behind them doesn't exist yet), on the premise that a
    // real auth phase might still arrive. PREP-459 deliberately reverses
    // that call: since there's no auth phase in this product's plan at
    // all, "disabled and waiting" is dishonest — it advertises a
    // capability that will never exist, not a merely-not-yet-built one.
    expect(find.text('ACCOUNT'), findsNothing);
    expect(find.text('Edit Profile'), findsNothing);
    expect(find.text('Change Password'), findsNothing);
  });

  test('LoginScreen no longer exists anywhere in the codebase', () {
    expect(
      File('lib/screens/login_screen.dart').existsSync(),
      isFalse,
      reason: 'LoginScreen was permanently unreachable (see PREP-645): no '
          'production route registered it, and nothing else constructed '
          'it directly. PREP-652 removed the file itself, along with the '
          'three no-op-shaped disabled controls it still carried (Forgot '
          'Password, Google sign-in, Apple sign-in) — the last remaining '
          'no-op-shaped controls found anywhere in the app by the '
          'PREP-652 interaction-control audit.',
    );

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final String source = entity.readAsStringSync();
      expect(
        source.contains('login_screen.dart'),
        isFalse,
        reason: '${entity.path} still imports/exports login_screen.dart.',
      );
      expect(
        source.contains('LoginScreen'),
        isFalse,
        reason: '${entity.path} still references the LoginScreen class.',
      );
    }
  });
}
