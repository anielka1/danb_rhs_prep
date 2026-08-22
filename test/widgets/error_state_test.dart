import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/error_state.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
        theme: theme ?? AppTheme.lightTheme, home: Scaffold(body: child));
  }

  testWidgets('renders title and message under light and dark themes',
      (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        wrap(
            const ErrorState(
                title: 'Something went wrong', message: 'Please try again.'),
            theme: theme),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Please try again.'), findsOneWidget);
    }
  });

  testWidgets('retry callback fires exactly once per tap', (tester) async {
    int taps = 0;
    await tester.pumpWidget(
      wrap(ErrorState(title: 'Something went wrong', onRetry: () => taps++)),
    );
    await tester.tap(find.text('Try Again'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('omits the retry action when no callback is given',
      (tester) async {
    await tester
        .pumpWidget(wrap(const ErrorState(title: 'Something went wrong')));
    expect(find.text('Try Again'), findsNothing);
  });

  testWidgets('supports a custom retry label', (tester) async {
    await tester.pumpWidget(
      wrap(ErrorState(
          title: 'Load failed', onRetry: () {}, retryLabel: 'Reload')),
    );
    expect(find.text('Reload'), findsOneWidget);
  });

  testWidgets('announces the error as an accessible live region',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(const ErrorState(
          title: 'Something went wrong', message: 'Please try again.')),
    );
    expect(
      tester.getSemantics(find.text('Something went wrong')),
      matchesSemantics(
          label: 'Something went wrong. Please try again.', isLiveRegion: true),
    );
    handle.dispose();
  });
}
