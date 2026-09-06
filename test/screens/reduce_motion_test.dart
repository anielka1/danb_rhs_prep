import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

// HomeScreen's Scaffold has a FloatingActionButton, and Scaffold uses its
// own internal AnimatedContainer for FAB positioning — find.byType(...)
// .first would find that one, not the day strip's. Anchor off the
// selected (today's, by default) day's number instead — computed at
// test-run time, not hardcoded, since HomeScreen shows the real current
// week and this would otherwise silently stop matching once the actual
// date moves past whatever day was hardcoded.
Finder _dayStripAnimatedContainer() =>
    find.widgetWithText(AnimatedContainer, '${DateTime.now().day}');

void main() {
  Widget wrap(Widget child, {bool disableAnimations = false}) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: MaterialApp(theme: AppTheme.lightTheme, home: child),
    );
  }

  group('Home day-strip selection', () {
    testWidgets('animation duration is zero when Reduce Motion is on',
        (tester) async {
      await tester
          .pumpWidget(wrap(const HomeScreen(), disableAnimations: true));
      final AnimatedContainer container =
          tester.widget<AnimatedContainer>(_dayStripAnimatedContainer());
      expect(container.duration, Duration.zero);
    });

    testWidgets(
        'animation duration is the normal length when Reduce Motion is off',
        (tester) async {
      await tester.pumpWidget(wrap(const HomeScreen()));
      final AnimatedContainer container =
          tester.widget<AnimatedContainer>(_dayStripAnimatedContainer());
      expect(container.duration, isNot(Duration.zero));
    });

    testWidgets(
        'selecting a day still updates state and needs no pending timer with Reduce Motion on',
        (tester) async {
      await tester
          .pumpWidget(wrap(const HomeScreen(), disableAnimations: true));

      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.tap(find.bySemanticsLabel(RegExp('Wed')));
      // A single, zero-duration pump is enough: with the animation
      // duration forced to zero, the new selection is already the final
      // (not mid-transition) state, and there is nothing left pending.
      await tester.pump();

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Wed'))),
        matchesSemantics(
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true),
      );
      handle.dispose();
    });
  });
}
