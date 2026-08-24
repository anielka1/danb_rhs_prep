import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_scaffold.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(theme: theme ?? AppTheme.lightTheme, home: child);
  }

  testWidgets('renders the body under light and dark themes', (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
          wrap(const AppScaffold(body: Text('Body content')), theme: theme));
      expect(find.text('Body content'), findsOneWidget);
    }
  });

  testWidgets('uses the surface color as background', (tester) async {
    await tester.pumpWidget(wrap(const AppScaffold(body: Text('x'))));
    final Scaffold scaffold = tester.widget(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppTheme.lightTheme.colorScheme.surface);
  });

  testWidgets(
      'omits the header row entirely when no title/leading/actions are given',
      (tester) async {
    await tester.pumpWidget(wrap(const AppScaffold(body: Text('x'))));
    expect(find.text('x'), findsOneWidget);
    // No header means no extra Row above the body from AppScaffold itself.
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('renders title, leading and trailing actions when provided',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        AppScaffold(
          title: 'Exam Info',
          leading: IconButton(
              icon: const Icon(Icons.chevron_left_rounded), onPressed: () {}),
          actions: [
            IconButton(
                icon: const Icon(Icons.bookmark_border_rounded),
                onPressed: () {})
          ],
          body: const Text('Body content'),
        ),
      ),
    );
    expect(find.text('Exam Info'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
  });

  testWidgets('passes through bottomNavigationBar and floatingActionButton',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        AppScaffold(
          body: const Text('x'),
          bottomNavigationBar: const Text('Nav bar'),
          floatingActionButton: FloatingActionButton(
              onPressed: () {}, child: const Icon(Icons.add)),
        ),
      ),
    );
    expect(find.text('Nav bar'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('applies token-based horizontal padding by default',
      (tester) async {
    await tester.pumpWidget(wrap(const AppScaffold(body: Text('x'))));
    final Padding padding = tester.widget(
      find.ancestor(of: find.text('x'), matching: find.byType(Padding)).first,
    );
    expect(padding.padding,
        const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding));
  });

  testWidgets('accepts a custom padding override', (tester) async {
    await tester.pumpWidget(
      wrap(const AppScaffold(body: Text('x'), padding: EdgeInsets.all(4))),
    );
    final Padding padding = tester.widget(
      find.ancestor(of: find.text('x'), matching: find.byType(Padding)).first,
    );
    expect(padding.padding, const EdgeInsets.all(4));
  });

  testWidgets('long title does not overflow (wraps instead of throwing)',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        AppScaffold(
          title:
              'A very long exam screen title that would not normally fit on one line',
          leading: IconButton(
              icon: const Icon(Icons.chevron_left_rounded), onPressed: () {}),
          body: const Text('x'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scales with large text without throwing', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
        child: wrap(
          AppScaffold(
            title: 'Exam Info',
            leading: IconButton(
                icon: const Icon(Icons.chevron_left_rounded), onPressed: () {}),
            body: const Text('Body content'),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
