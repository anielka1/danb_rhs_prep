import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/shared_preferences_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_user_settings_repository.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/features/content/data/bundled_content_repository.dart';

/// Everything else under `test/bootstrap/` proves the bootstrap
/// *algorithm* against test doubles (`_StaticContentRepository`,
/// `InMemoryBootstrapLocalStore`, file-read content). None of that
/// exercises the actual objects `main.dart` constructs, so none of it
/// alone is evidence the production wiring itself works end to end.
///
/// This file is that missing piece: it constructs `AppBootstrapService`
/// with the *exact* production dependency graph —
/// `BundledContentRepository` (which loads the real
/// `assets/content/danb_rhs/content.json` declared in `pubspec.yaml`
/// through `rootBundle`), `SharedPreferencesBootstrapLocalStore` (the
/// real `SharedPreferencesAsync`-backed store, only swapped to an
/// in-memory *platform backend* — the standard, supported way
/// `shared_preferences` itself documents for tests, not a substitute
/// repository implementation), and `DriftUserSettingsRepository` (the
/// real production adapter `main.dart` wires as of PREP-661, over an
/// in-memory `AppDatabase` rather than a real on-device file — this file
/// is about proving `AppBootstrapService`'s dependency graph, which is
/// identical either way; `app_database_test.dart` already covers the
/// real-file-backed `AppDatabase()` path end to end).
///
/// `testWidgets`, not `test`: `rootBundle` requires a live
/// `TestWidgetsFlutterBinding`. Deliberately the only test in this file
/// (see `RealFileContentRepository`'s doc comment in
/// `app_bootstrap_test_support.dart` for why real `rootBundle` use is
/// kept to one test per file) — a second `testWidgets` here calling
/// `BundledContentRepository` again would risk the same
/// `flutter_test` asset-channel hang already worked around elsewhere.
void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets(
      'the production wiring — BundledContentRepository + '
      'SharedPreferencesBootstrapLocalStore + DriftUserSettingsRepository, '
      'no network — succeeds against the real bundled asset', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final service = AppBootstrapService(
      contentRepository: BundledContentRepository(),
      localStore: SharedPreferencesBootstrapLocalStore(
        preferences: SharedPreferencesAsync(),
      ),
      userSettingsRepository: DriftUserSettingsRepository(database),
    );

    final result = await service.initialize();

    expect(result, isA<BootstrapReady>(),
        reason: 'the real production dependency graph must itself '
            'succeed, not just test substitutes for it');
    final ready = result as BootstrapReady;

    expect(ready.selectedExamId, kDefaultExamId,
        reason: 'a fresh SharedPreferences store has no stored '
            'selection, so this must resolve to the default exam');
    expect(ready.contentPackage.exam.id, kDefaultExamId);
    expect(ready.contentPackage.questions, isNotEmpty,
        reason: 'the actual bundled asset, loaded and validated through '
            'the real production adapter, must be genuinely usable');
    expect(ready.contentPackage.exam.domains, isNotEmpty);
    expect(ready.onboardingComplete, isFalse,
        reason: 'a fresh install has no persisted onboarding flag');
    expect(ready.entitlement.tier, EntitlementTier.free,
        reason: 'a fresh install has no persisted entitlement cache');
    expect(ready.profile, isNull,
        reason: 'the real DriftUserSettingsRepository, queried against a '
            'fresh, empty database, must honestly report no saved profile '
            'yet — not throw, and not fabricate one');
  });
}
