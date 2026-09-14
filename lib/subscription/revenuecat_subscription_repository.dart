import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import '../domain/models/entitlement.dart';
import '../domain/models/subscription_plan.dart';
import '../domain/repositories/subscription_store_repository.dart';

/// SDK seam used only in the infrastructure layer; unit tests supply a fake.
abstract interface class RevenueCatClient {
  Future<void> configure(String key);
  Future<rc.CustomerInfo> customerInfo();
  Future<rc.Offerings> offerings();
  Future<rc.CustomerInfo> purchase(rc.Package package);
  Future<rc.CustomerInfo> restore();
  void listen(void Function(rc.CustomerInfo) listener);
  void removeListener(void Function(rc.CustomerInfo) listener);
}

class PurchasesClient implements RevenueCatClient {
  static Future<void>? _configuration;
  @override
  Future<void> configure(String key) =>
      _configuration ??= _configure(key).catchError((Object e) {
        _configuration = null;
        throw e;
      });
  Future<void> _configure(String key) async {
    // Do not forward SDK payloads, anonymous IDs, receipts or keys to logs.
    await rc.Purchases.setLogHandler((_, __) {});
    await rc.Purchases.configure(rc.PurchasesConfiguration(key));
  }

  @override
  Future<rc.CustomerInfo> customerInfo() async {
    // Explicit refresh on launch/resume; SDK remains responsible for its cache.
    await rc.Purchases.invalidateCustomerInfoCache();
    return rc.Purchases.getCustomerInfo();
  }

  @override
  Future<rc.Offerings> offerings() => rc.Purchases.getOfferings();
  @override
  Future<rc.CustomerInfo> purchase(rc.Package package) async =>
      (await rc.Purchases.purchase(rc.PurchaseParams.package(package)))
          .customerInfo;
  @override
  Future<rc.CustomerInfo> restore() => rc.Purchases.restorePurchases();
  @override
  void listen(void Function(rc.CustomerInfo) listener) =>
      rc.Purchases.addCustomerInfoUpdateListener(listener);
  @override
  void removeListener(void Function(rc.CustomerInfo) listener) =>
      rc.Purchases.removeCustomerInfoUpdateListener(listener);
}

class RevenueCatSubscriptionRepository implements SubscriptionStoreRepository {
  RevenueCatSubscriptionRepository(this.client, {this.now = DateTime.now});
  final RevenueCatClient client;
  final DateTime Function() now;
  final _changes = StreamController<Entitlement>.broadcast(sync: true);
  final Map<String, rc.Package> _packages = {};
  bool _busy = false;
  bool _listening = false;
  Future<void>? _initialization;
  DateTime? _latestRequest;
  Entitlement? _latest;
  String? _key;

  /// Validation prevents Test Store credentials from entering release/profile.
  static bool validKey(String key,
          {required bool production, required bool ios}) =>
      ios &&
      ((key.startsWith('appl_') && key.length > 5) ||
          (!production && key.startsWith('test_') && key.length > 5));

  Future<void> initialize(String key,
      {required bool production, required bool ios}) {
    if (!validKey(key, production: production, ios: ios)) {
      throw const SubscriptionException(SubscriptionFailure.configuration);
    }
    _key = key;
    return _ready();
  }

  Future<void> _ready() {
    if (_key == null) {
      throw const SubscriptionException(SubscriptionFailure.configuration);
    }
    return _initialization ??= _initialize(_key!).catchError((Object e) {
      _initialization = null;
      throw e;
    });
  }

  Future<void> _initialize(String key) async {
    await client.configure(key);
    client.listen(_onInfo);
    _listening = true;
  }

  void _onInfo(rc.CustomerInfo info) => _publish(info);

  static Entitlement mapCustomerInfo(rc.CustomerInfo info, DateTime now,
      {bool restored = false}) {
    final premium = info.entitlements.all['premium'];
    final verified = DateTime.parse(info.requestDate).toUtc();
    final expiry = premium?.expirationDate == null
        ? null
        : DateTime.parse(premium!.expirationDate!).toUtc();
    if (premium?.isActive != true ||
        (expiry != null && !expiry.isAfter(now.toUtc()))) {
      return Entitlement.free(lastVerifiedAt: verified);
    }
    return Entitlement(
        tier: EntitlementTier.premium,
        source: restored
            ? EntitlementSource.restoredPurchase
            : EntitlementSource.purchase,
        lastVerifiedAt: verified,
        expiresAt: expiry,
        productId: premium!.productIdentifier);
  }

  Entitlement _publish(rc.CustomerInfo info, {bool restored = false}) {
    final value = mapCustomerInfo(info, now(), restored: restored);
    // A slow foreground refresh must not overwrite a newer purchase/listener.
    if (_latestRequest != null &&
        value.lastVerifiedAt.isBefore(_latestRequest!)) {
      return _latest!;
    }
    _latestRequest = value.lastVerifiedAt;
    _latest = value;
    if (!_changes.isClosed) _changes.add(value);
    return value;
  }

