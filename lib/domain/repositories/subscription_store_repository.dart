import '../models/entitlement.dart';
import '../models/subscription_plan.dart';
import 'subscription_repository.dart';

/// Purchasing extension of the existing entitlement boundary.
abstract interface class SubscriptionStoreRepository
    implements SubscriptionRepository {
  Future<List<SubscriptionPlan>> plans();

  /// Null means user cancellation; only an active entitlement grants access.
  Future<Entitlement?> purchase(String planId);
  Future<Entitlement> restore();
}
