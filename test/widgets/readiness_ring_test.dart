import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/readiness_ring.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Scaffold(body: Center(child: child)));
  }

  testWidgets('renders the rounded percentage under light and dark themes',
      (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(wrap(ReadinessRing(score: 72), theme: theme));
      expect(find.text('72%'), findsOneWidget);
    }
  });

  testWidgets(
      'renders a placeholder and different semantics when evidence is insufficient',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(ReadinessRing(score: 0, hasEvidence: false)));
    expect(find.text('72%'), findsNothing);
    expect(find.text('--'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(ReadinessRing)),
      matchesSemantics(label: 'Readiness score', value: 'Not enough data yet'),
    );
    handle.dispose();
  });

  testWidgets('exposes an accessible percentage value', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(ReadinessRing(score: 45)));
    expect(
      tester.getSemantics(find.byType(ReadinessRing)),
      matchesSemantics(label: 'Readiness score', value: '45 percent'),
    );
    handle.dispose();
  });

  testWidgets('renders the requested size variant', (tester) async {
    await tester.pumpWidget(
        wrap(ReadinessRing(score: 50, size: ReadinessRingSize.large)));
    final Size size = tester.getSize(find.byType(ReadinessRing));
    expect(size.width, 140);
    expect(size.height, 140);
  });

  test(
      'throws ArgumentError for a score outside 0-100 (validated in release builds)',
      () {
    expect(() => ReadinessRing(score: 101), throwsArgumentError);
    expect(() => ReadinessRing(score: -1), throwsArgumentError);
  });

  testWidgets('scales with large text without throwing', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
        child: wrap(ReadinessRing(score: 80)),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
