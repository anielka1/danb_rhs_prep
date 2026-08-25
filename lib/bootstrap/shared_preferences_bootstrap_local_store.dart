import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/entitlement.dart';
import '../domain/models/exam_date_precision.dart';
import '../domain/models/exam_date_selection.dart';
import '../domain/models/experience_level.dart';
import '../domain/models/experience_level_codec.dart';
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
  static const String _examDateSelectionKey = 'bootstrap.exam_date_selection';
  static const String _experienceLevelKey = 'bootstrap.experience_level';

  /// The only `version` value this store currently knows how to read for
  /// the experience-level entry — an entry written with any other value
  /// (including a missing one) is treated as unsupported/corrupt.
  static const int _experienceLevelVersion = 1;

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

  /// The only `version` value this store currently knows how to read —
  /// an entry written with any other value (including a missing one) is
  /// treated as unsupported/corrupt, not guessed at or migrated.
  static const int _examDateSelectionVersion = 1;

  @override
  Future<ExamDateSelection?> readExamDateSelection() async {
    final String? raw = await _preferences.getString(_examDateSelectionKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;

      if (json['version'] != _examDateSelectionVersion) return null;

      final String? precisionName = json['precision'] as String?;
      if (precisionName == null) return null;
      final ExamDatePrecision precision = ExamDatePrecision.values
          .firstWhere((value) => value.name == precisionName);

      final Object? yearRaw = json['year'];
      final Object? monthRaw = json['month'];
      final Object? dayRaw = json['day'];

      DateTime? date;
      if (yearRaw != null || monthRaw != null || dayRaw != null) {
        // Any date component present means all three must be present and
        // must be genuine integers, not doubles/strings/etc — a
        // partially- or wrongly-typed date is corrupt, not usable.
        if (yearRaw is! int || monthRaw is! int || dayRaw is! int) {
          return null;
        }
        final DateTime constructed = DateTime(yearRaw, monthRaw, dayRaw);
        // Dart's DateTime constructor silently *normalizes* impossible
        // calendar components — DateTime(2026, 2, 31) becomes a March
        // date — instead of throwing. Round-tripping the constructed
        // value's own fields back against what was stored is how that
        // silent normalization is caught: any mismatch means the stored
        // date never described a real calendar day, and is rejected
        // rather than rolled forward to whatever Dart normalized it to.
        if (constructed.year != yearRaw ||
            constructed.month != monthRaw ||
            constructed.day != dayRaw) {
          return null;
        }
        date = constructed;
      }

      // The [ExamDateSelection] constructor itself enforces "date is
      // non-null exactly when precision is exact/approximate" — an
      // unscheduled value with a date, or an exact/approximate value
      // missing one, throws here and is caught below, discarded exactly
      // like any other corrupt entry rather than fabricated as valid.
      return ExamDateSelection(precision: precision, date: date);
    } on Object {
      // A corrupt, unrecognized, or structurally-invalid cache entry is
      // discarded, not treated as valid user data.
      return null;
    }
  }

  @override
  Future<void> writeExamDateSelection(ExamDateSelection selection) {
    final DateTime? date = selection.date;
    final json = <String, Object?>{
      'version': _examDateSelectionVersion,
      'precision': selection.precision.name,
      'year': date?.year,
      'month': date?.month,
      'day': date?.day,
    };
    return _preferences.setString(_examDateSelectionKey, jsonEncode(json));
  }

  @override
  Future<ExperienceLevel?> readExperienceLevel() async {
    final String? raw = await _preferences.getString(_experienceLevelKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;
      if (json['version'] != _experienceLevelVersion) return null;
      final String? value = json['value'] as String?;
      if (value == null) return null;
      // An unrecognized stored value (e.g. from a future app version)
      // returns null here too, treated the same as absent.
      return experienceLevelFromStorageValue(value);
    } on Object {
      // A corrupt or unrecognized cache entry is discarded, not treated
      // as valid user data.
      return null;
    }
  }

  @override
  Future<void> writeExperienceLevel(ExperienceLevel level) {
    // Explicit stable string serialization via experienceLevelToStorageValue
    // — never `.name`/`.index` — see that function's doc comment for why.
    final json = <String, Object?>{
      'version': _experienceLevelVersion,
      'value': experienceLevelToStorageValue(level),
    };
    return _preferences.setString(_experienceLevelKey, jsonEncode(json));
  }
}
