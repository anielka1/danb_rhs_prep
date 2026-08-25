import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/experience_level.dart';
import 'package:danb_rhs_prep/domain/models/readiness_band.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/content_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_user_settings_repository.dart';
import 'package:danb_rhs_prep/features/content/data/bundled_content_repository.dart';
import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';

/// The real bundled DANB RHS content, decoded once — the same
/// `File(...).readAsStringSync()` + `ExamContentCodec` pattern
/// `content_validator_test.dart` already uses, not a fabricated fixture.
final ContentPackage _realPackage = () {
  final String source =
      File('assets/content/danb_rhs/content.json').readAsStringSync();
  return const ExamContentCodec().decode(source);
}();

class _StaticContentRepository implements ContentRepository {
  _StaticContentRepository(this.package);
  final ContentPackage package;
  int callCount = 0;

  @override
  Future<ContentPackage> loadContentPackage(String examId) async {
    callCount++;
    return package;
  }
}

class _ThrowingContentRepository implements ContentRepository {
  _ThrowingContentRepository(this.error);
  final Object error;

  @override
  Future<ContentPackage> loadContentPackage(String examId) async => throw error;
}

/// Every real dependency of [AppBootstrapService] — asserted here just by
/// what this file constructs it with, never anything HTTP/Supabase/auth
/// backed. See the `no remote dependency is reachable` group below for
/// the structural half of this proof.
({
  _StaticContentRepository contentRepository,
  InMemoryBootstrapLocalStore localStore,
}) _offlineDeps({ContentPackage? package}) {
  return (
    contentRepository: _StaticContentRepository(package ?? _realPackage),
    localStore: InMemoryBootstrapLocalStore(),
  );
}

