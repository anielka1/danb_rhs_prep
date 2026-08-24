import 'dart:io';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/domain/repositories/bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/content_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';

/// Reads and decodes the real bundled DANB RHS content directly from disk
/// (the same `File(...).readAsStringSync()` pattern
/// `content_validator_test.dart`/`exam_content_codec_test.dart` already
/// use — not a fabricated fixture), using the real, unmodified
/// `ExamContentCodec`. Implements the plain-Dart `ContentRepository`
/// interface, the same one `AppBootstrapService` depends on — this is a
/// test double for that interface, deliberately *not* the production
/// `BundledContentRepository`/`BundledExamContentLoader` (which loads
/// through `rootBundle`): `flutter_test`'s asset-bundle channel handler
/// does not survive being called from a second, separate `testWidgets`
/// block within the same file — confirmed by direct reproduction — so
/// any test file that (like this one, shared by many) needs to construct
/// bootstrap more than once would hang. Real `rootBundle` loading is
/// still exercised, once, by `app_bootstrap_service_test.dart`'s
/// dedicated test for it, and by `production_wiring_test.dart`'s
/// dedicated production-adapter test.
///
/// The decoded package is cached the first time a given [examId] is
/// loaded (content doesn't change mid-test-run) rather than re-reading
/// the file on every call: besides being wasteful, calling
/// `readAsStringSync` "live" from inside a `testWidgets` body at a point
/// interleaved with other pending async work has been observed to delay
/// that synchronous-looking call's effects until test teardown — a
/// `flutter_test`/`fake_async` interaction, confirmed by direct
/// reproduction. Reading once, eagerly, per `examId` avoids ever hitting
/// that window.
class RealFileContentRepository implements ContentRepository {
  const RealFileContentRepository();

  static final Map<String, ContentPackage> _cache = {};

  @override
  Future<ContentPackage> loadContentPackage(String examId) async {
    return _cache.putIfAbsent(examId, () {
      final String source =
          File('assets/content/$examId/content.json').readAsStringSync();
      return const ExamContentCodec().decode(source);
    });
  }
}

/// A ready-to-inject [AppBootstrapService] + [BootstrapLocalStore] pair
/// for widget tests that need `DanbRhsPrepApp`/`SplashScreen` to reach a
/// deterministic, real-content outcome — without duplicating an
/// in-memory store between the two, which would let the app's own
/// theme-persistence and the test's assertions read and write different
/// places.
///
/// Defaults to a "returning user" (`onboardingComplete: true`), since
/// most tests that don't specifically care about onboarding just want to
/// reach `MainShell`/Home directly, the way the old fixed-delay splash
/// always eventually did.
typedef ReadyAppBootstrap = ({
  AppBootstrapService bootstrapService,
  BootstrapLocalStore localStore,
});

ReadyAppBootstrap readyAppBootstrap({bool onboardingComplete = true}) {
  final BootstrapLocalStore localStore =
      InMemoryBootstrapLocalStore(onboardingComplete: onboardingComplete);
  return (
    bootstrapService: AppBootstrapService(
      contentRepository: const RealFileContentRepository(),
      localStore: localStore,
    ),
    localStore: localStore,
  );
}
