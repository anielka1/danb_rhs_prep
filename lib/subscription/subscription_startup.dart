import 'package:flutter/foundation.dart';
import '../domain/repositories/subscription_store_repository.dart';
import 'revenuecat_subscription_repository.dart';

Future<SubscriptionStoreRepository>
    createProductionSubscriptionRepository() async {
  const key = String.fromEnvironment('REVENUECAT_IOS_API_KEY');
  final ios = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  if (!RevenueCatSubscriptionRepository.validKey(key,
      production: !kDebugMode, ios: ios)) {
    if (kDebugMode) {
      debugPrint('RevenueCat: missing or invalid iOS SDK configuration.');
    }
    return const UnavailableSubscriptionRepository();
  }
  final repository = RevenueCatSubscriptionRepository(PurchasesClient());
  try {
    await repository.initialize(key, production: !kDebugMode, ios: ios);
  } catch (_) {
    // Never print configuration exceptions, which may include the API key.
    if (kDebugMode) {
      debugPrint('RevenueCat initialization failed; requests can retry.');
    }
  }
  return repository;
}