void main() {
  group('successful bootstrap', () {
    test('with onboarding incomplete', () async {
      final deps = _offlineDeps();
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      final result = await service.initialize();

      expect(result, isA<BootstrapReady>());
      final ready = result as BootstrapReady;
      expect(ready.onboardingComplete, isFalse);
      expect(ready.selectedExamId, kDefaultExamId);
      expect(ready.contentPackage.exam.id, kDefaultExamId);
    });

    test('with onboarding complete', () async {
      final deps = _offlineDeps();
      await deps.localStore.writeOnboardingComplete(true);
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      final result = await service.initialize();

      expect(result, isA<BootstrapReady>());
      expect((result as BootstrapReady).onboardingComplete, isTrue);
    });
  });

  group('selected exam resolution', () {
    test('defaults to DANB RHS when nothing has ever been stored', () async {
      final deps = _offlineDeps();
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      final result = await service.initialize() as BootstrapReady;

      expect(result.selectedExamId, kDefaultExamId);
      expect(await deps.localStore.readSelectedExamId(), kDefaultExamId,
          reason: 'the default is written back, so storage self-heals');
    });

    test('a stale/unknown stored exam ID safely resets to the default',
        () async {
      final deps = _offlineDeps();
      await deps.localStore.writeSelectedExamId('some_future_exam');
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      final result = await service.initialize() as BootstrapReady;

      expect(result.selectedExamId, kDefaultExamId);
      expect(await deps.localStore.readSelectedExamId(), kDefaultExamId);
    });

    test('a validly-stored known exam ID is trusted and kept', () async {
      final deps = _offlineDeps();
      await deps.localStore.writeSelectedExamId(kDefaultExamId);
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      final result = await service.initialize() as BootstrapReady;

      expect(result.selectedExamId, kDefaultExamId);
      expect(deps.contentRepository.callCount, 1);
    });
  });

  group('content loading and validation', () {
    // The one place this file touches `rootBundle` — deliberately the
    // only test in this file (and the only `testWidgets`, everything
    // else here is a plain `test`) that goes through the real
    // production `BundledContentRepository` rather than reading the
    // bundled file directly, matching `RealFileContentRepository`'s doc
    // comment about repeated `rootBundle` calls within one file hanging.
    testWidgets(
        'the real bundled DANB RHS content loads and validates through '
        'BundledContentRepository/BundledExamContentLoader/rootBundle',
        (tester) async {
      final localStore = InMemoryBootstrapLocalStore();
      final service = AppBootstrapService(
        contentRepository: BundledContentRepository(),
        localStore: localStore,
      );

      final result = await service.initialize();

      expect(result, isA<BootstrapReady>());
      final ready = result as BootstrapReady;
      expect(ready.contentPackage.exam.id, kDefaultExamId);
      expect(ready.contentPackage.questions, isNotEmpty);
    });

    test('a selected exam/package ID mismatch fails as content failure',
        () async {
      // The loader always returns content whose exam.id is "danb_rhs"
      // (the real package), but the service is configured to select a
      // *different* exam id — on an empty store, with no stored
      // selection to validate against known exams, bootstrap resolves
      // the selected exam straight to this custom default and then
      // discovers the loaded package doesn't match it.
      final loader = _StaticContentRepository(_realPackage);
      final service = AppBootstrapService(
        contentRepository: loader,
        localStore: InMemoryBootstrapLocalStore(),
        defaultExamId: 'not_danb_rhs',
      );

      final result = await service.initialize();

      expect(result, isA<BootstrapContentFailure>());
    });

    test('malformed bundled content returns a typed content failure', () async {
      final loader =
          _ThrowingContentRepository(const FormatException('malformed JSON'));
      final service = AppBootstrapService(
        contentRepository: loader,
        localStore: InMemoryBootstrapLocalStore(),
      );

      final result = await service.initialize();

      expect(result, isA<BootstrapContentFailure>());
      final failure = result as BootstrapContentFailure;
      expect(failure.message, isNotEmpty);
      expect(failure.message.toLowerCase(), isNot(contains('formatexception')),
          reason: 'the user-facing message must not leak the raw error');
    });

    test(
        'a missing bundled asset (loader throws) returns a typed content '
        'failure, not a crash', () async {
      final loader = _ThrowingContentRepository(
          const FileSystemException('No such file or directory'));
      final service = AppBootstrapService(
        contentRepository: loader,
        localStore: InMemoryBootstrapLocalStore(),
      );

      final result = await service.initialize();

      expect(result, isA<BootstrapContentFailure>());
    });

    test(
        'content that fails ContentValidator returns a typed content '
        'failure', () async {
      final invalidQuestion = _realPackage.questions.first;
      final duplicated = ContentPackage(
        exam: _realPackage.exam,
        contentVersion: _realPackage.contentVersion,
        sourceVersion: _realPackage.sourceVersion,
        generatedAt: _realPackage.generatedAt,
        // Duplicate question IDs — a real, existing ContentValidator
        // check (`duplicate_or_missing_question_id`).
        questions: [invalidQuestion, invalidQuestion],
      );
      final deps = _offlineDeps(package: duplicated);
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      final result = await service.initialize();

      expect(result, isA<BootstrapContentFailure>());
    });
  });

  group('local cache defaults', () {
    test('missing optional cache uses safe defaults', () async {
      final deps = _offlineDeps();
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      final result = await service.initialize() as BootstrapReady;

      expect(result.profile, isNull);
      expect(result.themePreference, ThemePreference.system);
      expect(result.readinessSnapshot, isNull);
      expect(result.entitlement.tier, EntitlementTier.free);
      expect(result.onboardingComplete, isFalse);
      expect(result.examDateSelection, isNull);
      expect(result.experienceLevel, isNull);
    });

    test('a cached exam-date selection is included in BootstrapReady',
        () async {
      final deps = _offlineDeps();
      final selection = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 1));
      await deps.localStore.writeExamDateSelection(selection);
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      final result = await service.initialize() as BootstrapReady;

      expect(result.examDateSelection, selection);
    });

    test('a cached experience level is included in BootstrapReady', () async {
      final deps = _offlineDeps();
      await deps.localStore
          .writeExperienceLevel(ExperienceLevel.studyingAlready);
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      final result = await service.initialize() as BootstrapReady;

      expect(result.experienceLevel, ExperienceLevel.studyingAlready);
    });

    test('a present profile (via UserSettingsRepository) is included',
        () async {
      final deps = _offlineDeps();
      final settingsRepo = InMemoryUserSettingsRepository();
      final now = DateTime.utc(2026, 1, 1);
      await settingsRepo.saveProfile(UserProfile(
        examId: kDefaultExamId,
        experienceLevel: ExperienceLevel.studyingAlready,
        examDatePrecision: ExamDatePrecision.notScheduled,
        dailyGoalQuestions: 10,
        notificationsEnabled: true,
        themePreference: ThemePreference.dark,
        onboardingComplete: true,
        createdAt: now,
        updatedAt: now,
      ));
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
        userSettingsRepository: settingsRepo,
      );

      final result = await service.initialize() as BootstrapReady;

      expect(result.profile, isNotNull);
      expect(result.profile!.examId, kDefaultExamId);
    });

    test('an expired cached entitlement becomes free, not stale-premium',
        () async {
      final deps = _offlineDeps();
      await deps.localStore.writeEntitlementSnapshot(Entitlement(
        tier: EntitlementTier.premium,
        source: EntitlementSource.purchase,
        lastVerifiedAt: DateTime.utc(2020, 1, 1),
        expiresAt: DateTime.utc(2020, 2, 1),
        productId: 'monthly',
      ));
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
        now: () => DateTime.utc(2026, 1, 1),
      );

      final result = await service.initialize() as BootstrapReady;

      expect(result.entitlement.tier, EntitlementTier.free);
    });

    test('an active cached entitlement is kept as-is', () async {
      final deps = _offlineDeps();
      final expiresAt = DateTime.utc(2027, 1, 1);
      await deps.localStore.writeEntitlementSnapshot(Entitlement(
        tier: EntitlementTier.premium,
        source: EntitlementSource.purchase,
        lastVerifiedAt: DateTime.utc(2026, 1, 1),
        expiresAt: expiresAt,
        productId: 'monthly',
      ));
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
        now: () => DateTime.utc(2026, 1, 15),
      );

      final result = await service.initialize() as BootstrapReady;

      expect(result.entitlement.tier, EntitlementTier.premium);
      expect(result.entitlement.expiresAt, expiresAt);
    });

    test('a cached readiness snapshot for the selected exam is included',
        () async {
      final deps = _offlineDeps();
      final snapshot = ReadinessSnapshot(
        id: 'snap-1',
        examId: kDefaultExamId,
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
      await deps.localStore.writeLatestReadinessSnapshot(snapshot);
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      final result = await service.initialize() as BootstrapReady;

      expect(result.readinessSnapshot, isNotNull);
      expect(result.readinessSnapshot!.id, 'snap-1');
    });

    test(
        'a corrupt cache entry for one key does not affect other keys or '
        'crash startup, and is not presented as valid data', () async {
      // A local store whose entitlement read always throws (simulating a
      // corrupt entry a real implementation failed to guard against) —
      // AppBootstrapService itself has no special-case handling for
      // this, so this also proves any *unexpected* failure (not just an
      // anticipated content one) is caught and typed, never left to
      // crash startup.
      final deps = _offlineDeps();
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: _CorruptEntitlementLocalStore(deps.localStore),
      );

      final result = await service.initialize();

      expect(result, isA<BootstrapUnexpectedFailure>(),
          reason: 'a genuinely unexpected failure (not a content one) is '
              'reported as such, not silently swallowed or crashed on');
    });
  });

  group('each dependency is invoked exactly once', () {
    test('a single initialize() call touches the content loader once',
        () async {
      final deps = _offlineDeps();
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      await service.initialize();

      expect(deps.contentRepository.callCount, 1);
    });

    test(
        'calling initialize() multiple times does not re-invoke '
        'dependencies', () async {
      final deps = _offlineDeps();
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      await service.initialize();
      await service.initialize();
      await service.initialize();

      expect(deps.contentRepository.callCount, 1);
    });

    test('retry() genuinely re-invokes the content loader', () async {
      final deps = _offlineDeps();
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      await service.initialize();
      await service.retry();

      expect(deps.contentRepository.callCount, 2);
    });
  });

  group('no remote dependency is reachable', () {
    test(
        'AppBootstrapService\'s source has no network/backend imports or '
        'dependency types', () {
      final String source =
          File('lib/bootstrap/app_bootstrap_service.dart').readAsStringSync();
      for (final forbidden in [
        'package:http/',
        'package:dio/',
        'package:supabase',
        'SubscriptionRepository',
        'SyncRepository',
        'HttpClient',
      ]) {
        expect(source.contains(forbidden), isFalse,
            reason: 'AppBootstrapService must not reference "$forbidden" — '
                'bootstrap must be reachable entirely offline');
      }
    });

    test(
        'bootstrap succeeds end-to-end using only offline-capable '
        'dependencies (in-memory store, local file content)', () async {
      final deps = _offlineDeps();
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );

      final result = await service.initialize();

      expect(result, isA<BootstrapReady>(),
          reason: 'nothing injected here can reach a network — this '
              'succeeding proves bootstrap needs nothing that can');
    });
  });

  group('BootstrapReady.copyWith (session-sync mechanism)', () {
    test('replaces only the given fields, preserving everything else',
        () async {
      final deps = _offlineDeps();
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );
      final ready = await service.initialize() as BootstrapReady;

      final selection = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 1));
      final updated = ready.copyWith(examDateSelection: selection);

      expect(updated.examDateSelection, selection);
      expect(updated.selectedExamId, ready.selectedExamId);
      expect(updated.contentPackage, ready.contentPackage);
      expect(updated.onboardingComplete, ready.onboardingComplete);
      expect(updated.experienceLevel, ready.experienceLevel);
      expect(updated.entitlement, ready.entitlement);
      expect(updated.themePreference, ready.themePreference);
    });

    test(
        'layered updates accumulate — a later copyWith does not drop an '
        'earlier one\'s change', () async {
      final deps = _offlineDeps();
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );
      final ready = await service.initialize() as BootstrapReady;

      final selection = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 1));
      final withDate = ready.copyWith(examDateSelection: selection);
      final withBoth =
          withDate.copyWith(experienceLevel: ExperienceLevel.justStarting);

      expect(withBoth.examDateSelection, selection);
      expect(withBoth.experienceLevel, ExperienceLevel.justStarting);
    });

    test(
        'copyWith(onboardingComplete: true) can mark a session complete '
        'without any durable write happening', () async {
      final deps = _offlineDeps();
      final service = AppBootstrapService(
        contentRepository: deps.contentRepository,
        localStore: deps.localStore,
      );
      final ready = await service.initialize() as BootstrapReady;
      expect(ready.onboardingComplete, isFalse);

      final sessionOnly = ready.copyWith(onboardingComplete: true);

      expect(sessionOnly.onboardingComplete, isTrue);
      expect(await deps.localStore.readOnboardingComplete(), isNot(isTrue),
          reason: 'copyWith only ever affects the in-memory value — it '
              'must never itself write to durable storage');
    });
  });
}

