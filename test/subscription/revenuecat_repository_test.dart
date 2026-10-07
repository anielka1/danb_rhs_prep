import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:danb_rhs_prep/domain/models/subscription_plan.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/subscription/revenuecat_subscription_repository.dart';

final date = DateTime.utc(2026, 9, 14);
rc.CustomerInfo info(
    {bool? active, String? expiry, String request = '2026-09-14T00:00:00Z'}) {
  final entries = <String, rc.EntitlementInfo>{
    if (active != null)
      'premium': rc.EntitlementInfo('premium', active, true, request, request,
          'com.anielkad.danbrhs.premium.monthly', true,
          expirationDate: expiry),
  };
  return rc.CustomerInfo(
      rc.EntitlementInfos(entries, const {}),
      const {},
      const [],
      const [],
      const [],
      request,
      'anonymous-fixture',
      const {},
      request);
}

rc.Package package(String id,
        {bool standard = false, rc.IntroductoryPrice? intro}) =>
    rc.Package(
        standard ? '\$rc_$id' : id,
        rc.PackageType.custom,
        rc.StoreProduct('com.anielkad.danbrhs.premium.$id', 'Fixture',
            'Store title', 12.34, '€12,34', 'EUR',
            subscriptionPeriod: id == 'monthly' ? 'P1M' : 'P1W',
            introductoryPrice: intro),
        const rc.PresentedOfferingContext('default', null, null));
rc.Offerings catalog(List<rc.Package> packages) => rc.Offerings({
      'default': rc.Offering('default', 'Fixture', const {}, packages),
    });

class Client implements RevenueCatClient {
  int configurations = 0, purchases = 0, restores = 0;
  rc.CustomerInfo value = info();
  rc.Offerings products = catalog([package('weekly'), package('monthly')]);
  Object? failure;
  bool failConfiguration = false;
  Completer<rc.CustomerInfo>? pending;
  void Function(rc.CustomerInfo)? listener;
  rc.Package? purchased;
  @override
  Future<void> configure(String key) async {
    configurations++;
    if (failConfiguration) throw StateError('fixture');
  }

  @override
  Future<rc.CustomerInfo> customerInfo() async => value;
  @override
  Future<rc.Offerings> offerings() async => products;
  @override
  Future<rc.CustomerInfo> purchase(rc.Package package) async {
    purchases++;
    purchased = package;
    if (failure != null) throw failure!;
    return pending == null ? value : await pending!.future;
  }

  @override
  Future<rc.CustomerInfo> restore() async {
    restores++;
    if (failure != null) throw failure!;
    return pending == null ? value : await pending!.future;
  }

  @override
  void listen(void Function(rc.CustomerInfo) callback) {
    listener = callback;
  }

  @override
  void removeListener(void Function(rc.CustomerInfo) callback) {
    if (callback == listener) listener = null;
  }
}

