import '../models/entitlement.dart';

/// The subscription/entitlement boundary. Implementations may be backed by
/// StoreKit, a fake for tests, or a future server-verified source, but this
/// interface exposes only domain-level [Entitlement] information — never
/// StoreKit or platform purchase types.
abstract interface class SubscriptionRepository {
  /// The best currently-known entitlement, suitable for offline use (e.g.
  /// the last verified value while the store is unreachable).
  Future<Entitlement> currentEntitlement();

  /// Emits a new value whenever the entitlement changes, such as after a
  /// purchase, renewal, expiration, or restore.
  Stream<Entitlement> entitlementChanges();
}
