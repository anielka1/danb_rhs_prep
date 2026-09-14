import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/screens/subscription_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import '../support/golden_probe.dart';
import '../support/subscription_fixture.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await loader.load();
  });
  for (final dark in [false, true]) {
    for (final scale in GoldenTextScale.values) {
      testWidgets('subscription dark=$dark scale=$scale', (tester) async {
        final repository = subscriptionFixture();
        addTearDown(repository.dispose);
        await pumpGolden(tester, SubscriptionScreen(repository: repository),
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            textScale: scale);
        expect(tester.takeException(), isNull);
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(goldenPath(
                screen: 'subscription',
                brightness: dark ? Brightness.dark : Brightness.light,
                textScale: scale)));
        await tester.ensureVisible(find.text('Monthly'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('Close subscription').hitTestable(),
            findsOneWidget);
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(goldenPath(
                screen: 'subscription_plans',
                brightness: dark ? Brightness.dark : Brightness.light,
                textScale: scale)));
        await tester.ensureVisible(find.text('Privacy Policy'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
