import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_bottom_navigation.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Scaffold(bottomNavigationBar: child));
  }

  testWidgets('renders all four tabs under light and dark themes',
      (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
          wrap(const AppBottomNavigation(current: AppTab.home), theme: theme));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    }
  });

  testWidgets('selected tab uses onSurface, others use mutedForeground',
      (tester) async {
    await tester
        .pumpWidget(wrap(const AppBottomNavigation(current: AppTab.practice)));
    final scheme = AppTheme.lightTheme.colorScheme;
    final semantic = AppTheme.lightTheme.extension<AppSemanticColors>()!;

    final Icon practiceIcon =
        tester.widget(find.byIcon(Icons.menu_book_rounded));
    final Icon homeIcon = tester.widget(find.byIcon(Icons.home_rounded));
    expect(practiceIcon.color, scheme.onSurface);
    expect(homeIcon.color, semantic.mutedForeground);
  });

  testWidgets('tapping a tab invokes onTap with the tapped AppTab exactly once',
      (tester) async {
    final List<AppTab> taps = [];
    await tester.pumpWidget(
      wrap(AppBottomNavigation(current: AppTab.home, onTap: taps.add)),
    );

    await tester.tap(find.text('Profile'));
    await tester.pump();

    expect(taps, [AppTab.profile]);
  });

  testWidgets('each tab meets the 44x44 minimum interactive size',
      (tester) async {
    await tester
        .pumpWidget(wrap(const AppBottomNavigation(current: AppTab.home)));
    final inkWells = find.descendant(
      of: find.byType(AppBottomNavigation),
      matching: find.byType(InkWell),
    );
    expect(inkWells, findsNWidgets(4));
    for (final element in inkWells.evaluate()) {
      final Size size = tester.getSize(find.byWidget(element.widget));
      expect(size.width, greaterThanOrEqualTo(AppTapTarget.minInteractive));
      expect(size.height, greaterThanOrEqualTo(AppTapTarget.minInteractive));
    }
  });

  testWidgets('exposes selected-tab semantics', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester
        .pumpWidget(wrap(const AppBottomNavigation(current: AppTab.home)));

    expect(
      tester.getSemantics(find.text('Home')),
      matchesSemantics(
          label: 'Home',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true),
    );
    expect(
      tester.getSemantics(find.text('Practice')),
      matchesSemantics(
          label: 'Practice',
          isButton: true,
          isSelected: false,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true),
    );

    handle.dispose();
  });
}
