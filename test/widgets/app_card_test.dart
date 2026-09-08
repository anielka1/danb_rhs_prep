import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_card.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Scaffold(body: Center(child: child)));
  }

  testWidgets('renders its child under light and dark themes', (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
          wrap(const AppCard(child: Text('Card content')), theme: theme));
      expect(find.text('Card content'), findsOneWidget);
    }
  });

  testWidgets('uses surfaceContainer by default', (tester) async {
    await tester.pumpWidget(wrap(const AppCard(child: Text('x'))));
    final Material material = tester.widget(
      find.descendant(
          of: find.byType(AppCard), matching: find.byType(Material)),
    );
    expect(material.color, AppTheme.lightTheme.colorScheme.surfaceContainer);
  });

  testWidgets('accepts a background color override for accent cards',
      (tester) async {
    await tester.pumpWidget(
      wrap(AppCard(
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          child: const Text('x'))),
    );
    final Material material = tester.widget(
      find.descendant(
          of: find.byType(AppCard), matching: find.byType(Material)),
    );
    expect(material.color, AppTheme.lightTheme.colorScheme.primary);
  });

  testWidgets('tap callback fires exactly once per tap', (tester) async {
    int taps = 0;
    await tester
        .pumpWidget(wrap(AppCard(onTap: () => taps++, child: const Text('x'))));
    await tester.tap(find.byType(AppCard));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('exposes button semantics only when tappable', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(AppCard(
          onTap: () {},
          semanticLabel: 'Tappable card',
          child: const Text('x'))),
    );
    expect(
      tester.getSemantics(find.byType(AppCard)),
      matchesSemantics(
          label: 'Tappable card',
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true),
    );

    await tester.pumpWidget(
        wrap(const AppCard(semanticLabel: 'Static card', child: Text('x'))));
    expect(
      tester.getSemantics(find.byType(AppCard)),
      matchesSemantics(label: 'Static card', isButton: false),
    );

    handle.dispose();
  });

  testWidgets('a plain AppCard exposes no selected-state semantics at all',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(
          const AppCard(semanticLabel: 'Informational card', child: Text('x'))),
    );
    expect(
      tester.getSemantics(find.byType(AppCard)),
      matchesSemantics(label: 'Informational card', hasSelectedState: false),
    );

    handle.dispose();
  });

  testWidgets(
      'a tappable ordinary card exposes button/tap semantics without selection semantics',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(AppCard(
          onTap: () {}, semanticLabel: 'Task card', child: const Text('x'))),
    );
    expect(
      tester.getSemantics(find.byType(AppCard)),
      matchesSemantics(
          label: 'Task card',
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          hasSelectedState: false,
          isSelected: false),
    );

    handle.dispose();
  });

  testWidgets('AppCard(selected: false) reports an unselected state',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(AppCard(
          selected: false,
          onTap: () {},
          semanticLabel: 'Unchosen plan',
          child: const Text('x'))),
    );
    expect(
      tester.getSemantics(find.byType(AppCard)),
      matchesSemantics(
          label: 'Unchosen plan',
          isButton: true,
          isSelected: false,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true),
    );

    handle.dispose();
  });

  testWidgets('AppCard(selected: true) reports a selected state',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(AppCard(
          selected: true,
          onTap: () {},
          semanticLabel: 'Chosen plan',
          child: const Text('x'))),
    );
    expect(
      tester.getSemantics(find.byType(AppCard)),
      matchesSemantics(
          label: 'Chosen plan',
          isButton: true,
          isSelected: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          hasSelectedState: true),
    );

    handle.dispose();
  });

  testWidgets(
      'the emphasized border only appears when selected is exactly true',
      (tester) async {
    Border? borderOf(WidgetTester t) {
      final DecoratedBox? box = t
          .widgetList<DecoratedBox>(
            find.descendant(
                of: find.byType(AppCard), matching: find.byType(DecoratedBox)),
          )
          .firstOrNull;
      return box?.decoration is BoxDecoration
          ? (box!.decoration as BoxDecoration).border as Border?
          : null;
    }

    await tester.pumpWidget(wrap(const AppCard(child: Text('x'))));
    expect(borderOf(tester)?.top.color,
        AppTheme.lightTheme.colorScheme.outlineVariant);

    await tester
        .pumpWidget(wrap(const AppCard(selected: false, child: Text('x'))));
    expect(borderOf(tester)?.top.color,
        AppTheme.lightTheme.colorScheme.outlineVariant);

    await tester
        .pumpWidget(wrap(const AppCard(selected: true, child: Text('x'))));
    expect(borderOf(tester), isNotNull);
  });
}
