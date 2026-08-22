import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_subscription_repository.dart';

void main() {
  test('currentEntitlement returns the seeded entitlement', () async {
    final free = Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1));
    final repository = InMemorySubscriptionRepository(free);

    expect(await repository.currentEntitlement(), free);

    repository.dispose();
  });

  test('setEntitlement updates current value and emits a change', () async {
    final free = Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1));
    final repository = InMemorySubscriptionRepository(free);
    final premium = Entitlement(
      tier: EntitlementTier.premium,
      source: EntitlementSource.purchase,
      lastVerifiedAt: DateTime.utc(2026, 1, 2),
      productId: 'danb_rhs_premium_monthly',
    );

    final changes = repository.entitlementChanges();
    final firstChange = changes.first;

    repository.setEntitlement(premium);

    expect(await repository.currentEntitlement(), premium);
    expect(await firstChange, premium);

    repository.dispose();
  });
}
