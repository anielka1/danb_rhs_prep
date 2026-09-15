import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/screens/subscription_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/links/external_link_launcher.dart';

class RecordingLauncher implements ExternalLinkLauncher {
  final calls = <Uri>[];
  @override
  Future<bool> open(Uri uri) async {
    calls.add(uri);
    return true;
  }
}

void main() {
  testWidgets('settings legal pages reuse the existing destinations',
      (tester) async {
    final controller = ThemeModeController();
    addTearDown(controller.dispose);
    final launcher = RecordingLauncher();
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProfileSettingsScreen(
            themeModeController: controller, linkLauncher: launcher)));
    await tester.pumpAndSettle();
    for (final label in ['Privacy Policy', 'Terms of Use']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(launcher.calls.map((uri) => uri.toString()), [
      'https://prepnovo.org/privacy-policy/',
      'https://prepnovo.org/terms-of-use/',
    ]);
    expect(find.byType(ProfileSettingsScreen), findsOneWidget);
    expect(find.byType(SubscriptionScreen), findsNothing);
  });

  const fullText =
      'PrepNovo is not affiliated with, sponsored by, or endorsed by Dental Assisting National Board, Inc. DANB® and RHS® are registered trademarks of DANB.';
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final scale in [1.0, 3.2]) {
      testWidgets('offline notice without Premium: $platform scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = ThemeModeController();
        addTearDown(controller.dispose);
        final launcher = RecordingLauncher();
        await tester.pumpWidget(
          MaterialApp(
            theme: (scale == 1 ? AppTheme.lightTheme : AppTheme.darkTheme)
                .copyWith(platform: platform),
            builder: (_, child) => MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: ProfileSettingsScreen(
              themeModeController: controller,
              linkLauncher: launcher,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Legal Notice'));
        await tester.pumpAndSettle();
        expect(find.text('About & Legal'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('Privacy Policy')).dy,
          lessThan(tester.getTopLeft(find.text('Terms of Use')).dy),
        );
        expect(
          tester.getTopLeft(find.text('Terms of Use')).dy,
          lessThan(tester.getTopLeft(find.text('Legal Notice')).dy),
        );
        final semantics = tester.ensureSemantics();
        expect(find.bySemanticsLabel('Legal notice regarding DANB trademarks'),
            findsOneWidget);
        semantics.dispose();
        await tester.tap(find.text('Legal Notice'));
        await tester.pumpAndSettle();
        expect(find.text(fullText), findsOneWidget);
        expect(fullText, contains('DANB®'));
        expect(fullText, contains('RHS®'));
        expect(find.byType(SubscriptionScreen), findsNothing);
        expect(launcher.calls, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Close'));
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.text(fullText), findsNothing);
        expect(find.byType(ProfileSettingsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
