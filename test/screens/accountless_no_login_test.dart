import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

/// Reproduces and guards the "[REWORK] Usun Login i Sign Out z accountless
/// flow" defect: this app has no working authentication (no account
/// backend exists — LoginScreen's own "Get Started" button just enters
/// MainShell regardless of what was typed), yet ProfileSettingsScreen
/// showed both "Guest" / "Not signed in" *and* a live, enabled "Sign Out"
/// button that pushed the user into that non-functional LoginScreen via
/// `Navigator.pushNamedAndRemoveUntil`. There was never a session to sign
/// out of, and the screen it led to couldn't sign the guest back in
/// either — a real, reachable dead end for every accountless-flow user.
///
/// This differs from `test/main_test.dart`'s "Login never appears" group,
/// which only covers the splash/bootstrap routing path (splash ->
/// welcome/MainShell) — it never pumps ProfileSettingsScreen, so it did
/// not catch this.
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

  test('LoginScreen is not registered as a navigable production route', () {
    final String main = File('lib/main.dart').readAsStringSync();

    expect(
      main,
      isNot(contains('LoginScreen.route:')),
      reason: 'LoginScreen must not be reachable from production '
          'navigation in the accountless flow. The widget itself may stay '
          'in the codebase for future real auth work, but registering it '
          'as a named route is exactly the production entry point this '
          'task removes — nothing else in the app currently constructs a '
          'LoginScreen instance directly.',
    );
    expect(
      main,
      isNot(contains("import 'screens/login_screen.dart';")),
      reason: 'main.dart should not import LoginScreen once it no longer '
          'registers or otherwise references it — an unused import would '
          'also fail flutter analyze.',
    );
  });
}
