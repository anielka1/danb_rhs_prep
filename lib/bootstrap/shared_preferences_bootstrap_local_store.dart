import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/entitlement.dart';
import '../domain/models/readiness_snapshot.dart';
import '../domain/models/readiness_band.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/bootstrap_local_store.dart';

/// Production [BootstrapLocalStore], backed by `shared_preferences` — a
/// plain local key-value store, not a database. This is deliberately the
/// smallest persistence mechanism that satisfies Section 3.1's narrow
/// needs (a handful of small, independent values); it is not a general
/// local-persistence layer and must not grow into one. Structured,
/// relational, or append-only data (answer attempts, practice sessions,
/// full question state, mock attempts) belongs in Phase 5's
/// Drift/SQLite-backed repositories, not here.
///
/// Every read tolerates a missing or corrupt value for its own key by
/// returning null (never throwing, never crashing startup) and never
/// touches any other key while doing so — a corrupt entitlement snapshot,
/// for instance, cannot affect the selected exam ID or onboarding flag.
class SharedPreferencesBootstrapLocalStore implements BootstrapLocalStore {
  SharedPreferencesBootstrapLocalStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static const String _selectedExamIdKey = 'bootstrap.selected_exam_id';
  static const String _onboardingCompleteKey = 'bootstrap.onboarding_complete';
  static const String _themePreferenceKey = 'bootstrap.theme_preference';
  static const String _entitlementKey = 'bootstrap.entitlement_snapshot';
  static const String _readinessKeyPrefix = 'bootstrap.readiness_snapshot.';

  @override
  Future<String?> readSelectedExamId() async {
    final String? value = await _preferences.getString(_selectedExamIdKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  @override
  Future<void> writeSelectedExamId(String examId) {
    return _preferences.setString(_selectedExamIdKey, examId);
  }

  @override
  Future<bool?> readOnboardingComplete() {
    return _preferences.getBool(_onboardingCompleteKey);
  }

  @override
  Future<void> writeOnboardingComplete(bool complete) {
    return _preferences.setBool(_onboardingCompleteKey, complete);
  }

  @override
  Future<ThemePreference?> readThemePreference() async {
    final String? name = await _preferences.getString(_themePreferenceKey);
    if (name == null) return null;
    for (final preference in ThemePreference.values) {
      if (preference.name == name) return preference;
    }
    // An unrecognized stored value (e.g. from a future app version) is
    // treated the same as absent, rather than thrown — the caller falls
    // back to its own default.
    return null;
  }

  @override
  Future<void> writeThemePreference(ThemePreference preference) {
    return _preferences.setString(_themePreferenceKey, preference.name);
  }

  @override
  Future<Entitlement?> readEntitlementSnapshot() async {
    final String? raw = await _preferences.getString(_entitlementKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;
      final String? tierName = json['tier'] as String?;
      final String? sourceName = json['source'] as String?;
      final String? lastVerifiedAtRaw = json['lastVerifiedAt'] as String?;
      final DateTime? lastVerifiedAt = lastVerifiedAtRaw == null
          ? null
          : DateTime.tryParse(lastVerifiedAtRaw);
      if (tierName == null || sourceName == null || lastVerifiedAt == null) {
        return null;
      }
      final EntitlementTier tier =
          EntitlementTier.values.firstWhere((value) => value.name == tierName);
      final EntitlementSource source = EntitlementSource.values
          .firstWhere((value) => value.name == sourceName);
      final String? expiresAtRaw = json['expiresAt'] as String?;
      return Entitlement(
        tier: tier,
        source: source,
        lastVerifiedAt: lastVerifiedAt,
        expiresAt:
            expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw),
        productId: json['productId'] as String?,
      );
    } on Object {
      // A corrupt or unrecognized cache entry is discarded, not treated
      // as valid user data — the caller falls back to its own default
      // (a free entitlement).
      return null;
    }
  }

  @override
  Future<void> writeEntitlementSnapshot(Entitlement entitlement) {
    final json = <String, Object?>{
      'tier': entitlement.tier.name,
      'source': entitlement.source.name,
      'lastVerifiedAt': entitlement.lastVerifiedAt.toIso8601String(),
      'expiresAt': entitlement.expiresAt?.toIso8601String(),
      'productId': entitlement.productId,
    };
    return _preferences.setString(_entitlementKey, jsonEncode(json));
  }

  @override
  Future<ReadinessSnapshot?> readLatestReadinessSnapshot(
    String examId,
  ) async {
    final String? raw =
        await _preferences.getString('$_readinessKeyPrefix$examId');
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;
      final String? calculatedAtRaw = json['calculatedAt'] as String?;
      final DateTime? calculatedAt =
          calculatedAtRaw == null ? null : DateTime.tryParse(calculatedAtRaw);
      final String? bandName = json['band'] as String?;
      if (calculatedAt == null || bandName == null) return null;
      final ReadinessBand band =
          ReadinessBand.values.firstWhere((value) => value.name == bandName);
      return ReadinessSnapshot(
        id: json['id'] as String? ?? '',
        examId: examId,
        calculatedAt: calculatedAt,
        overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0,
        band: band,
        recentAccuracyComponent:
            (json['recentAccuracyComponent'] as num?)?.toDouble() ?? 0,
        domainMasteryComponent:
            (json['domainMasteryComponent'] as num?)?.toDouble() ?? 0,
        mockPerformanceComponent:
            (json['mockPerformanceComponent'] as num?)?.toDouble() ?? 0,
        repeatedMasteryComponent:
            (json['repeatedMasteryComponent'] as num?)?.toDouble() ?? 0,
        coverageComponent: (json['coverageComponent'] as num?)?.toDouble() ?? 0,
        evidenceConfidence:
            (json['evidenceConfidence'] as num?)?.toDouble() ?? 0,
        uniqueQuestionsAnswered:
            (json['uniqueQuestionsAnswered'] as num?)?.toInt() ?? 0,
      );
    } on Object {
      // Discarded, not fabricated as valid progress data.
      return null;
    }
  }

  @override
  Future<void> writeLatestReadinessSnapshot(ReadinessSnapshot snapshot) {
    final json = <String, Object?>{
      'id': snapshot.id,
      'calculatedAt': snapshot.calculatedAt.toIso8601String(),
      'overallScore': snapshot.overallScore,
      'band': snapshot.band.name,
      'recentAccuracyComponent': snapshot.recentAccuracyComponent,
      'domainMasteryComponent': snapshot.domainMasteryComponent,
      'mockPerformanceComponent': snapshot.mockPerformanceComponent,
      'repeatedMasteryComponent': snapshot.repeatedMasteryComponent,
      'coverageComponent': snapshot.coverageComponent,
      'evidenceConfidence': snapshot.evidenceConfidence,
      'uniqueQuestionsAnswered': snapshot.uniqueQuestionsAnswered,
    };
    return _preferences.setString(
      '$_readinessKeyPrefix${snapshot.examId}',
      jsonEncode(json),
    );
  }
}
