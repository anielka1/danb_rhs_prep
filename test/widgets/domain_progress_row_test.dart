import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/domain_progress_row.dart';
import 'package:danb_rhs_prep/widgets/progress_bar.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Scaffold(body: Center(child: child)));
  }

  testWidgets('renders the domain name, percent, and a ProgressBar',
      (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        wrap(
            const DomainProgressRow(
                domainName: 'Radiation Physics', progress: 0.85),
            theme: theme),
      );
      expect(find.text('Radiation Physics'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.byType(ProgressBar), findsOneWidget);
    }
  });

  testWidgets('shows optional supporting text', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DomainProgressRow(
            domainName: 'Radiation Physics',
            progress: 0.85,
            supportingText: '17/20 correct'),
      ),
    );
    expect(find.text('17/20 correct'), findsOneWidget);
  });

  testWidgets('a long domain name does not overflow the row', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 200,
          child: DomainProgressRow(
            domainName:
                'Radiation Protection Standards and Advanced Equipment Operation',
            progress: 0.6,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes an accessible percentage description', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        const DomainProgressRow(
            domainName: 'Radiation Physics',
            progress: 0.85,
            supportingText: '17/20 correct'),
      ),
    );
    expect(
      tester.getSemantics(find.byType(DomainProgressRow)),
      matchesSemantics(label: 'Radiation Physics, 85 percent, 17/20 correct'),
    );
    handle.dispose();
  });
}