void main() {
  test('customer info keeps the SDK cache', () async {
    const channel = MethodChannel('purchases_flutter');
    final methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      methods.add(call.method);
      throw PlatformException(code: 'offline');
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    await expectLater(
      PurchasesClient().customerInfo(),
      throwsA(isA<PlatformException>()),
    );
    expect(methods, ['getCustomerInfo']);
  });

  test(
      'configuration rejects missing, secret, wrong platform and release Test Store keys',
      () {
    for (final key in ['', 'sk_secret', 'test_fixture']) {
      expect(
          RevenueCatSubscriptionRepository.validKey(key,
              production: true, ios: true),
          false);
    }
    expect(
        RevenueCatSubscriptionRepository.validKey('appl_fixture',
            production: true, ios: true),
        true);
    expect(
        RevenueCatSubscriptionRepository.validKey('test_fixture',
            production: false, ios: true),
        true);
    expect(
        RevenueCatSubscriptionRepository.validKey('appl_fixture',
            production: false, ios: false),
        false);
  });
  test('maps all premium activity, UTC request time, expiry and product', () {
    for (final value in [
      info(),
      info(active: false),
      info(active: true, expiry: '2026-09-13T00:00:00Z')
    ]) {
      expect(
          RevenueCatSubscriptionRepository.mapCustomerInfo(value, date)
              .isPremium,
          false);
    }
    final entitlement = RevenueCatSubscriptionRepository.mapCustomerInfo(
        info(
            active: true,
            expiry: '2026-10-14T02:00:00+02:00',
            request: '2026-09-14T02:00:00+02:00'),
        date);
    expect(entitlement.isActiveAt(date), true);
    expect(entitlement.productId, 'com.anielkad.danbrhs.premium.monthly');
    expect(entitlement.lastVerifiedAt, date);
    expect(entitlement.expiresAt, DateTime.utc(2026, 10, 14));
  });
  late Client client;
  late RevenueCatSubscriptionRepository repo;
  setUp(() async {
    client = Client();
    repo = RevenueCatSubscriptionRepository(client, now: () => date);
    await repo.initialize('test_fixture', production: false, ios: true);
  });
  tearDown(() => repo.dispose());
  test(
      'configure once and listener emits/revokes, stale refresh cannot roll back',
      () async {
    await repo.initialize('test_fixture', production: false, ios: true);
    expect(client.configurations, 1);
    final values = <Entitlement>[];
    final sub = repo.entitlementChanges().listen(values.add);
    client.listener!(info(active: true, request: '2026-09-14T00:00:01Z'));
    expect((await repo.currentEntitlement()).isPremium, true);
    client.listener!(info(active: false, request: '2026-09-14T00:00:02Z'));
    expect(values.last.isPremium, false);
    await sub.cancel();
  });
  test(
      'localized price and period from store, standard/custom IDs and conditional trial',
      () async {
    client.products = catalog([
      package('weekly', standard: true),
      package('monthly',
          intro: const rc.IntroductoryPrice(
              0, '€0,00', 'P3D', 1, rc.PeriodUnit.day, 3))
    ]);
    final plans = await repo.plans();
    expect(plans.map((p) => p.localizedPrice), everyElement('€12,34'));
    expect(plans.last.billingPeriod, '/ month');
    expect(plans.last.trialDescription, contains('3 days'));
    expect(plans.last.trialDescription, contains('if eligible'));
    client.value = info(active: true);
    expect((await repo.purchase('monthly'))!.isPremium, true);
    expect(client.purchased!.identifier, 'monthly');
  });
  test('missing offering or either package never returns misleading plans',
      () async {
    for (final products in [
      const rc.Offerings({}),
      catalog([package('weekly')]),
      catalog([package('monthly')])
    ]) {
      client.products = products;
      await expectLater(repo.plans(), throwsA(isA<SubscriptionException>()));
    }
    expect(client.purchases, 0);
  });
  test(
      'cancellation is null; errors typed; purchase without entitlement stays free',
      () async {
    await repo.plans();
    client.failure = PlatformException(code: '1');
    expect(await repo.purchase('weekly'), isNull);
    client.failure = PlatformException(code: '10');
    await expectLater(
        repo.purchase('weekly'), throwsA(isA<SubscriptionException>()));
    client.failure = null;
    expect((await repo.purchase('weekly'))!.isPremium, false);
  });
  test('single flight across purchase/restore, restore active/empty/error',
      () async {
    await repo.plans();
    client.pending = Completer();
    final purchase = repo.purchase('weekly');
    await expectLater(
        repo.purchase('monthly'), throwsA(isA<SubscriptionException>()));
    await expectLater(repo.restore(), throwsA(isA<SubscriptionException>()));
    expect(client.purchases, 1);
    client.pending!.complete(info(active: true));
    await purchase;
    client.pending = null;
    client.value = info(active: true);
    expect((await repo.restore()).source, EntitlementSource.restoredPurchase);
    client.value = info(active: false);
    expect((await repo.restore()).isPremium, false);
    client.failure = PlatformException(code: '10');
    await expectLater(repo.restore(), throwsA(isA<SubscriptionException>()));
  });
  test('configuration failure can retry without recreating UI', () async {
    final freshClient = Client()..failConfiguration = true;
    final fresh = RevenueCatSubscriptionRepository(freshClient);
    await expectLater(
        fresh.initialize('test_fixture', production: false, ios: true),
        throwsStateError);
    freshClient.failConfiguration = false;
    expect(await fresh.plans(), hasLength(2));
    expect(freshClient.configurations, 2);
    fresh.dispose();
  });
}
