import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

void main() {
  for (final reduced in [true, false]) {
    testWidgets('motion helper respects system preference: $reduced',
        (tester) async {
      Duration? actual;
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Builder(builder: (context) {
          actual =
              context.reducedMotionDuration(const Duration(milliseconds: 150));
          return const SizedBox();
        }),
      )));
      expect(
          actual, reduced ? Duration.zero : const Duration(milliseconds: 150));
    });
  }
}
