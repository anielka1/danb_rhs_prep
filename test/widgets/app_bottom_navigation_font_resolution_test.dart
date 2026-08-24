import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_bottom_navigation.dart';

/// `AppBottomNavigation` must resolve its label style from the ambient
/// theme/platform typography (`DefaultTextStyle.of(context).style`,
/// merged with only size/weight/color overrides — exactly what `Text`
/// does internally), never from a hardcoded font family. This file
/// proves that at the source level (no hardcoded `fontFamily: 'Roboto'`
/// survives in production code), at the resolved-style level (the
/// rendered label's style matches an independently-recomputed "merge
/// onto DefaultTextStyle" expectation, so a future regression that
/// reintroduces a hardcoded override or bypasses the merge would show up
/// as a mismatch here), and at the layout-decision level (the fixed vs.
/// scrollable choice does not depend on which tab happens to be
/// selected).
void main() {
  group('production source', () {
    test('contains no hardcoded fontFamily: \'Roboto\'', () {
      final String source =
          File('lib/widgets/app_bottom_navigation.dart').readAsStringSync();
      expect(source.contains("fontFamily: 'Roboto'"), isFalse,
          reason: 'the label style must resolve from the ambient theme, '
              'never a hardcoded production font family — the Roboto '
              'files under test/fonts/ are test-only infrastructure');
      // Checking for actual instantiations, not the bare words — this
      // file's own doc comments legitimately *mention* FittedBox and
      // Transform.scale by name when explaining that they're not used.
      expect(source.contains('FittedBox('), isFalse);
      expect(source.contains('Transform.scale('), isFalse);
      expect(source.contains('TextOverflow.ellipsis'), isFalse);
    });
  });

  group('measurement and rendering use the same resolved style', () {
    Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.lightTheme, home: Scaffold(bottomNavigationBar: child));

    /// Independently recomputes what the rendered label's style *should*
    /// be — the same "merge this widget's overrides onto
    /// DefaultTextStyle.of(context).style" resolution `Text` performs
    /// internally — from the test's own vantage point, without calling
    /// into any of the widget's private implementation. If the
    /// production code ever stopped doing this same merge (e.g.
    /// reintroduced a hardcoded fontFamily, or used some other
    /// unrelated style), the actual rendered style below would no
    /// longer match this.
    TextStyle expectedStyle(BuildContext context, {required bool selected}) {
      final Color color = selected
          ? context.colors.onSurface
          : context.semanticColors.mutedForeground;
      return DefaultTextStyle.of(context).style.merge(TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ));
    }

    testWidgets('the rendered label style matches the theme-merged expectation',
        (tester) async {
      await tester.pumpWidget(
          wrap(const AppBottomNavigation(current: AppTab.practice)));
      await tester.pumpAndSettle();

      for (final entry in {'Home': false, 'Practice': true}.entries) {
        final Text widget = tester.widget<Text>(find.text(entry.key));
        final TextStyle? actual = widget.style;
        final TextStyle expected = expectedStyle(
            tester.element(find.text(entry.key)),
            selected: entry.value);

        expect(actual, isNotNull);
        expect(actual!.fontFamily, expected.fontFamily,
            reason: '"${entry.key}" font family must come from the theme');
        expect(actual.fontFamilyFallback, expected.fontFamilyFallback);
        expect(actual.fontSize, expected.fontSize);
        expect(actual.fontWeight, expected.fontWeight);
        expect(actual.letterSpacing, expected.letterSpacing);
        expect(actual.height, expected.height);
      }
    });

    testWidgets(
        'selected and unselected labels resolve from the same theme, '
        'differing only in weight and color', (tester) async {
      await tester
          .pumpWidget(wrap(const AppBottomNavigation(current: AppTab.home)));
      await tester.pumpAndSettle();

      final TextStyle selectedStyle =
          tester.widget<Text>(find.text('Home')).style!;
      final TextStyle unselectedStyle =
          tester.widget<Text>(find.text('Practice')).style!;

      expect(selectedStyle.fontFamily, unselectedStyle.fontFamily);
      expect(
          selectedStyle.fontFamilyFallback, unselectedStyle.fontFamilyFallback);
      expect(selectedStyle.fontSize, unselectedStyle.fontSize);
      expect(selectedStyle.fontWeight, FontWeight.w700);
      expect(unselectedStyle.fontWeight, FontWeight.w500);
    });
  });

  group('the layout decision is stable across tab selection', () {
    Future<bool> isScrollableWith(
        WidgetTester tester, AppTab current, double textScale) async {
      final double dpr = tester.view.devicePixelRatio;
      tester.view.physicalSize = Size(320 * dpr, 568 * dpr);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
                bottomNavigationBar: AppBottomNavigation(current: current)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return find
          .descendant(
              of: find.byType(AppBottomNavigation),
              matching: find.byType(SingleChildScrollView))
          .evaluate()
          .isNotEmpty;
    }

    // 2.0x on a 320px phone is close to this bar's real fit/no-fit
    // boundary (unlike a comfortably-fits 1.0x or a nowhere-close-4.0x),
    // so if the fit decision were (incorrectly) based on only the
    // currently-selected tab's weight instead of the true worst case
    // across all four, this scale is where selecting a different tab
    // would be most likely to flip it.
    const double borderlineScale = 2.0;

    testWidgets(
        'the fixed-vs-scrollable choice is identical for every possible '
        'selected tab at the same size', (tester) async {
      final Map<AppTab, bool> results = {};
      for (final tab in AppTab.values) {
        results[tab] = await isScrollableWith(tester, tab, borderlineScale);
      }

      expect(results.values.toSet().length, 1,
          reason: 'the layout must not switch between fixed and scrollable '
              'merely because a different tab became selected: $results');
    });
  });
}
