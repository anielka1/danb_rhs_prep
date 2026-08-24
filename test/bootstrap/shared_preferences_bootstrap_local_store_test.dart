import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:danb_rhs_prep/bootstrap/shared_preferences_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/readiness_band.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';

void main() {
  // A fresh in-memory backend per test, isolated from
  // `test/flutter_test_config.dart`'s shared fallback instance, so these
  // tests can freely inspect/corrupt raw stored values without any risk
  // of leaking into other test files.
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('every key starts absent on a fresh store', () async {
    final store = SharedPreferencesBootstrapLocalStore();

    expect(await store.readSelectedExamId(), isNull);
    expect(await store.readOnboardingComplete(), isNull);
    expect(await store.readThemePreference(), isNull);
    expect(await store.readEntitlementSnapshot(), isNull);
    expect(await store.readLatestReadinessSnapshot('danb_rhs'), isNull);
  });

  test(
      'each key round-trips through write then read, including across a '
      'fresh store instance (genuine persistence, not just in-memory '
      'object identity)', () async {
    final writer = SharedPreferencesBootstrapLocalStore();
    await writer.writeSelectedExamId('danb_rhs');
    await writer.writeOnboardingComplete(true);
    await writer.writeThemePreference(ThemePreference.dark);
    final entitlement = Entitlement(
      tier: EntitlementTier.premium,
      source: EntitlementSource.purchase,
      lastVerifiedAt: DateTime.utc(2026, 1, 1),
      expiresAt: DateTime.utc(2026, 6, 1),
      productId: 'monthly',
    );
    await writer.writeEntitlementSnapshot(entitlement);
    final snapshot = ReadinessSnapshot(
      id: 'snap-1',
      examId: 'danb_rhs',
      calculatedAt: DateTime.utc(2026, 1, 1),
      overallScore: 62,
      band: ReadinessBand.developing,
      recentAccuracyComponent: 0.6,
      domainMasteryComponent: 0.5,
      mockPerformanceComponent: 0,
      repeatedMasteryComponent: 0.4,
      coverageComponent: 0.3,
      evidenceConfidence: 0.7,
      uniqueQuestionsAnswered: 40,
    );
    await writer.writeLatestReadinessSnapshot(snapshot);

    // A brand new instance, backed by the same platform singleton — the
    // same as a fresh app launch reading what a previous launch wrote.
    final reader = SharedPreferencesBootstrapLocalStore();

    expect(await reader.readSelectedExamId(), 'danb_rhs');
    expect(await reader.readOnboardingComplete(), isTrue);
    expect(await reader.readThemePreference(), ThemePreference.dark);
    final Entitlement? readEntitlement = await reader.readEntitlementSnapshot();
    expect(readEntitlement?.tier, EntitlementTier.premium);
    expect(readEntitlement?.productId, 'monthly');
    final ReadinessSnapshot? readSnapshot =
        await reader.readLatestReadinessSnapshot('danb_rhs');
    expect(readSnapshot?.id, 'snap-1');
    expect(readSnapshot?.overallScore, 62);
  });

  group('a corrupt cache entry is discarded, not fabricated as valid data', () {
    test('an unparsable entitlement JSON string returns null, not a throw',
        () async {
      final SharedPreferencesAsync raw = SharedPreferencesAsync();
      await raw.setString(
          'bootstrap.entitlement_snapshot', 'not valid json{{{');
      final store = SharedPreferencesBootstrapLocalStore();

      expect(await store.readEntitlementSnapshot(), isNull);
    });

    test('an entitlement JSON missing required fields returns null', () async {
      final SharedPreferencesAsync raw = SharedPreferencesAsync();
      await raw.setString('bootstrap.entitlement_snapshot', '{"tier": 5}');
      final store = SharedPreferencesBootstrapLocalStore();

      expect(await store.readEntitlementSnapshot(), isNull);
    });

    test('an unrecognized theme preference value returns null, not a throw',
        () async {
      final SharedPreferencesAsync raw = SharedPreferencesAsync();
      await raw.setString('bootstrap.theme_preference', 'ultra_dark_mode');
      final store = SharedPreferencesBootstrapLocalStore();

      expect(await store.readThemePreference(), isNull);
    });

    test('an unparsable readiness snapshot JSON returns null for that exam',
        () async {
      final SharedPreferencesAsync raw = SharedPreferencesAsync();
      await raw.setString('bootstrap.readiness_snapshot.danb_rhs', '{not json');
      final store = SharedPreferencesBootstrapLocalStore();

      expect(await store.readLatestReadinessSnapshot('danb_rhs'), isNull);
    });

    test('a corrupt entry for one key does not affect any other key', () async {
      final SharedPreferencesAsync raw = SharedPreferencesAsync();
      await raw.setString('bootstrap.entitlement_snapshot', 'garbage');
      final store = SharedPreferencesBootstrapLocalStore();
      await store.writeSelectedExamId('danb_rhs');
      await store.writeOnboardingComplete(true);

      expect(await store.readEntitlementSnapshot(), isNull);
      expect(await store.readSelectedExamId(), 'danb_rhs');
      expect(await store.readOnboardingComplete(), isTrue);
    });
  });
}
