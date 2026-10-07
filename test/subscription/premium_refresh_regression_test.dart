import 'dart:async';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_free_practice_store.dart';
import 'package:danb_rhs_prep/subscription/free_practice_store.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:danb_rhs_prep/subscription/revenuecat_subscription_repository.dart';
import 'package:danb_rhs_prep/subscription/premium_access.dart';
import 'package:danb_rhs_prep/screens/subscription_screen.dart';
import 'package:danb_rhs_prep/widgets/primary_button.dart';
import '../screens/subscription_access_test.dart'
    show ControlledSubscriptions, premium;
import '../support/subscription_fixture.dart';
import 'revenuecat_repository_test.dart' show Client, info, date;

class DelayedClient extends Client {
  final response = Completer<rc.CustomerInfo>();
  @override
  Future<rc.CustomerInfo> customerInfo() => response.future;
}

class DelayedTrial extends InMemoryFreePracticeStore {
  Completer<FreePracticeState> response = Completer();
  @override
  Future<FreePracticeState> read() => response.future;
}

void main() {
  test(
      'older in-flight free result with equal requestDate must not revoke newer Premium event',
      () async {
    final client = DelayedClient();
    final repo = RevenueCatSubscriptionRepository(client, now: () => date);
    addTearDown(repo.dispose);
    await repo.initialize('test_fixture', production: false, ios: true);
    final pending = repo.currentEntitlement();
    await Future<void>.delayed(Duration.zero);
    client.listener!(info(active: true));
    client.response.complete(info(active: false));
    expect((await pending).isPremium, isTrue);
  });

  testWidgets('hanging entitlement read should eventually expose retry',
      (tester) async {
    final repo = ControlledSubscriptions();
    final access = PremiumAccessController(repo);
    addTearDown(access.dispose);
    addTearDown(repo.events.close);
    await tester.pump(const Duration(minutes: 2));
    expect(access.loading, isFalse);
    expect(access.failed, isTrue);
  });

  testWidgets(
      'open paywall must stop offering purchase after asynchronous Premium activation',
      (tester) async {
    final repo = subscriptionFixture();
    final access = PremiumAccessController(repo);
    addTearDown(access.dispose);
    addTearDown(repo.dispose);
    var closes = 0;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: PremiumAccessScope(
            controller: access,
            child: SubscriptionScreen(onClose: () => closes++))));
    await tester.pumpAndSettle();
    repo.setEntitlement(premium());
    await tester.pumpAndSettle();
    expect(access.active, isTrue);
    final buy = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(closes > 0 || buy.onPressed == null, isTrue);
  });

  test('equal-date explicit revocation wins over older in-flight Premium read',
      () async {
    final client = DelayedClient();
    final repo = RevenueCatSubscriptionRepository(client, now: () => date);
    addTearDown(repo.dispose);
    await repo.initialize('test_fixture', production: false, ios: true);
    client.listener!(info(active: true));
    final pending = repo.currentEntitlement();
    await Future<void>.delayed(Duration.zero);
    client.listener!(info(active: false));
    client.response.complete(info(active: true));
    expect((await pending).isPremium, isFalse);
  });

  test('a new free read without an intervening event still revokes access',
      () async {
    final client = Client();
    final repo = RevenueCatSubscriptionRepository(client, now: () => date);
    addTearDown(repo.dispose);
    await repo.initialize('test_fixture', production: false, ios: true);
    client.listener!(info(active: true));
    client.value = info(active: false);
    expect((await repo.currentEntitlement()).isPremium, isFalse);
  });

  testWidgets(
      'timeout offers Retry; new result wins over a late timed-out read',
      (tester) async {
    final repo = ControlledSubscriptions();
    final access = PremiumAccessController(repo);
    addTearDown(access.dispose);
    addTearDown(repo.events.close);
    final old = repo.read;
    await tester.pump(access.refreshTimeout);
    expect(access.loading, isFalse);
    expect(access.failed, isTrue);
    expect(access.ready, isFalse);
    repo.read = Completer<Entitlement>();
    final retry = access.refresh();
    expect(access.loading, isTrue);
    repo.read.complete(premium());
    await tester.pump();
    await retry;
    expect(access.active, isTrue);
    expect(access.failed, isFalse);
    old.complete(Entitlement.free(lastVerifiedAt: date));
    await tester.pump();
    expect(access.active, isTrue);
  });

  testWidgets(
      'verified Premium remains available through timeout but expires normally',
      (tester) async {
    var now = date;
    final repo = ControlledSubscriptions();
    final access = PremiumAccessController(repo, now: () => now);
    addTearDown(access.dispose);
    addTearDown(repo.events.close);
    repo.read.complete(premium(expires: now.add(const Duration(minutes: 1))));
    await tester.pump();
    repo.read = Completer<Entitlement>();
    final pending = access.refresh();
    await tester.pump(access.refreshTimeout);
    await pending;
    expect(access.active, isTrue);
    expect(access.ready, isTrue);
    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(minutes: 2));
    expect(access.active, isFalse);
    expect(access.ready, isFalse);
  });

  testWidgets(
      'late trial read cannot restore consumed free questions after Retry',
      (tester) async {
    final repo = ControlledSubscriptions();
    final trial = DelayedTrial();
    final access = PremiumAccessController(repo, trialStore: trial);
    addTearDown(access.dispose);
    addTearDown(repo.events.close);
    repo.read.complete(Entitlement.free(lastVerifiedAt: date));
    await tester.pump();
    final oldTrial = trial.response;
    await tester.pump(access.refreshTimeout);
    expect(access.failed, isTrue);
    trial.response = Completer<FreePracticeState>();
    final retry = access.refresh();
    await tester.pump();
    trial.response.complete(const FreePracticeState(answeredCount: 5));
    await tester.pump();
    await retry;
    expect(access.freeQuestionsRemaining, 0);
    oldTrial.complete(const FreePracticeState());
    await tester.pump();
    expect(access.freeQuestionsRemaining, 0);
    expect(access.canStartFreePractice, isFalse);
  });

  testWidgets('disposal during a pending read ignores its late result',
      (tester) async {
    final repo = ControlledSubscriptions();
    final access = PremiumAccessController(repo);
    addTearDown(repo.events.close);
    access.dispose();
    repo.read.complete(premium());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'late purchase reply after external activation does not pop the previous route',
      (tester) async {
    final repo = subscriptionFixture();
    final access = PremiumAccessController(repo);
    addTearDown(access.dispose);
    addTearDown(repo.dispose);
    final pending = Completer<Entitlement?>();
    var purchases = 0;
    repo.onPurchase = (_) {
      purchases++;
      return pending.future;
    };
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(PremiumAccessScope(
        controller: access,
        child: MaterialApp(
            navigatorKey: nav,
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: Text('Home')))));
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Previous screen'))));
    await tester.pumpAndSettle();
    nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue with Monthly'));
    await tester.tap(find.text('Continue with Monthly'));
    await tester.pump();
    expect(purchases, 1);
    repo.setEntitlement(premium());
    await tester.pumpAndSettle();
    expect(find.text('Previous screen'), findsOneWidget);
    expect(find.byType(SubscriptionScreen), findsNothing);
    pending.complete(premium());
    await tester.pumpAndSettle();
    expect(find.text('Previous screen'), findsOneWidget);
    expect(purchases, 1);
  });

  testWidgets(
      'already active Premium closes without loading prices or purchasing',
      (tester) async {
    final repo = subscriptionFixture()..setEntitlement(premium());
    var catalogCalls = 0;
    repo.onPlans = () async {
      catalogCalls++;
      return repo.availablePlans;
    };
    final access = PremiumAccessController(repo);
    addTearDown(access.dispose);
    addTearDown(repo.dispose);
    await tester.pump();
    var closes = 0;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: PremiumAccessScope(
            controller: access,
            child: SubscriptionScreen(onClose: () => closes++))));
    await tester.pumpAndSettle();
    expect(closes, 1);
    expect(catalogCalls, 0);
    expect(find.text('Continue with Monthly'), findsNothing);
  });

  testWidgets(
      'timed-out access screen exposes a working Retry instead of a paywall',
      (tester) async {
    final repo = ControlledSubscriptions();
    final access = PremiumAccessController(repo);
    addTearDown(access.dispose);
    addTearDown(repo.events.close);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: PremiumAccessScope(
            controller: access,
            child: Builder(
                builder: (context) =>
                    premiumBlock(context) ??
                    const Scaffold(body: Text('Access granted'))))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(access.refreshTimeout);
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(SubscriptionScreen), findsNothing);
    repo.read = Completer<Entitlement>();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.read.complete(premium());
    await tester.pumpAndSettle();
    expect(find.text('Access granted'), findsOneWidget);
  });

  testWidgets('SDK publication during a read still loads the free trial',
      (tester) async {
    final client = Client();
    final repo = RevenueCatSubscriptionRepository(client, now: () => date);
    await repo.initialize('test_fixture', production: false, ios: true);
    final access = PremiumAccessController(repo,
        trialStore: InMemoryFreePracticeStore(), now: () => date);
    addTearDown(access.dispose);
    addTearDown(repo.dispose);
    await tester.pump();
    expect(access.ready, isTrue);
    expect(access.active, isFalse);
    expect(access.freeQuestionsRemaining, 5);
    expect(access.canStartFreePractice, isTrue);
  });

  testWidgets(
      'activation and purchase reply do not dismiss a route above the paywall',
      (tester) async {
    final repo = subscriptionFixture();
    final access = PremiumAccessController(repo);
    addTearDown(access.dispose);
    addTearDown(repo.dispose);
    final pending = Completer<Entitlement?>();
    repo.onPurchase = (_) => pending.future;
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(PremiumAccessScope(
        controller: access,
        child: MaterialApp(
            navigatorKey: nav,
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: Text('Home')))));
    nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue with Monthly'));
    await tester.tap(find.text('Continue with Monthly'));
    await tester.pump();
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Another screen'))));
    await tester.pump(const Duration(seconds: 1));
    repo.setEntitlement(premium());
    pending.complete(premium());
    await tester.pumpAndSettle();
    expect(find.text('Another screen'), findsOneWidget);
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Continue with Monthly'), findsNothing);
  });
}
