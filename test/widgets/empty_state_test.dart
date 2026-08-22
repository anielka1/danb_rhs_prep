import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/empty_state.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
        theme: theme ?? AppTheme.lightTheme, home: Scaffold(body: child));
  }

  testWidgets('renders title under light and dark themes', (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
          wrap(const EmptyState(title: 'No bookmarks yet'), theme: theme));
      expect(find.text('No bookmarks yet'), findsOneWidget);
    }
  });

  testWidgets('shows the optional message and icon', (tester) async {
    await tester.pumpWidget(
      wrap(const EmptyState(
          title: 'No bookmarks yet',
          message: 'Bookmark a question to see it here.',
          icon: Icons.bookmark_outline)),
    );
    expect(find.text('Bookmark a question to see it here.'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
  });

  testWidgets('primary and secondary actions fire exactly once each',
      (tester) async {
    int primaryTaps = 0;
    int secondaryTaps = 0;
    await tester.pumpWidget(
      wrap(
        EmptyState(
          title: 'No bookmarks yet',
          primaryActionLabel: 'Start Practicing',
          onPrimaryAction: () => primaryTaps++,
          secondaryActionLabel: 'Browse Questions',
          onSecondaryAction: () => secondaryTaps++,
        ),
      ),
    );

    await tester.tap(find.text('Start Practicing'));
    await tester.pump();
    await tester.tap(find.text('Browse Questions'));
    await tester.pump();

    expect(primaryTaps, 1);
    expect(secondaryTaps, 1);
  });

  testWidgets('omits actions when not provided', (tester) async {
    await tester.pumpWidget(wrap(const EmptyState(title: 'No bookmarks yet')));
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
