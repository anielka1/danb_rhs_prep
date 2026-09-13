import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/main.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_bottom_navigation.dart';
import 'package:danb_rhs_prep/widgets/primary_button.dart';

void main() {
  group('app boot', () {
    testWidgets(
        'boots and shows the splash screen under a light platform brightness',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(platformBrightness: Brightness.light),
          child: DanbRhsPrepApp(),
        ),
      );

      expect(find.text('DANB RHS Prep'), findsOneWidget);
      final BuildContext context = tester.element(find.text('DANB RHS Prep'));
      expect(Theme.of(context).brightness, Brightness.light);
    });

    testWidgets(
        'boots and shows the splash screen under a dark platform brightness',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(platformBrightness: Brightness.dark),
          child: DanbRhsPrepApp(),
        ),
      );

      expect(find.text('DANB RHS Prep'), findsOneWidget);
      final BuildContext context = tester.element(find.text('DANB RHS Prep'));
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  });

  group('representative themed widgets', () {
    Widget wrap(Widget child, {required ThemeData theme}) {
      return MaterialApp(
          theme: theme, home: Scaffold(body: Center(child: child)));
    }

    testWidgets('PrimaryButton label uses onPrimary in both themes',
        (tester) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
          wrap(PrimaryButton(label: 'Start Practice Exam', onPressed: () {}),
              theme: theme),
        );
        // MaterialApp animates theme changes via AnimatedTheme; let the
        // transition finish before asserting resolved colors.
        await tester.pumpAndSettle();

        final Text text = tester.widget(find.text('Start Practice Exam'));
        expect(text.style?.color, theme.colorScheme.onPrimary);
      }
    });

    testWidgets('CircleIconButton defaults to the surfaceContainer role',
        (tester) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
          wrap(CircleIconButton(icon: Icons.close_rounded, onPressed: () {}),
              theme: theme),
        );
        await tester.pumpAndSettle();

        final Material material = tester.widget(
          find.descendant(
              of: find.byType(CircleIconButton),
              matching: find.byType(Material)),
        );
        expect(material.color, theme.colorScheme.surfaceContainer);
      }
    });

    testWidgets(
        'AppBottomNavigation selected item uses onSurface, unselected uses mutedForeground',
        (tester) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
                bottomNavigationBar: AppBottomNavigation(current: AppTab.home)),
          ),
        );
        await tester.pumpAndSettle();

        final semantic = theme.extension<AppSemanticColors>()!;
        final Icon homeIcon = tester.widget(find.byIcon(Icons.home_rounded));
        final Icon practiceIcon =
            tester.widget(find.byIcon(Icons.bar_chart_rounded));

        expect(homeIcon.color, theme.colorScheme.onSurface);
        expect(practiceIcon.color, semantic.mutedForeground);
      }
    });
  });

  group('tap targets', () {
    testWidgets('CircleIconButton meets the 44x44 minimum interactive size',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
                child: CircleIconButton(
                    icon: Icons.close_rounded, onPressed: () {})),
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(CircleIconButton));
      expect(size.width, greaterThanOrEqualTo(AppTapTarget.minInteractive));
      expect(size.height, greaterThanOrEqualTo(AppTapTarget.minInteractive));
    });

    testWidgets(
        'AppBottomNavigation items each meet the 44x44 minimum interactive size',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
              bottomNavigationBar: AppBottomNavigation(current: AppTab.home)),
        ),
      );

      final inkWells = find.descendant(
          of: find.byType(AppBottomNavigation), matching: find.byType(InkWell));
      expect(inkWells, findsNWidgets(2));
      for (final element in inkWells.evaluate()) {
        final Size size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(AppTapTarget.minInteractive));
        expect(size.height, greaterThanOrEqualTo(AppTapTarget.minInteractive));
      }
    });

    testWidgets('PrimaryButton meets the 44pt minimum height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
              body: PrimaryButton(label: 'Get Started', onPressed: () {})),
        ),
      );

      final Size size = tester.getSize(find.byType(PrimaryButton));
      expect(size.height, greaterThanOrEqualTo(AppTapTarget.minInteractive));
    });
  });
}
