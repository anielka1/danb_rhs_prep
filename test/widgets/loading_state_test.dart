import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/loading_state.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
        theme: theme ?? AppTheme.lightTheme, home: Scaffold(body: child));
  }

  testWidgets('renders a progress indicator under light and dark themes',
      (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(wrap(const LoadingState(), theme: theme));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    }
  });

  testWidgets('shows the optional message', (tester) async {
    await tester.pumpWidget(
        wrap(const LoadingState(message: 'Loading your progress…')));
    expect(find.text('Loading your progress…'), findsOneWidget);
  });

  testWidgets('announces as an accessible live region', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
        wrap(const LoadingState(message: 'Loading your progress…')));
    expect(
      tester.getSemantics(find.byType(CircularProgressIndicator)),
      matchesSemantics(label: 'Loading your progress…', isLiveRegion: true),
    );
    handle.dispose();
  });

  testWidgets('defaults to a generic "Loading" label with no message',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const LoadingState()));
    expect(
      tester.getSemantics(find.byType(CircularProgressIndicator)),
      matchesSemantics(label: 'Loading', isLiveRegion: true),
    );
    handle.dispose();
  });
}
