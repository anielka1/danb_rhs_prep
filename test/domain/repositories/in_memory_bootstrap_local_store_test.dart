import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/readiness_band.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';

void main() {
  test('every key starts absent (null) on a fresh store', () async {
    final store = InMemoryBootstrapLocalStore();

    expect(await store.readSelectedExamId(), isNull);
    expect(await store.readOnboardingComplete(), isNull);
    expect(await store.readThemePreference(), isNull);
    expect(await store.readEntitlementSnapshot(), isNull);
    expect(await store.readLatestReadinessSnapshot('danb_rhs'), isNull);
  });

  test('constructor arguments pre-seed each key synchronously', () async {
    final snapshot = ReadinessSnapshot(
      id: 'snap-1',
      examId: 'danb_rhs',
      calculatedAt: DateTime.utc(2026, 1, 1),
      overallScore: 50,
      band: ReadinessBand.developing,
      recentAccuracyComponent: 0.5,
      domainMasteryComponent: 0.5,
      mockPerformanceComponent: 0,
      repeatedMasteryComponent: 0.5,
      coverageComponent: 0.5,
      evidenceConfidence: 0.5,
      uniqueQuestionsAnswered: 20,
    );
    final entitlement =
        Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1));
    final store = InMemoryBootstrapLocalStore(
      selectedExamId: 'danb_rhs',
      onboardingComplete: true,
      themePreference: ThemePreference.dark,
      entitlement: entitlement,
      readinessSnapshot: snapshot,
    );

    expect(await store.readSelectedExamId(), 'danb_rhs');
    expect(await store.readOnboardingComplete(), isTrue);
    expect(await store.readThemePreference(), ThemePreference.dark);
    expect(await store.readEntitlementSnapshot(), entitlement);
    expect(await store.readLatestReadinessSnapshot('danb_rhs'), snapshot);
  });

  test('each key round-trips independently through write then read', () async {
    final store = InMemoryBootstrapLocalStore();

    await store.writeSelectedExamId('danb_rhs');
    await store.writeOnboardingComplete(true);
    await store.writeThemePreference(ThemePreference.light);
    final entitlement = Entitlement(
      tier: EntitlementTier.premium,
      source: EntitlementSource.purchase,
      lastVerifiedAt: DateTime.utc(2026, 1, 1),
      productId: 'monthly',
    );
    await store.writeEntitlementSnapshot(entitlement);
    final snapshot = ReadinessSnapshot(
      id: 'snap-2',
      examId: 'danb_rhs',
      calculatedAt: DateTime.utc(2026, 1, 2),
      overallScore: 70,
      band: ReadinessBand.examReady,
      recentAccuracyComponent: 0.7,
      domainMasteryComponent: 0.7,
      mockPerformanceComponent: 0.7,
      repeatedMasteryComponent: 0.7,
      coverageComponent: 0.7,
      evidenceConfidence: 0.9,
      uniqueQuestionsAnswered: 80,
    );
    await store.writeLatestReadinessSnapshot(snapshot);

    expect(await store.readSelectedExamId(), 'danb_rhs');
    expect(await store.readOnboardingComplete(), isTrue);
    expect(await store.readThemePreference(), ThemePreference.light);
    expect(await store.readEntitlementSnapshot(), entitlement);
    expect(await store.readLatestReadinessSnapshot('danb_rhs'), snapshot);
  });

  test('readiness snapshots are keyed per exam ID', () async {
    final store = InMemoryBootstrapLocalStore();
    final rhsSnapshot = ReadinessSnapshot(
      id: 'rhs-snap',
      examId: 'danb_rhs',
      calculatedAt: DateTime.utc(2026, 1, 1),
      overallScore: 50,
      band: ReadinessBand.developing,
      recentAccuracyComponent: 0.5,
      domainMasteryComponent: 0.5,
      mockPerformanceComponent: 0.5,
      repeatedMasteryComponent: 0.5,
      coverageComponent: 0.5,
      evidenceConfidence: 0.5,
      uniqueQuestionsAnswered: 10,
    );
    await store.writeLatestReadinessSnapshot(rhsSnapshot);

    expect(await store.readLatestReadinessSnapshot('danb_rhs'), rhsSnapshot);
    expect(await store.readLatestReadinessSnapshot('other_exam'), isNull);
  });
}
