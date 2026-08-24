import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/readiness_band.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/readiness_card.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Scaffold(body: Center(child: child)));
  }

  testWidgets('renders the band label and score under light and dark themes',
      (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        wrap(const ReadinessCard(score: 64, band: ReadinessBand.gettingClose),
            theme: theme),
      );
      expect(find.text('Getting Close'), findsOneWidget);
      expect(find.text('64%'), findsOneWidget);
    }
  });

  testWidgets('shows the low-evidence message instead of a band label',
      (tester) async {
    await tester.pumpWidget(
      wrap(const ReadinessCard(
          score: 0, band: ReadinessBand.starting, hasEvidence: false)),
    );
    expect(find.text('Not enough data yet'), findsOneWidget);
    expect(find.text('Starting'), findsNothing);
  });

  testWidgets('shows the optional evidence explanation and supporting message',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const ReadinessCard(
          score: 70,
          band: ReadinessBand.examReady,
          evidenceExplanation: 'Based on 40 recent questions.',
          supportingMessage: 'Radiation Protection has 3 recent mistakes.',
        ),
      ),
    );
    expect(find.text('Based on 40 recent questions.'), findsOneWidget);
    expect(find.text('Radiation Protection has 3 recent mistakes.'),
        findsOneWidget);
  });

  testWidgets(
      'view detail action fires exactly once and is absent without a callback',
      (tester) async {
    await tester.pumpWidget(
      wrap(const ReadinessCard(score: 70, band: ReadinessBand.examReady)),
    );
    expect(find.text('View Details'), findsNothing);

    int taps = 0;
    await tester.pumpWidget(
      wrap(ReadinessCard(
          score: 70,
          band: ReadinessBand.examReady,
          onViewDetail: () => taps++)),
    );
    await tester.tap(find.text('View Details'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('"View Details" is reachable by assistive technology',
      (tester) async {
    // Regression test: AppCard's semanticLabel mechanism excludes its
    // entire child from the semantics tree, which previously made this
    // button completely unreachable by VoiceOver whenever a card-level
    // semanticLabel was set. ReadinessCard no longer sets one.
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(ReadinessCard(
          score: 70, band: ReadinessBand.examReady, onViewDetail: () {})),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('View readiness detail')),
      matchesSemantics(
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true),
    );

    handle.dispose();
  });
}