  @override
  Future<Entitlement> currentEntitlement() async {
    await _ready();
    return _publish(await client.customerInfo());
  }

  @override
  Stream<Entitlement> entitlementChanges() => _changes.stream;

  static String periodLabel(String period) {
    final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(period);
    if (match == null) {
      throw const SubscriptionException(SubscriptionFailure.unavailable);
    }
    final count = int.parse(match.group(1)!);
    if (count < 1) {
      throw const SubscriptionException(SubscriptionFailure.unavailable);
    }
    final unit =
        {'D': 'day', 'W': 'week', 'M': 'month', 'Y': 'year'}[match.group(2)]!;
    return count == 1 ? unit : '$count ${unit}s';
  }

  @override
  Future<List<SubscriptionPlan>> plans() async {
    try {
      await _ready();
      final offerings = await client.offerings();
      final offering = offerings.all['default'] ??
          (offerings.current?.identifier == 'default'
              ? offerings.current
              : null);
      if (offering == null) return _unavailable('Missing offering default');
      final packages = <String, rc.Package>{};
      final result = <SubscriptionPlan>[];
      for (final id in ['weekly', 'monthly']) {
        // Support both custom identifiers and RevenueCat standard packages.
        final matches = offering.availablePackages
            .where((p) => p.identifier == id || p.identifier == '\$rc_$id')
            .toList();
        if (matches.length != 1) {
          return _unavailable('Missing or ambiguous package $id');
        }
        final package = matches.single;
        final product = package.storeProduct;
        if (product.identifier != 'com.anielkad.danbrhs.premium.$id' ||
            product.subscriptionPeriod == null ||
            product.priceString.isEmpty) {
          return _unavailable('Invalid product metadata for $id');
        }
        final intro = product.introductoryPrice;
        final offer = intro == null
            ? null
            : '${intro.priceString} per ${periodLabel(intro.period)} for ${intro.cycles} billing period(s), if eligible. The store confirms eligibility.';
        result.add(SubscriptionPlan(
            id: id,
            name: id == 'weekly' ? 'Weekly' : 'Monthly',
            localizedPrice: product.priceString,
            currencyCode: product.currencyCode,
            billingPeriod: '/ ${periodLabel(product.subscriptionPeriod!)}',
            trialDescription: offer));
        packages[id] = package;
      }
      _packages
        ..clear()
        ..addAll(packages);
      return List.unmodifiable(result);
    } on PlatformException catch (e) {
      throw _error(e);
    }
  }

  Never _unavailable(String detail) {
    _packages.clear();
    if (kDebugMode) debugPrint('RevenueCat catalog: $detail');
    throw const SubscriptionException(SubscriptionFailure.unavailable);
  }

  SubscriptionException _error(PlatformException error) {
    final code = rc.PurchasesErrorHelper.getErrorCode(error);
    if (kDebugMode) debugPrint('RevenueCat request failed: ${code.name}');
    return SubscriptionException(code == rc.PurchasesErrorCode.networkError
        ? SubscriptionFailure.network
        : SubscriptionFailure.purchase);
  }

  @override
  Future<Entitlement?> purchase(String planId) async {
    if (_busy) throw const SubscriptionException(SubscriptionFailure.busy);
    final package = _packages[planId];
    if (package == null) {
      throw const SubscriptionException(SubscriptionFailure.unavailable);
    }
    _busy = true;
    try {
      return _publish(await client.purchase(package));
    } on PlatformException catch (e) {
      if (rc.PurchasesErrorHelper.getErrorCode(e) ==
          rc.PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      throw _error(e);
    } finally {
      _busy = false;
    }
  }

  @override
  Future<Entitlement> restore() async {
    if (_busy) throw const SubscriptionException(SubscriptionFailure.busy);
    _busy = true;
    try {
      await _ready();
      return _publish(await client.restore(), restored: true);
    } on PlatformException catch (e) {
      throw _error(e);
    } finally {
      _busy = false;
    }
  }

  void dispose() {
    if (_listening) client.removeListener(_onInfo);
    unawaited(_changes.close());
  }
}

/// No key / unsupported platform: Home remains usable, purchasing fails clearly.
class UnavailableSubscriptionRepository implements SubscriptionStoreRepository {
  const UnavailableSubscriptionRepository();
  @override
  Future<Entitlement> currentEntitlement() async =>
      Entitlement.free(lastVerifiedAt: DateTime.now().toUtc());
  @override
  Stream<Entitlement> entitlementChanges() => const Stream.empty();
  @override
  Future<List<SubscriptionPlan>> plans() async =>
      throw const SubscriptionException(SubscriptionFailure.configuration);
  @override
  Future<Entitlement?> purchase(String planId) async =>
      throw const SubscriptionException(SubscriptionFailure.configuration);
  @override
  Future<Entitlement> restore() async =>
      throw const SubscriptionException(SubscriptionFailure.configuration);
}
