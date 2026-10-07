import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/subscription_plan.dart';
import 'package:danb_rhs_prep/screens/subscription_screen.dart';
import 'package:danb_rhs_prep/subscription/premium_access.dart';
import 'package:danb_rhs_prep/widgets/subscription_product_card.dart';
import 'package:danb_rhs_prep/widgets/primary_button.dart';
import '../support/subscription_fixture.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

Entitlement active() => Entitlement(
    tier: EntitlementTier.premium,
    source: EntitlementSource.purchase,
    lastVerifiedAt: DateTime.now().toUtc());
Future<void> tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  testWidgets(
      'selected package, double click, cancellation, error retry, live Premium and close',
      (tester) async {
    final repo = subscriptionFixture();
    final access = PremiumAccessController(repo);
    addTearDown(() {
      access.dispose();
      repo.dispose();
    });
    int calls = 0, closes = 0;
    final pending = Completer<Entitlement?>();
    repo.onPurchase = (id) {
      expect(id, 'weekly');
      calls++;
      return pending.future;
    };
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: PremiumAccessScope(
            controller: access,
            child: SubscriptionScreen(onClose: () => closes++))));
    await tester.pumpAndSettle();
    await tap(tester, 'Weekly');
    await tap(tester, 'Continue with Weekly');
    expect(calls, 1);
    expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull);
    expect(
        tester
            .widgetList<SubscriptionProductCard>(
                find.byType(SubscriptionProductCard))
            .every((p) => !p.enabled),
        true);
    await tap(tester, 'Continue with Weekly');
    expect(calls, 1);
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(closes, 0);
    expect(access.active, false);
    repo.onPurchase = (_) async =>
        throw const SubscriptionException(SubscriptionFailure.network);
    await tap(tester, 'Continue with Weekly');
    await tester.pumpAndSettle();
    expect(find.textContaining('Check your connection'), findsOneWidget);
    repo.onPurchase = (_) async => active();
    await tap(tester, 'Continue with Weekly');
    await tester.pumpAndSettle();
    expect(access.active, true);
    expect(closes, 1);
  });
  testWidgets('restore free, error and success; close never writes entitlement',
      (tester) async {
    final repo = subscriptionFixture();
    addTearDown(repo.dispose);
    int closes = 0;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: SubscriptionScreen(repository: repo, onClose: () => closes++)));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Close subscription'));
    expect((await repo.currentEntitlement()).isPremium, false);
    expect(closes, 1);
    // Reopen after Close, as the actual navigator does. The closed instance
    // must not accept another operation while its route is being removed.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: SubscriptionScreen(repository: repo, onClose: () => closes++)));
    await tester.pumpAndSettle();
    await tap(tester, 'Restore purchases');
    await tester.pumpAndSettle();
    expect(find.text('No active subscription was found.'), findsOneWidget);
    repo.onRestore = () async =>
        throw const SubscriptionException(SubscriptionFailure.purchase);
    await tap(tester, 'Restore purchases');
    await tester.pumpAndSettle();
    expect(find.textContaining('could not complete'), findsOneWidget);
    repo.onRestore = () async => active();
    await tap(tester, 'Restore purchases');
    await tester.pumpAndSettle();
    expect(closes, 2);
  });
  testWidgets(
      'catalog failure Retry loads real fixture and no success for free purchase',
      (tester) async {
    final repo = subscriptionFixture();
    addTearDown(repo.dispose);
    repo.onPlans = () async =>
        throw const SubscriptionException(SubscriptionFailure.unavailable);
    int closes = 0;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: SubscriptionScreen(repository: repo, onClose: () => closes++)));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionProductCard), findsNothing);
    repo.onPlans = null;
    await tap(tester, 'Retry');
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionProductCard), findsNWidgets(2));
    repo.onPurchase = (_) => repo.currentEntitlement();
    await tap(tester, 'Continue with Monthly');
    await tester.pumpAndSettle();
    expect(closes, 0);
    expect(find.textContaining('has not activated Premium'), findsOneWidget);
  });
}
