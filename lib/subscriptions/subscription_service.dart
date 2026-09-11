import '../domain/models/entitlement.dart';
import '../domain/repositories/subscription_repository.dart';
import '../features/exams/domain/exam_config.dart';

enum SubscriptionPeriod { weekly, monthly, threeMonths }

enum PurchaseOutcome { purchased, cancelled, pending }

enum SubscriptionLink { manage, terms, privacy }

class SubscriptionOffer {
  const SubscriptionOffer({
    required this.productId,
    required this.period,
    required this.localizedPrice,
  });

  final String productId;
  final SubscriptionPeriod period;
  final String localizedPrice;
}

/// A safe user-facing failure. Platform exceptions never reach the UI.
class SubscriptionFailure implements Exception {
  const SubscriptionFailure(this.message);
  final String message;
}

abstract interface class SubscriptionService implements SubscriptionRepository {
  Future<List<SubscriptionOffer>> loadOffers(SubscriptionProductIds products);
  Future<PurchaseOutcome> purchase(String productId);
  Future<Entitlement> restorePurchases();
  Future<void> openLink(SubscriptionLink link);
  void dispose();
}
