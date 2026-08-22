import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/entitlement.dart';

void main() {
  test('Entitlement.free carries no source, expiry, or product', () {
    final free = Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1));

    expect(free.isPremium, isFalse);
    expect(free.source, EntitlementSource.none);
    expect(free.expiresAt, isNull);
    expect(free.productId, isNull);
  });

  test('a free tier with a source or expiry violates the invariant', () {
    expect(
      () => Entitlement(
        tier: EntitlementTier.free,
        source: EntitlementSource.purchase,
        lastVerifiedAt: DateTime.utc(2026, 1, 1),
      ),
      throwsArgumentError,
    );
  });

  test('a premium entitlement with no expiry is always active', () {
    final lifetime = Entitlement(
      tier: EntitlementTier.premium,
      source: EntitlementSource.purchase,
      lastVerifiedAt: DateTime.utc(2026, 1, 1),
      productId: 'danb_rhs_premium_monthly',
    );

    expect(lifetime.isActiveAt(DateTime.utc(2030, 1, 1)), isTrue);
  });

  test('a premium entitlement is inactive once past its expiry', () {
    final expiring = Entitlement(
      tier: EntitlementTier.premium,
      source: EntitlementSource.purchase,
      lastVerifiedAt: DateTime.utc(2026, 1, 1),
      expiresAt: DateTime.utc(2026, 2, 1),
      productId: 'danb_rhs_premium_monthly',
    );

    expect(expiring.isActiveAt(DateTime.utc(2026, 1, 15)), isTrue);
    expect(expiring.isActiveAt(DateTime.utc(2026, 3, 1)), isFalse);
  });

  test('a free entitlement is never active', () {
    final free = Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1));
    expect(free.isActiveAt(DateTime.utc(2026, 1, 1)), isFalse);
  });

  test('copyWith can upgrade a free entitlement to premium', () {
    final free = Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1));

    final upgraded = free.copyWith(
      tier: EntitlementTier.premium,
      source: EntitlementSource.purchase,
      productId: 'danb_rhs_premium_weekly',
      lastVerifiedAt: DateTime.utc(2026, 1, 2),
    );

    expect(upgraded.isPremium, isTrue);
    expect(upgraded.productId, 'danb_rhs_premium_weekly');
  });

  test('equal field values produce equal instances and hash codes', () {
    final a = Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1));
    final b = Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1));
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });
}
