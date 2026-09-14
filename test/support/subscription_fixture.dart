import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/subscription_plan.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_subscription_repository.dart';

InMemorySubscriptionRepository subscriptionFixture() =>
    InMemorySubscriptionRepository(
        Entitlement.free(lastVerifiedAt: DateTime.utc(2026)))
      ..availablePlans = const [
        SubscriptionPlan(
            id: 'weekly',
            name: 'Weekly',
            localizedPrice: r'$9.99',
            currencyCode: 'USD',
            billingPeriod: '/ week'),
        SubscriptionPlan(
            id: 'monthly',
            name: 'Monthly',
            localizedPrice: r'$19.99',
            currencyCode: 'USD',
            billingPeriod: '/ month'),
      ];
