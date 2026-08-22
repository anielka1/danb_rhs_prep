/// The premium access level currently granted to the user.
enum EntitlementTier { free, premium }

/// How a premium [Entitlement] was granted, described in domain terms only
/// (no StoreKit or platform purchase types).
enum EntitlementSource { none, purchase, restoredPurchase, promotional }

/// Domain-level subscription entitlement. This is the only representation
/// of purchase state that application and UI code should depend on; it
/// deliberately carries no StoreKit, receipt, or transaction types so that a
/// future StoreKit-backed implementation stays swappable behind
/// `SubscriptionRepository`.
///
/// Invariant, enforced by the constructor (throws [ArgumentError] if
/// violated): [source] is [EntitlementSource.none] and [expiresAt] and
/// [productId] are null exactly when [tier] is [EntitlementTier.free].
class Entitlement {
  Entitlement({
    required this.tier,
    required this.source,
    required this.lastVerifiedAt,
    this.expiresAt,
    this.productId,
  }) {
    if (tier != EntitlementTier.premium &&
        (source != EntitlementSource.none ||
            expiresAt != null ||
            productId != null)) {
      throw ArgumentError(
        'A free entitlement must have no source, expiry, or product ID.',
      );
    }
  }

  /// The default entitlement for a user who has never purchased premium.
  const Entitlement.free({required this.lastVerifiedAt})
      : tier = EntitlementTier.free,
        source = EntitlementSource.none,
        expiresAt = null,
        productId = null;

  final EntitlementTier tier;
  final EntitlementSource source;

  /// Always stored in UTC when set. Null for a lifetime/free entitlement.
  final DateTime? expiresAt;

  /// Always stored in UTC.
  final DateTime lastVerifiedAt;

  final String? productId;

  bool get isPremium => tier == EntitlementTier.premium;

  /// Whether this entitlement grants premium access at [now]. A premium
  /// entitlement with no [expiresAt] is treated as currently active.
  bool isActiveAt(DateTime now) {
    if (tier != EntitlementTier.premium) return false;
    return expiresAt == null || expiresAt!.isAfter(now);
  }

  Entitlement copyWith({
    EntitlementTier? tier,
    EntitlementSource? source,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    DateTime? lastVerifiedAt,
    String? productId,
  }) {
    return Entitlement(
      tier: tier ?? this.tier,
      source: source ?? this.source,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      productId: productId ?? this.productId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Entitlement &&
        other.tier == tier &&
        other.source == source &&
        other.expiresAt == expiresAt &&
        other.lastVerifiedAt == lastVerifiedAt &&
        other.productId == productId;
  }

  @override
  int get hashCode =>
      Object.hash(tier, source, expiresAt, lastVerifiedAt, productId);
}
