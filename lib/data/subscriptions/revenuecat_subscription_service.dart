import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/entitlement.dart';
import '../../features/exams/domain/exam_config.dart';
import '../../subscriptions/subscription_service.dart';

/// SDK boundary kept injectable for transaction and cache regression tests.
abstract interface class RevenueCatClient {
  Future<void> configure(String publicKey);
  Future<rc.CustomerInfo> customerInfo();
  Future<rc.Offerings> offerings();
  Future<rc.CustomerInfo> purchase(rc.Package package);
  Future<rc.CustomerInfo> restore();
  void addListener(void Function(rc.CustomerInfo) listener);
  void removeListener(void Function(rc.CustomerInfo) listener);
}

class PurchasesRevenueCatClient implements RevenueCatClient {
  @override
  Future<void> configure(String publicKey) async {
    final configuration = rc.PurchasesConfiguration(publicKey)
      ..entitlementVerificationMode = rc.EntitlementVerificationMode.informational
      ..automaticDeviceIdentifierCollectionEnabled = false;
    // Leave appUserID unset: RevenueCat creates/persists an anonymous identity.
    // RevenueCat owns transaction completion; do not also use another IAP SDK.
    await rc.Purchases.configure(configuration);
  }

  @override
  Future<rc.CustomerInfo> customerInfo() => rc.Purchases.getCustomerInfo();
  @override
  Future<rc.Offerings> offerings() => rc.Purchases.getOfferings();
  @override
  Future<rc.CustomerInfo> purchase(rc.Package package) async =>
      (await rc.Purchases.purchase(rc.PurchaseParams.package(package)))
          .customerInfo;
  @override
  Future<rc.CustomerInfo> restore() => rc.Purchases.restorePurchases();
  @override
  void addListener(void Function(rc.CustomerInfo) listener) =>
      rc.Purchases.addCustomerInfoUpdateListener(listener);
  @override
  void removeListener(void Function(rc.CustomerInfo) listener) =>
      rc.Purchases.removeCustomerInfoUpdateListener(listener);
}

class RevenueCatSubscriptionService implements SubscriptionService {
  RevenueCatSubscriptionService({
    required this.publicKey,
    required this.termsUrl,
    required this.privacyUrl,
    this.entitlementId = 'premium',
    RevenueCatClient? client,
    bool? supported,
    DateTime Function()? now,
    Future<bool> Function(Uri)? openUrl,
  })  : _client = client ?? PurchasesRevenueCatClient(),
        _supported = supported ??
            (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS),
        _now = now ?? DateTime.now,
        _openUrl = openUrl ??
            ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

  final String publicKey, termsUrl, privacyUrl, entitlementId;
  final RevenueCatClient _client;
  final bool _supported;
  final DateTime Function() _now;
  final Future<bool> Function(Uri) _openUrl;
  final _changes = StreamController<Entitlement>.broadcast();
  final Map<String, rc.Package> _packages = {};
  Future<void>? _initializing;
  bool _configured = false;
  bool _disposed = false;
  bool _transacting = false;
  Entitlement? _last;
  Timer? _expirationTimer;

  Future<void> _initialize() async {
    if (_disposed || !_supported || !publicKey.startsWith('appl_')) {
      throw const SubscriptionFailure('Purchases are currently unavailable.');
    }
    if (_configured) return;
    final pending = _initializing ??= _configure();
    try {
      await pending;
    } finally {
      if (identical(_initializing, pending)) _initializing = null;
    }
  }

  Future<void> _configure() async {
    await _client.configure(publicKey);
    if (_disposed) return;
    _configured = true;
    _client.addListener(_onCustomerInfo);
  }

  void _onCustomerInfo(rc.CustomerInfo info) => _accept(info);

  Entitlement _accept(rc.CustomerInfo info,
      {EntitlementSource source = EntitlementSource.purchase}) {
    final verifiedAt = DateTime.tryParse(info.requestDate)?.toUtc();
    if (verifiedAt == null) return _effective();
    // A slow refresh must not overwrite a newer purchase or refund response.
    if (_last != null && verifiedAt.isBefore(_last!.lastVerifiedAt)) {
      return _effective();
    }
    final premium = info.entitlements.all[entitlementId];
    final expires = DateTime.tryParse(premium?.expirationDate ?? '')?.toUtc();
    // This catalog is recurring-only. Never turn a missing expiry into lifetime.
    final active = premium != null &&
        premium.isActive &&
        premium.verification != rc.VerificationResult.failed &&
        expires != null &&
        expires.isAfter(_now());
    _last = active
        ? Entitlement(
            tier: EntitlementTier.premium,
            source: source,
            lastVerifiedAt: verifiedAt,
            expiresAt: expires,
            productId: premium.productIdentifier,
          )
        : Entitlement.free(lastVerifiedAt: verifiedAt);
    _expirationTimer?.cancel();
    if (!_disposed) {
      _changes.add(_last!);
      if (active) {
        _expirationTimer = Timer(expires.difference(_now()), () {
          if (!_disposed) _changes.add(_effective());
        });
      }
    }
    return _last!;
  }

