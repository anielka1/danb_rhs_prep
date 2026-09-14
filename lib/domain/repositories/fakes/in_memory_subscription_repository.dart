import 'dart:async';

import '../../models/entitlement.dart';
import '../subscription_repository.dart';
import '../subscription_store_repository.dart';
import '../../models/subscription_plan.dart';

/// An in-memory [SubscriptionRepository] for unit tests and previews. Tests
/// can call [setEntitlement] to simulate purchases, renewals, expirations,
/// and restores without any StoreKit dependency.
class InMemorySubscriptionRepository implements SubscriptionStoreRepository {
  InMemorySubscriptionRepository(Entitlement initialEntitlement)
      : _entitlement = initialEntitlement;

  Entitlement _entitlement;
  List<SubscriptionPlan> availablePlans = [];
  Future<Entitlement?> Function(String)? onPurchase;
  Future<Entitlement> Function()? onRestore;
  Future<List<SubscriptionPlan>> Function()? onPlans;
  @override
  Future<List<SubscriptionPlan>> plans() async {
    if (onPlans != null) return onPlans!();
    if (availablePlans.isEmpty) {
      throw const SubscriptionException(SubscriptionFailure.unavailable);
    }
    return List.unmodifiable(availablePlans);
  }

  @override
  Future<Entitlement?> purchase(String planId) async {
    if (onPurchase == null) {
      throw const SubscriptionException(SubscriptionFailure.unavailable);
    }
    final result = await onPurchase!(planId);
    if (result != null) setEntitlement(result);
    return result;
  }

  @override
  Future<Entitlement> restore() async {
    final result = onRestore == null ? _entitlement : await onRestore!();
    setEntitlement(result);
    return result;
  }

  final StreamController<Entitlement> _controller =
      StreamController<Entitlement>.broadcast();

  void setEntitlement(Entitlement entitlement) {
    _entitlement = entitlement;
    _controller.add(entitlement);
  }

  @override
  Future<Entitlement> currentEntitlement() async => _entitlement;

  @override
  Stream<Entitlement> entitlementChanges() => _controller.stream;

  void dispose() {
    unawaited(_controller.close());
  }
}
