/// Store-supplied presentation data. No SDK objects cross this boundary.
class SubscriptionPlan {
  const SubscriptionPlan(
      {required this.id,
      required this.name,
      required this.localizedPrice,
      required this.currencyCode,
      required this.billingPeriod,
      this.trialDescription,
      this.available = true});
  final String id, name, localizedPrice, currencyCode, billingPeriod;

  /// Describes the store's offer, explicitly conditional on eligibility.
  final String? trialDescription;
  final bool available;
}

enum SubscriptionFailure { configuration, unavailable, network, purchase, busy }

class SubscriptionException implements Exception {
  const SubscriptionException(this.reason);
  final SubscriptionFailure reason;
  String get message => switch (reason) {
        SubscriptionFailure.configuration =>
          'Subscriptions are not configured for this build.',
        SubscriptionFailure.unavailable =>
          'Subscription plans are unavailable. Please try again.',
        SubscriptionFailure.network =>
          'Could not reach the store. Check your connection and try again.',
        SubscriptionFailure.purchase =>
          'The store could not complete the request. Please try again.',
        SubscriptionFailure.busy => 'A store request is already in progress.',
      };
}