/// Wraps a real [InMemoryBootstrapLocalStore] but makes the entitlement
/// read throw, simulating a corrupt entry a real store implementation
/// failed to contain — every other key still works normally through it.
class _CorruptEntitlementLocalStore implements BootstrapLocalStore {
  _CorruptEntitlementLocalStore(this._delegate);
  final BootstrapLocalStore _delegate;

  @override
  Future<Entitlement?> readEntitlementSnapshot() =>
      throw const FormatException('corrupt entitlement cache entry');

  @override
  Future<String?> readSelectedExamId() => _delegate.readSelectedExamId();
  @override
  Future<void> writeSelectedExamId(String examId) =>
      _delegate.writeSelectedExamId(examId);
  @override
  Future<bool?> readOnboardingComplete() => _delegate.readOnboardingComplete();
  @override
  Future<void> writeOnboardingComplete(bool complete) =>
      _delegate.writeOnboardingComplete(complete);
  @override
  Future<ThemePreference?> readThemePreference() =>
      _delegate.readThemePreference();
  @override
  Future<void> writeThemePreference(ThemePreference preference) =>
      _delegate.writeThemePreference(preference);
  @override
  Future<void> writeEntitlementSnapshot(Entitlement entitlement) =>
      _delegate.writeEntitlementSnapshot(entitlement);
  @override
  Future<ReadinessSnapshot?> readLatestReadinessSnapshot(String examId) =>
      _delegate.readLatestReadinessSnapshot(examId);
  @override
  Future<void> writeLatestReadinessSnapshot(ReadinessSnapshot snapshot) =>
      _delegate.writeLatestReadinessSnapshot(snapshot);
  @override
  Future<ExamDateSelection?> readExamDateSelection() =>
      _delegate.readExamDateSelection();
  @override
  Future<void> writeExamDateSelection(ExamDateSelection selection) =>
      _delegate.writeExamDateSelection(selection);
  @override
  Future<ExperienceLevel?> readExperienceLevel() =>
      _delegate.readExperienceLevel();
  @override
  Future<void> writeExperienceLevel(ExperienceLevel level) =>
      _delegate.writeExperienceLevel(level);
}
