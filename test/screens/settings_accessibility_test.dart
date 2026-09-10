import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/screens/study_help_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 4.0]) {
      testWidgets('settings and help remain usable dark=$dark scale=$scale',
          (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final controller = ThemeModeController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: ProfileSettingsScreen(
            themeModeController: controller,
            onResetProgress: () async {},
          ),
        ));
        Future<void> tap(String text) async {
          await tester.ensureVisible(find.text(text));
          await tester.pumpAndSettle();
          await tester.tap(find.text(text));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        for (final entry in {
          'Dark': ThemeMode.dark,
          'Light': ThemeMode.light,
          'System': ThemeMode.system
        }.entries) {
          await tap(entry.key);
          expect(controller.value, entry.value);
        }
        await tap('Study help');
        expect(find.byType(StudyHelpScreen), findsOneWidget);
        for (final entry in StudyHelpScreen.topics.entries) {
          await tap(entry.key);
          expect(find.text(entry.value), findsOneWidget);
          await tester.ensureVisible(find.text(entry.value));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.ensureVisible(find.bySemanticsLabel('Back').last);
        await tester.tap(find.bySemanticsLabel('Back').last);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileSettingsScreen), findsOneWidget);
        await tap('Your data');
        expect(find.textContaining('No account is needed.'), findsOneWidget);
        await tap('About RHS Prep');
        expect(
            find.textContaining('An independent study tool'), findsOneWidget);
        await tap('Reset study progress');
        await tap('Keep my progress');
        expect(find.text('Reset study progress?'), findsNothing);
      });
    }
  }
}
