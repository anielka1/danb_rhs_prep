import 'dart:async';

import '../../models/entitlement.dart';
import '../subscription_repository.dart';

/// An in-memory [SubscriptionRepository] for unit tests and previews. Tests
/// can call [setEntitlement] to simulate purchases, renewals, expirations,
/// and restores without any StoreKit dependency.
class InMemorySubscriptionRepository implements SubscriptionRepository {
  InMemorySubscriptionRepository(Entitlement initialEntitlement)
      : _entitlement = initialEntitlement;

  Entitlement _entitlement;
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
