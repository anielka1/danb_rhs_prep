import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/screens/subscription_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

import 'package:danb_rhs_prep/links/external_link_launcher.dart';
import 'package:danb_rhs_prep/widgets/subscription_product_card.dart';
import '../support/subscription_fixture.dart';

class FakeLauncher implements ExternalLinkLauncher {
  final calls = <Uri>[];
  bool fail = false;
  bool throws = false;
  @override
  Future<bool> open(Uri uri) async {
    calls.add(uri);
    if (throws) throw StateError('platform error');
    return !fail;
  }
}

void main() {
  for (final failure in ['none', 'false', 'throw']) {
    testWidgets('Free legal links preserve weekly selection; $failure',
        (tester) async {
      final semantics = tester.ensureSemantics();

      final repo = subscriptionFixture();
      addTearDown(repo.dispose);
      var purchases = 0;
      var closes = 0;
      repo.onPurchase = (_) async {
        purchases++;
        return null;
      };
      final launcher = FakeLauncher()
        ..fail = failure == 'false'
        ..throws = failure == 'throw';
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: SubscriptionScreen(
              repository: repo,
              linkLauncher: launcher,
              onClose: () => closes++)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Weekly'));
      await tester.tap(find.text('Weekly'));
      await tester.pump();
      for (final entry in {
        'Privacy Policy': 'https://prepnovo.org/privacy-policy/',
        'Terms of Use': 'https://prepnovo.org/terms-of-use/',
      }.entries) {
        await tester.ensureVisible(find.text(entry.key));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(entry.key), findsOneWidget);
        await tester.tap(find.text(entry.key));
        await tester.pump();
        expect(launcher.calls.last.toString(), entry.value);
        expect(find.byType(SubscriptionScreen), findsOneWidget);
        expect(
            tester
                .widgetList<SubscriptionProductCard>(
                    find.byType(SubscriptionProductCard))
                .singleWhere((p) => p.selected)
                .title,
            'Weekly');
        if (failure != 'none') {
          expect(find.text('Could not open this page. Please try again.'),
              findsOneWidget);
          ScaffoldMessenger.of(tester.element(find.byType(SubscriptionScreen)))
              .removeCurrentSnackBar();
          await tester.pumpAndSettle();
        }
      }
      semantics.dispose();
      expect(purchases, 0);
      expect(closes, 0);
      expect((await repo.currentEntitlement()).isPremium, false);
    });
  }

  testWidgets('legal links are enabled even without store or Premium',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme, home: const SubscriptionScreen()));
    await tester.pumpAndSettle();
    for (final label in ['Privacy Policy', 'Terms of Use']) {
      final button = find.widgetWithText(TextButton, label);
      expect(tester.widget<TextButton>(button).onPressed, isNotNull);
    }
  });
}
