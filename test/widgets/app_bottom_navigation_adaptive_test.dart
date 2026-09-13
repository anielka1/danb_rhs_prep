import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_bottom_navigation.dart';

import '../support/dynamic_type_probe.dart';

/// `AppBottomNavigation` renders as a plain two-equal-column `Row` (its
/// classic design) whenever every label fits that way at the real,
/// requested text scale — true at every normal reading size on every
/// phone width this app targets, once measured against the label's real
/// font (see `test/flutter_test_config.dart`) rather than
/// `flutter test`'s synthetic fallback font, which made "Practice" and
/// "Progress" look far wider than they really are. Only once a label's
/// widest single word genuinely doesn't fit — only possible at extreme
/// accessibility text scales — does it fall back to a horizontally
/// scrollable row, keeping every label at full, un-shrunk size and
/// automatically scrolling the selected tab into view.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    required ProbeViewport viewport,
    double textScale = 1.0,
    bool disableAnimations = false,
  }) async {
    final double dpr = tester.view.devicePixelRatio;
    tester.view.physicalSize =
        Size(viewport.size.width * dpr, viewport.size.height * dpr);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: MaterialApp(theme: AppTheme.lightTheme, home: home),
      ),
    );
  }

  Widget shellWith({required AppTab current, ValueChanged<AppTab>? onTap}) {
    return Scaffold(
      body: const SizedBox.expand(),
      bottomNavigationBar: AppBottomNavigation(current: current, onTap: onTap),
    );
  }

  Finder scrollableFallbackFinder() => find.descendant(
      of: find.byType(AppBottomNavigation),
      matching: find.byType(SingleChildScrollView));

  // ---------------------------------------------------------------------
  // 1. Normal size: both required widths, no scrolling.
  // ---------------------------------------------------------------------
  group('at 1.0x, no horizontal scrolling is required', () {
    const labels = ['Home', 'Progress'];
    const viewports = [
      ProbeViewport.exitCriteriaSmallPhone, // 320
      ProbeViewport.smallPhone, // 375
      ProbeViewport.exitCriteriaLargePhone, // 430
      ProbeViewport.exitCriteriaIpad, // iPad
    ];

    for (final viewport in viewports) {
      testWidgets('$viewport: both labels visible, no scrolling',
          (tester) async {
        await pump(tester, shellWith(current: AppTab.home), viewport: viewport);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        for (final label in labels) {
          expect(find.text(label), findsOneWidget,
              reason: '"$label" must be visible at $viewport');
        }

        // "No horizontal scrolling is required" — the scrollable
        // fallback isn't even built at this size.
        expect(scrollableFallbackFinder(), findsNothing,
            reason: 'the scrollable fallback must be absent at $viewport, '
                '1.0x — the plain four-column row must be used instead');

        final Finder inkWells = find.descendant(
            of: find.byType(AppBottomNavigation),
            matching: find.byType(InkWell));
        expect(inkWells, findsNWidgets(2));
        for (final element in inkWells.evaluate()) {
          final Size size = tester.getSize(find.byWidget(element.widget));
          expect(size.width, greaterThanOrEqualTo(AppTapTarget.minInteractive),
              reason:
                  'every tab target must stay at least 44 wide at $viewport');
          expect(size.height, greaterThanOrEqualTo(AppTapTarget.minInteractive),
              reason:
                  'every tab target must stay at least 44 tall at $viewport');
        }

        // All four tabs are directly tappable — no ensureVisible/scroll
        // needed first, since there's nothing to scroll.
        for (final label in ['Progress', 'Home']) {
          await tester.tap(find.text(label), warnIfMissed: true);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  });

  // ---------------------------------------------------------------------
  // 2. Accessibility size: the fallback, and only the fallback, activates.
  // ---------------------------------------------------------------------
  group('at 4.0x on a 320x568 viewport', () {
    testWidgets(
        'the scrollable fallback activates, and no label is ellipsized, '
        'clipped, or painted smaller than its natural size', (tester) async {
      await pump(tester, shellWith(current: AppTab.home),
          viewport: ProbeViewport.exitCriteriaSmallPhone, textScale: 4.0);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The fallback is genuinely required at this scale (every label,
      // even the shortest, needs more than a quarter of 320px) — this
      // assertion is what proves it "activates only if required": it's
      // driven by the same real measurement as section 1 above, which
      // showed the opposite result (absent) at every 1.0x width.
      expect(scrollableFallbackFinder(), findsOneWidget);

      for (final label in ['Home', 'Progress']) {
        final Finder finder = find.text(label);
        expect(finder, findsOneWidget,
            reason: '"$label" must render as its exact, complete text — '
                'not truncated with an ellipsis');

        expect(find.ancestor(of: finder, matching: find.byType(FittedBox)),
            findsNothing,
            reason: 'a FittedBox would shrink "$label" after layout');

        final RenderParagraph paragraph =
            tester.renderObject<RenderParagraph>(finder);
        expect(paragraph.didExceedMaxLines, isFalse,
            reason: '"$label" silently needed more lines than its cap '
                'allows, which would have been hidden rather than shown');

        // The authoritative "not painted smaller" check: getSize is the
        // label's own natural, pre-transform layout size; getRect is
        // its real on-screen size. A FittedBox/Transform.scale ancestor
        // is the only thing that would make these differ.
        final Size naturalSize = tester.getSize(finder);
        final Size paintedSize = tester.getRect(finder).size;
        expect(paintedSize.height,
            moreOrLessEquals(naturalSize.height, epsilon: 0.5),
            reason: '"$label" painted smaller than its natural size');

        expect(
          MediaQuery.textScalerOf(tester.element(finder)),
          const TextScaler.linear(4.0),
          reason: '"$label" must receive the requested 4.0x text scaler, '
              'not a clamped or overridden one',
        );
      }
    });

    testWidgets('both tabs can be reached and selected', (tester) async {
      final List<AppTab> taps = [];
      await pump(
        tester,
        shellWith(current: AppTab.home, onTap: taps.add),
        viewport: ProbeViewport.exitCriteriaSmallPhone,
        textScale: 4.0,
      );
      await tester.pumpAndSettle();

      for (final label in ['Progress', 'Home']) {
        final Finder finder = find.text(label);
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      expect(taps, [AppTab.progress, AppTab.home]);
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------
  // 3. Initial selection off-screen: automatically revealed.
  // ---------------------------------------------------------------------
  group('Progress initially selected at 4.0x', () {
    testWidgets('is automatically brought into view after the first frame',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, shellWith(current: AppTab.progress),
          viewport: ProbeViewport.exitCriteriaSmallPhone, textScale: 4.0);
      // One pump for the first frame to build and lay out, then let the
      // scheduled post-frame reveal (and its scroll animation) finish.
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final Rect viewport = tester.getRect(find.byType(AppBottomNavigation));
      final Rect progressRect = tester.getRect(find.text('Progress'));
      expect(
        viewport.left <= progressRect.left &&
            progressRect.right <= viewport.right,
        isTrue,
        reason: 'Progress must be fully within the visible bar after the '
            'first frame, not scrolled out of view',
      );

      expect(
        tester.getSemantics(find.descendant(
            of: find.byType(AppBottomNavigation),
            matching: find.bySemanticsLabel('Progress'))),
        matchesSemantics(
            label: 'Progress',
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true),
      );

      handle.dispose();
    });
  });

  // ---------------------------------------------------------------------
  // 4. Programmatic change to an off-screen tab.
  // ---------------------------------------------------------------------
  group('changing selection programmatically to an off-screen tab', () {
    testWidgets(
        'brings the newly-selected tab into view without erroring or '
        'leaving pending post-frame work', (tester) async {
      AppTab current = AppTab.home;
      late StateSetter setState;

      await pump(
        tester,
        StatefulBuilder(builder: (context, setter) {
          setState = setter;
          return shellWith(current: current);
        }),
        viewport: ProbeViewport.exitCriteriaSmallPhone,
        textScale: 4.0,
      );
      await tester.pumpAndSettle();

      // Home is the first (leftmost) item, so it's already visible
      // without needing to scroll — Progress, the last item, is not.
      setState(() => current = AppTab.progress);
      await tester.pump(); // triggers didUpdateWidget's post-frame reveal
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final Rect viewport = tester.getRect(find.byType(AppBottomNavigation));
      final Rect progressRect = tester.getRect(find.text('Progress'));
      expect(
        viewport.left <= progressRect.left &&
            progressRect.right <= viewport.right,
        isTrue,
        reason: 'Progress must be scrolled into view after the '
            'programmatic change',
      );

      // Disposing immediately after triggering another change, before
      // anything has a chance to settle, exercises the exact race a
      // stray post-frame callback touching a disposed State would hit —
      // this must not throw.
      setState(() => current = AppTab.progress);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------
  // 5. Reduce Motion.
  // ---------------------------------------------------------------------
  group('Reduce Motion', () {
    testWidgets(
        'automatic reveal still works, but scrolls immediately rather '
        'than animating', (tester) async {
      await pump(
        tester,
        shellWith(current: AppTab.progress),
        viewport: ProbeViewport.exitCriteriaSmallPhone,
        textScale: 4.0,
        disableAnimations: true,
      );

      // A single pump completes the first frame, runs the scheduled
      // post-frame reveal, and — because Reduce Motion makes that reveal
      // an immediate `jumpTo` rather than an `animateTo` — leaves
      // Progress already fully visible without needing further pumps to
      // let an animation finish.
      await tester.pump();
      expect(tester.takeException(), isNull);

      final Rect viewport = tester.getRect(find.byType(AppBottomNavigation));
      final Rect progressRect = tester.getRect(find.text('Progress'));
      expect(
        viewport.left <= progressRect.left &&
            progressRect.right <= viewport.right,
        isTrue,
        reason: 'Progress must already be fully visible after a single '
            'pump under Reduce Motion — an animated reveal would still '
            'be mid-flight at this point',
      );
    });
  });
}
