import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:danb_rhs_prep/data/subscriptions/revenuecat_subscription_service.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/subscriptions/subscription_service.dart';

const products = SubscriptionProductIds(
    weekly: 'weekly', monthly: 'monthly', threeMonths: 'quarterly');

rc.CustomerInfo customer({bool active = true, String? expires = '2030-02-01T00:00:00Z',
    String requested = '2030-01-01T00:00:00Z',
    rc.VerificationResult verification = rc.VerificationResult.verified}) {
  final entitlement = rc.EntitlementInfo('premium', active, false,
      '2030-01-01T00:00:00Z', '2030-01-01T00:00:00Z', 'monthly', true,
      expirationDate: expires, verification: verification);
  return rc.CustomerInfo(rc.EntitlementInfos({'premium': entitlement},
      active ? {'premium': entitlement} : {}), {}, [], [], [],
      '2030-01-01T00:00:00Z', 'anonymous-test', {}, requested);
}

rc.Package package(String id, String period, String price) => rc.Package.fromJson({
  'identifier': id, 'packageType': 'CUSTOM',
  'presentedOfferingContext': {'offeringIdentifier': 'default'},
  'product': {
    'identifier': id, 'description': 'Premium', 'title': id,
    'price': 10.0, 'priceString': price, 'currencyCode': 'EUR',
    'subscriptionPeriod': period,
  },
});

class FakeClient implements RevenueCatClient {
  int configurations = 0;
  rc.CustomerInfo info = customer();
  Object? error;
  Object? purchaseError;
  final packages = [package('weekly', 'P1W', '9,99 €'),
    package('monthly', 'P1M', '29,99 €'), package('quarterly', 'P3M', '49,99 €')];
  void Function(rc.CustomerInfo)? listener;
  @override
  Future<void> configure(String publicKey) async { configurations++; }
  @override
  Future<rc.CustomerInfo> customerInfo() async {
    if (error != null) throw error!;
    return info;
  }
  @override
  Future<rc.Offerings> offerings() async => rc.Offerings({},
      current: rc.Offering('default', 'Premium', {}, packages));
  @override
  Future<rc.CustomerInfo> purchase(rc.Package package) async {
    if (purchaseError != null) throw purchaseError!;
    return info;
  }
  @override
  Future<rc.CustomerInfo> restore() => customerInfo();
  @override
  void addListener(void Function(rc.CustomerInfo) callback) { listener = callback; }
  @override
  void removeListener(void Function(rc.CustomerInfo) callback) { listener = null; }
}

void main() {
  late FakeClient client;
  late RevenueCatSubscriptionService service;
  late DateTime now;
  setUp(() {
    client = FakeClient();
    now = DateTime.utc(2030, 1, 1);
    service = RevenueCatSubscriptionService(publicKey: 'appl_unit_test',
      termsUrl: 'https://example.com/terms', privacyUrl: 'https://example.com/privacy',
      client: client, supported: true, now: () => now);
  });
  tearDown(() => service.dispose());

  test('anonymous SDK is configured once across concurrent refreshes', () async {
    await Future.wait([service.currentEntitlement(), service.currentEntitlement()]);
    expect(client.configurations, 1);
  });

  test('catalog preserves localized prices and validates billing durations', () async {
    final offers = await service.loadOffers(products);
    expect(offers.map((o) => o.localizedPrice), ['9,99 €', '29,99 €', '49,99 €']);
    expect(offers.last.period, SubscriptionPeriod.threeMonths);
    client.packages[2] = package('quarterly', 'P1Y', '49,99 €');
    await expectLater(service.loadOffers(products), throwsA(isA<SubscriptionFailure>()));
    await expectLater(service.purchase('monthly'), throwsA(isA<SubscriptionFailure>()));
  });

  test('offline access ends at expiry and never stamps a new verification', () async {
    final original = await service.currentEntitlement();
    expect(original.isPremium, true);
    client.error = Exception('offline');
    now = DateTime.utc(2030, 1, 20);
    expect(await service.currentEntitlement(), original);
    now = DateTime.utc(2030, 2, 1);
    final expired = await service.currentEntitlement();
    expect(expired.isPremium, false);
    expect(expired.lastVerifiedAt, original.lastVerifiedAt);
  });

  test('refund removes premium, stale refresh cannot reinstate it', () async {
    await service.currentEntitlement();
    client.listener!(customer(active: false, requested: '2030-01-02T00:00:00Z'));
    expect((await service.currentEntitlement()).isPremium, false);
  });

  test('unverified or missing-expiry data cannot unlock lifetime access', () async {
    client.info = customer(verification: rc.VerificationResult.failed);
    expect((await service.currentEntitlement()).isPremium, false);
    client.info = customer(expires: null);
    expect((await service.currentEntitlement()).isPremium, false);
  });

  test('cancellation and pending do not grant access', () async {
    client.info = customer(active: false);
    await service.loadOffers(products);
    client.purchaseError = PlatformException(
      code: rc.PurchasesErrorCode.purchaseCancelledError.index.toString());
    expect(await service.purchase('monthly'), PurchaseOutcome.cancelled);
    client.purchaseError = PlatformException(
      code: rc.PurchasesErrorCode.paymentPendingError.index.toString());
    expect(await service.purchase('monthly'), PurchaseOutcome.pending);
    expect((await service.currentEntitlement()).isPremium, false);
  });

  test('purchase unlocks only after premium confirmation; restore identifies source', () async {
    await service.loadOffers(products);
    expect(await service.purchase('monthly'), PurchaseOutcome.purchased);
    expect((await service.restorePurchases()).source, EntitlementSource.restoredPurchase);
    client.info = customer(active: false, requested: '2030-01-03T00:00:00Z');
    await expectLater(service.purchase('monthly'), throwsA(isA<SubscriptionFailure>()));
  });

  test('absent public key does not configure SDK or grant premium', () async {
    final unavailable = RevenueCatSubscriptionService(publicKey: '', termsUrl: '',
      privacyUrl: '', client: client, supported: true);
    addTearDown(unavailable.dispose);
    expect((await unavailable.currentEntitlement()).isPremium, false);
    expect(client.configurations, 0);
    await expectLater(unavailable.loadOffers(products), throwsA(isA<SubscriptionFailure>()));
  });
}
