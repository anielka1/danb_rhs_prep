import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/progress_bar.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Scaffold(body: Center(child: child)));
  }

  testWidgets('renders under light and dark themes', (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester
          .pumpWidget(wrap(const ProgressBar(value: 0.5), theme: theme));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    }
  });

  testWidgets('passes the given value through to LinearProgressIndicator',
      (tester) async {
    await tester.pumpWidget(wrap(const ProgressBar(value: 0.42)));
    final LinearProgressIndicator indicator =
        tester.widget(find.byType(LinearProgressIndicator));
    expect(indicator.value, 0.42);
  });

  testWidgets('clamps a value above 1 rather than throwing', (tester) async {
    await tester.pumpWidget(wrap(const ProgressBar(value: 1.5)));
    final LinearProgressIndicator indicator =
        tester.widget(find.byType(LinearProgressIndicator));
    expect(indicator.value, 1.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clamps a negative value rather than throwing', (tester) async {
    await tester.pumpWidget(wrap(const ProgressBar(value: -0.3)));
    final LinearProgressIndicator indicator =
        tester.widget(find.byType(LinearProgressIndicator));
    expect(indicator.value, 0.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes accessible progress semantics', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
        wrap(const ProgressBar(value: 0.75, semanticLabel: 'Weekly goal')));
    expect(
      tester.getSemantics(find.byType(ProgressBar)),
      matchesSemantics(label: 'Weekly goal', value: '75 percent'),
    );
    handle.dispose();
  });
}