  Entitlement _effective() {
    final last = _last;
    if (last != null && last.isActiveAt(_now())) return last;
    return Entitlement.free(
        lastVerifiedAt: last?.lastVerifiedAt ?? _now().toUtc());
  }

  @override
  Future<Entitlement> currentEntitlement() async {
    try {
      await _initialize();
      return _accept(await _client.customerInfo());
    } on Object {
      // SDK CustomerInfo is the durable cache. Never trust the old editable
      // bootstrap preference, nor extend an expired subscription while offline.
      return _effective();
    }
  }

  @override
  Stream<Entitlement> entitlementChanges() => _changes.stream;

  @override
  Future<List<SubscriptionOffer>> loadOffers(
      SubscriptionProductIds products) async {
    try {
      _packages.clear();
      await _initialize();
      if (!_validUrl(termsUrl) || !_validUrl(privacyUrl)) {
        throw const SubscriptionFailure('Purchases are currently unavailable.');
      }
      final offerings = await _client.offerings();
      final current = offerings.current;
      _packages.clear();
      if (current == null) {
        throw const SubscriptionFailure('Plans are unavailable. Try again later.');
      }
      final expected = {
        products.weekly: (SubscriptionPeriod.weekly, 'P1W'),
        products.monthly: (SubscriptionPeriod.monthly, 'P1M'),
        products.threeMonths: (SubscriptionPeriod.threeMonths, 'P3M'),
      };
      final offers = <SubscriptionOffer>[];
      for (final entry in expected.entries) {
        final matches = current.availablePackages.where((package) =>
            package.storeProduct.identifier == entry.key &&
            package.storeProduct.subscriptionPeriod == entry.value.$2);
        if (matches.length != 1) continue;
        final package = matches.single;
        _packages[entry.key] = package;
        offers.add(SubscriptionOffer(
          productId: entry.key,
          period: entry.value.$1,
          localizedPrice: package.storeProduct.priceString,
        ));
      }
      // A misconfigured catalog must not silently sell a different duration.
      if (offers.length != 3) {
        _packages.clear();
        throw const SubscriptionFailure('Plans are unavailable. Try again later.');
      }
      return List.unmodifiable(offers);
    } on SubscriptionFailure {
      rethrow;
    } on Object {
      throw const SubscriptionFailure('Could not load plans. Please try again.');
    }
  }

  @override
  Future<PurchaseOutcome> purchase(String productId) async {
    if (_transacting) {
      throw const SubscriptionFailure('Another purchase is still in progress.');
    }
    final package = _packages[productId];
    if (package == null) {
      throw const SubscriptionFailure('Reload plans before purchasing.');
    }
    _transacting = true;
    try {
      await _initialize();
      final entitlement = _accept(await _client.purchase(package));
      if (!entitlement.isActiveAt(_now())) {
        throw const SubscriptionFailure(
            'Premium is not active yet. Try Restore Purchases before buying again.');
      }
      return PurchaseOutcome.purchased;
    } on PlatformException catch (error) {
      final code = rc.PurchasesErrorHelper.getErrorCode(error);
      if (code == rc.PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      if (code == rc.PurchasesErrorCode.paymentPendingError) {
        return PurchaseOutcome.pending;
      }
      throw const SubscriptionFailure(
          'Could not complete the purchase. Please try again.');
    } on SubscriptionFailure {
      rethrow;
    } on Object {
      throw const SubscriptionFailure(
          'Could not complete the purchase. Please try again.');
    } finally {
      _transacting = false;
    }
  }

  @override
  Future<Entitlement> restorePurchases() async {
    if (_transacting) {
      throw const SubscriptionFailure('Another purchase is still in progress.');
    }
    _transacting = true;
    try {
      await _initialize();
      return _accept(await _client.restore(),
          source: EntitlementSource.restoredPurchase);
    } on Object {
      throw const SubscriptionFailure(
          'Could not restore purchases. Check your connection and try again.');
    } finally {
      _transacting = false;
    }
  }

  static bool _validUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  @override
  Future<void> openLink(SubscriptionLink link) async {
    final value = switch (link) {
      SubscriptionLink.manage => 'https://apps.apple.com/account/subscriptions',
      SubscriptionLink.terms => termsUrl,
      SubscriptionLink.privacy => privacyUrl,
    };
    try {
      if (!_validUrl(value) || !await _openUrl(Uri.parse(value))) {
        throw const SubscriptionFailure('Could not open this page. Try again later.');
      }
    } on Object {
      throw const SubscriptionFailure('Could not open this page. Try again later.');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _expirationTimer?.cancel();
    if (_configured) _client.removeListener(_onCustomerInfo);
    unawaited(_changes.close());
  }
}
