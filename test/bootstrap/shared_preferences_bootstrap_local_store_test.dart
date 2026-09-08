import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:danb_rhs_prep/bootstrap/shared_preferences_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/experience_level.dart';
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

  for (final precision in [
    ExamDatePrecision.withinMonth,
    ExamDatePrecision.oneToThreeMonths,
    ExamDatePrecision.later,
  ]) {
    test('$precision survives reopening storage without inventing a date',
        () async {
      final selection = ExamDateSelection(precision: precision);
      await SharedPreferencesBootstrapLocalStore()
          .writeExamDateSelection(selection);
      final restored =
          await SharedPreferencesBootstrapLocalStore().readExamDateSelection();
      expect(restored, selection);
      expect(restored!.date, isNull);
    });
  }

  test('every key starts absent on a fresh store', () async {
    final store = SharedPreferencesBootstrapLocalStore();

    expect(await store.readSelectedExamId(), isNull);
    expect(await store.readOnboardingComplete(), isNull);
    expect(await store.readThemePreference(), isNull);
    expect(await store.readEntitlementSnapshot(), isNull);
    expect(await store.readLatestReadinessSnapshot('danb_rhs'), isNull);
    expect(await store.readExamDateSelection(), isNull);
    expect(await store.readExperienceLevel(), isNull);
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

  group('exam date selection', () {
    test('an exact selection round-trips through a fresh store instance',
        () async {
      final writer = SharedPreferencesBootstrapLocalStore();
      final selection = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 12));
      await writer.writeExamDateSelection(selection);

      final reader = SharedPreferencesBootstrapLocalStore();
      expect(await reader.readExamDateSelection(), selection);
    });

    test(
        'an approximate selection round-trips through a fresh store '
        'instance', () async {
      final writer = SharedPreferencesBootstrapLocalStore();
      final selection = ExamDateSelection(
          precision: ExamDatePrecision.approximate, date: DateTime(2026, 6, 1));
      await writer.writeExamDateSelection(selection);

      final reader = SharedPreferencesBootstrapLocalStore();
      expect(await reader.readExamDateSelection(), selection);
    });

    test(
        'an unscheduled selection round-trips through a fresh store '
        'instance', () async {
      final writer = SharedPreferencesBootstrapLocalStore();
      final selection =
          ExamDateSelection(precision: ExamDatePrecision.notScheduled);
      await writer.writeExamDateSelection(selection);

      final reader = SharedPreferencesBootstrapLocalStore();
      expect(await reader.readExamDateSelection(), selection);
    });

    test(
        'precision and date are stored together as one atomic JSON value, '
        'not unrelated keys that could drift apart', () async {
      final store = SharedPreferencesBootstrapLocalStore();
      await store.writeExamDateSelection(ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 12)));

      final SharedPreferencesAsync raw = SharedPreferencesAsync();
      final String? stored =
          await raw.getString('bootstrap.exam_date_selection');
      expect(stored, isNotNull);
      final Map<String, Object?> json =
          jsonDecode(stored!) as Map<String, Object?>;
      expect(json['precision'], 'exact');
      expect(json['year'], 2026);
      expect(json['month'], 3);
      expect(json['day'], 12);
    });

    group(
        'a corrupt or structurally-invalid cache entry is discarded, not '
        'fabricated as valid data', () {
      test('unparsable JSON returns null, not a throw', () async {
        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        await raw.setString('bootstrap.exam_date_selection', 'not json{{{');
        final store = SharedPreferencesBootstrapLocalStore();

        expect(await store.readExamDateSelection(), isNull);
      });

      test('an unknown precision value returns null', () async {
        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        await raw.setString(
          'bootstrap.exam_date_selection',
          jsonEncode({
            'version': 1,
            'precision': 'someday',
            'year': 2026,
            'month': 3,
            'day': 12
          }),
        );
        final store = SharedPreferencesBootstrapLocalStore();

        expect(await store.readExamDateSelection(), isNull);
      });

      test(
          'an exact/approximate entry missing the required date returns '
          'null', () async {
        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        await raw.setString(
          'bootstrap.exam_date_selection',
          jsonEncode({'version': 1, 'precision': 'exact'}),
        );
        final store = SharedPreferencesBootstrapLocalStore();

        expect(await store.readExamDateSelection(), isNull);
      });

      test('an unscheduled entry that also carries a date is rejected',
          () async {
        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        await raw.setString(
          'bootstrap.exam_date_selection',
          jsonEncode({
            'version': 1,
            'precision': 'notScheduled',
            'year': 2026,
            'month': 3,
            'day': 12,
          }),
        );
        final store = SharedPreferencesBootstrapLocalStore();

        expect(await store.readExamDateSelection(), isNull);
      });

      test('a corrupt exam-date entry does not affect any other key', () async {
        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        await raw.setString('bootstrap.exam_date_selection', 'garbage');
        final store = SharedPreferencesBootstrapLocalStore();
        await store.writeSelectedExamId('danb_rhs');
        await store.writeOnboardingComplete(true);

        expect(await store.readExamDateSelection(), isNull);
        expect(await store.readSelectedExamId(), 'danb_rhs');
        expect(await store.readOnboardingComplete(), isTrue);
      });
    });

    group(
        'an impossible calendar date is rejected, not silently normalized '
        'forward (Dart\'s DateTime constructor would otherwise roll '
        'DateTime(2026, 2, 31) forward into March)', () {
      Future<void> expectRejected(Map<String, Object?> json) async {
        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        await raw.setString('bootstrap.exam_date_selection', jsonEncode(json));
        final store = SharedPreferencesBootstrapLocalStore();

        expect(await store.readExamDateSelection(), isNull);
      }

      test('month 0 is rejected', () async {
        await expectRejected({
          'version': 1,
          'precision': 'exact',
          'year': 2026,
          'month': 0,
          'day': 15,
        });
      });

      test('month 13 is rejected', () async {
        await expectRejected({
          'version': 1,
          'precision': 'exact',
          'year': 2026,
          'month': 13,
          'day': 15,
        });
      });

      test('day 0 is rejected', () async {
        await expectRejected({
          'version': 1,
          'precision': 'exact',
          'year': 2026,
          'month': 3,
          'day': 0,
        });
      });

      test('day 32 is rejected', () async {
        await expectRejected({
          'version': 1,
          'precision': 'exact',
          'year': 2026,
          'month': 1,
          'day': 32,
        });
      });

      test('April 31 (April only has 30 days) is rejected', () async {
        await expectRejected({
          'version': 1,
          'precision': 'exact',
          'year': 2026,
          'month': 4,
          'day': 31,
        });
      });

      test('February 30 is rejected', () async {
        await expectRejected({
          'version': 1,
          'precision': 'exact',
          'year': 2026,
          'month': 2,
          'day': 30,
        });
      });

      test('February 29 in a non-leap year (2026) is rejected', () async {
        await expectRejected({
          'version': 1,
          'precision': 'exact',
          'year': 2026,
          'month': 2,
          'day': 29,
        });
      });

      test('February 29 in a leap year (2028) succeeds', () async {
        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        await raw.setString(
          'bootstrap.exam_date_selection',
          jsonEncode({
            'version': 1,
            'precision': 'exact',
            'year': 2028,
            'month': 2,
            'day': 29,
          }),
        );
        final store = SharedPreferencesBootstrapLocalStore();

        final ExamDateSelection? result = await store.readExamDateSelection();
        expect(result, isNotNull);
        expect(result!.date, DateTime(2028, 2, 29));
      });

      test('a non-integer (double) year is rejected', () async {
        await expectRejected({
          'version': 1,
          'precision': 'exact',
          'year': 2026.5,
          'month': 3,
          'day': 15,
        });
      });

      test('a non-integer (string) month is rejected', () async {
        await expectRejected({
          'version': 1,
          'precision': 'exact',
          'year': 2026,
          'month': 'march',
          'day': 15,
        });
      });

      test('a non-integer (string) day is rejected', () async {
        await expectRejected({
          'version': 1,
          'precision': 'exact',
          'year': 2026,
          'month': 3,
          'day': '15',
        });
      });

      test('an unsupported JSON version is rejected', () async {
        await expectRejected({
          'version': 2,
          'precision': 'exact',
          'year': 2026,
          'month': 3,
          'day': 15,
        });
      });

      test('a missing JSON version is rejected', () async {
        await expectRejected({
          'precision': 'exact',
          'year': 2026,
          'month': 3,
          'day': 15,
        });
      });
    });
  });

  group('experience level', () {
    test('all three values round-trip through a fresh store instance',
        () async {
      for (final level in ExperienceLevel.values) {
        final writer = SharedPreferencesBootstrapLocalStore();
        await writer.writeExperienceLevel(level);

        final reader = SharedPreferencesBootstrapLocalStore();
        expect(await reader.readExperienceLevel(), level);
      }
    });

    test(
        'each value is serialized via the exact expected explicit stable '
        'string, never the enum index or a derived name', () async {
      final Map<ExperienceLevel, String> expectedStoredValues = {
        ExperienceLevel.justStarting: 'justStarting',
        ExperienceLevel.studyingAlready: 'studyingAlready',
        ExperienceLevel.retakingExam: 'retakingExam',
      };

      for (final entry in expectedStoredValues.entries) {
        final store = SharedPreferencesBootstrapLocalStore();
        await store.writeExperienceLevel(entry.key);

        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        final String? stored =
            await raw.getString('bootstrap.experience_level');
        expect(stored, isNotNull);
        final Map<String, Object?> json =
            jsonDecode(stored!) as Map<String, Object?>;
        expect(json['value'], entry.value,
            reason: '${entry.key} must serialize to exactly '
                '"${entry.value}"');
      }
    });

    group(
        'a corrupt or unsupported cache entry is discarded, not '
        'fabricated as valid data', () {
      test('unparsable JSON returns null, not a throw', () async {
        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        await raw.setString('bootstrap.experience_level', 'not json{{{');
        final store = SharedPreferencesBootstrapLocalStore();

        expect(await store.readExperienceLevel(), isNull);
      });

      test('an unknown value name returns null', () async {
        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        await raw.setString(
          'bootstrap.experience_level',
          jsonEncode({'version': 1, 'value': 'expertAlready'}),
        );
        final store = SharedPreferencesBootstrapLocalStore();

        expect(await store.readExperienceLevel(), isNull);
      });

      test('an unsupported JSON version is rejected', () async {
        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        await raw.setString(
          'bootstrap.experience_level',
          jsonEncode({'version': 2, 'value': 'justStarting'}),
        );
        final store = SharedPreferencesBootstrapLocalStore();

        expect(await store.readExperienceLevel(), isNull);
      });

      test('a missing JSON version is rejected', () async {
        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        await raw.setString(
          'bootstrap.experience_level',
          jsonEncode({'value': 'justStarting'}),
        );
        final store = SharedPreferencesBootstrapLocalStore();

        expect(await store.readExperienceLevel(), isNull);
      });

      test(
          'a corrupt experience-level entry does not affect exam date, '
          'onboarding, entitlement or settings', () async {
        final SharedPreferencesAsync raw = SharedPreferencesAsync();
        await raw.setString('bootstrap.experience_level', 'garbage');
        final store = SharedPreferencesBootstrapLocalStore();
        await store.writeSelectedExamId('danb_rhs');
        await store.writeOnboardingComplete(true);
        await store.writeThemePreference(ThemePreference.dark);
        final selection = ExamDateSelection(
            precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 1));
        await store.writeExamDateSelection(selection);
        final entitlement =
            Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1));
        await store.writeEntitlementSnapshot(entitlement);

        expect(await store.readExperienceLevel(), isNull);
        expect(await store.readSelectedExamId(), 'danb_rhs');
        expect(await store.readOnboardingComplete(), isTrue);
        expect(await store.readThemePreference(), ThemePreference.dark);
        expect(await store.readExamDateSelection(), selection);
        final Entitlement? readEntitlement =
            await store.readEntitlementSnapshot();
        expect(readEntitlement?.tier, entitlement.tier);
      });
    });
  });
}
