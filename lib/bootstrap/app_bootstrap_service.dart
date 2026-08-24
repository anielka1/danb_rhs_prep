import '../domain/models/entitlement.dart';
import '../domain/models/exam_date_selection.dart';
import '../domain/models/readiness_snapshot.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/bootstrap_local_store.dart';
import '../domain/repositories/content_repository.dart';
import '../domain/repositories/user_settings_repository.dart';
import '../features/content/domain/content_package.dart';
import '../features/content/domain/content_validation.dart';

/// The exam this app supports today, used whenever no selection has ever
/// been stored locally, and as the safe recovery target for a stale or
/// unrecognized stored selection. Only one exam is currently supported;
/// this becomes a real "known exam IDs" set if a second exam is ever
/// added.
const String kDefaultExamId = 'danb_rhs';

/// The outcome of [AppBootstrapService.initialize]. A sealed hierarchy
/// (not a single class with nullable fields) so callers — in practice,
/// `SplashScreen` — must handle every case explicitly and can never
/// accidentally read [BootstrapReady] data from a failure result.
sealed class BootstrapResult {
  const BootstrapResult();
}

/// Bootstrap completed successfully. Carries everything the application
/// session needs, so later layers don't have to independently reload it
/// or query bundled JSON/plugins directly.
final class BootstrapReady extends BootstrapResult {
  const BootstrapReady({
    required this.selectedExamId,
    required this.contentPackage,
    required this.profile,
    required this.themePreference,
    required this.readinessSnapshot,
    required this.entitlement,
    required this.onboardingComplete,
    required this.examDateSelection,
  });

  final String selectedExamId;
  final ContentPackage contentPackage;

  /// Null until real onboarding (Phase 3.2-3.6) exists and saves one —
  /// always null today, which is the honest state, not a placeholder.
  final UserProfile? profile;

  final ThemePreference themePreference;

  /// Null until the readiness algorithm (Phase 7) exists and saves one —
  /// always null today.
  final ReadinessSnapshot? readinessSnapshot;

  /// Never null: defaults to a free entitlement (see
  /// [Entitlement.free]) when no cached entitlement exists or the
  /// cached one has expired.
  ///
  /// This is a **last-known local cache, not authoritative purchase
  /// verification** — it comes from a `SharedPreferences`-backed value
  /// a user could in principle edit on a jailbroken/rooted device, and
  /// nothing here contacts StoreKit/Play Billing to re-verify it.
  /// Real verification is Phase 9's job. Until that exists: do not gate
  /// premium features on this value alone, and never present bootstrap
  /// as having "verified" a purchase — it has only read a cache that
  /// defaults safely to free whenever it's missing, unparsable, or
  /// expired.
  final Entitlement entitlement;

  final bool onboardingComplete;

  /// The onboarding exam-date screen's saved selection, if any — null on
  /// a fresh install or if the user hasn't reached/completed that screen
  /// yet. Lets `ExamDateScreen` prefill a returning user's prior choice
  /// without re-reading local storage itself.
  final ExamDateSelection? examDateSelection;
}

/// The selected exam's bundled content could not be loaded or is invalid
/// — a missing/unreadable asset, a malformed package, a failed
/// [ContentValidator] check, or a selected exam ID that doesn't match
/// the loaded package. [message] is always safe to show a user; the
/// underlying cause (if any) is kept out of it entirely, never a stack
/// trace or file path.
final class BootstrapContentFailure extends BootstrapResult {
  const BootstrapContentFailure({required this.message, this.debugCause});

  final String message;

  /// For logs/tests only — never rendered in the UI.
  final Object? debugCause;
}

/// Something outside content loading failed unexpectedly (e.g. a local
/// store read threw instead of returning null for a corrupt entry, which
/// would itself be a bug in that store). Kept distinct from
/// [BootstrapContentFailure] so a future crash-reporting hook can
/// distinguish "the user's install is fine, the content wasn't" from
/// "something the app didn't anticipate happened."
final class BootstrapUnexpectedFailure extends BootstrapResult {
  const BootstrapUnexpectedFailure({required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;
}

/// Loads and validates bundled exam content and local cache, with no
/// Flutter import of any kind (widget, asset, or otherwise) and no
/// network dependency — the app must be able to start and begin
/// studying entirely offline. See `SplashScreen` for the only place
/// this is driven from, and `BootstrapLocalStore` for what "local
/// cache" is scoped to.
///
/// Content is loaded through [ContentRepository] — a plain-Dart
/// interface — never through `BundledExamContentLoader`/`rootBundle`
/// directly, which live behind `package:flutter/services.dart` in
/// `BundledContentRepository` (the production adapter, wired only in
/// `main.dart`). That keeps this file, and everything it directly
/// imports, free of any transitive Flutter dependency; see
/// `test/bootstrap/dependency_direction_test.dart` for a source-level
/// proof of that boundary.
///
/// [initialize] is memoized: calling it more than once (e.g. because a
/// caller doesn't itself guard against duplicate calls) returns the
/// same in-flight or completed result rather than re-running every
/// dependency again.
class AppBootstrapService {
  AppBootstrapService({
    required ContentRepository contentRepository,
    required BootstrapLocalStore localStore,
    this.userSettingsRepository,
    this.contentValidator = const ContentValidator(),
    this.defaultExamId = kDefaultExamId,
    DateTime Function()? now,
  })  : _contentRepository = contentRepository,
        _localStore = localStore,
        _now = now ?? DateTime.now;

  final ContentRepository _contentRepository;
  final BootstrapLocalStore _localStore;

  /// Null in production today — no adapter exists yet (see
  /// `BootstrapLocalStore`'s doc comment); [BootstrapReady.profile] is
  /// simply always null until one is wired up. Tests may inject
  /// `InMemoryUserSettingsRepository` to exercise the "profile present"
  /// path.
  final UserSettingsRepository? userSettingsRepository;

  final ContentValidator contentValidator;
  final String defaultExamId;
  final DateTime Function() _now;

  Future<BootstrapResult>? _pending;

  /// Runs bootstrap, exactly once regardless of how many times this is
  /// called: the first call starts it and every call (including the
  /// first) returns the same future. This is what "starts exactly once"
  /// and "not restarted by widget rebuilds" mean in practice — a widget
  /// calling this again (e.g. from `initState` after being recreated)
  /// can never trigger a second real run. Use [retry] for an explicit,
  /// user-initiated re-run after a failure.
  Future<BootstrapResult> initialize() {
    return _pending ??= _run();
  }

  /// Explicitly re-runs bootstrap from scratch — every dependency is
  /// called again — for a user-initiated retry after
  /// [BootstrapContentFailure]/[BootstrapUnexpectedFailure]. Unlike
  /// [initialize], this is never memoized: each call genuinely starts a
  /// new run. The caller (`SplashScreen`) is responsible for not calling
  /// this again while a previous call is still in flight.
  Future<BootstrapResult> retry() {
    final Future<BootstrapResult> run = _run();
    _pending = run;
    return run;
  }

  Future<BootstrapResult> _run() async {
    try {
      final String examId = await _resolveSelectedExamId();

      final ContentPackage package;
      try {
        package = await _contentRepository.loadContentPackage(examId);
      } on Object catch (error) {
        return BootstrapContentFailure(
          message: 'We couldn\'t load your study content.',
          debugCause: error,
        );
      }

      if (package.exam.id != examId) {
        return BootstrapContentFailure(
          message: 'We couldn\'t load your study content.',
          debugCause:
              'package.exam.id "${package.exam.id}" != selected "$examId"',
        );
      }

      final validation = contentValidator.validate(package);
      if (!validation.isValid) {
        return BootstrapContentFailure(
          message: 'We couldn\'t load your study content.',
          debugCause: validation.errors.map((e) => e.code).join(', '),
        );
      }

      final UserProfile? profile =
          await userSettingsRepository?.loadProfile(examId);

      final ThemePreference themePreference =
          await _localStore.readThemePreference() ?? ThemePreference.system;

      final ReadinessSnapshot? readinessSnapshot =
          await _localStore.readLatestReadinessSnapshot(examId);

      final DateTime now = _now();
      Entitlement? entitlement = await _localStore.readEntitlementSnapshot();
      if (entitlement == null || !entitlement.isActiveAt(now)) {
        entitlement = Entitlement.free(lastVerifiedAt: now);
      }

      final bool onboardingComplete =
          await _localStore.readOnboardingComplete() ?? false;

      final ExamDateSelection? examDateSelection =
          await _localStore.readExamDateSelection();

      return BootstrapReady(
        selectedExamId: examId,
        contentPackage: package,
        profile: profile,
        themePreference: themePreference,
        readinessSnapshot: readinessSnapshot,
        entitlement: entitlement,
        onboardingComplete: onboardingComplete,
        examDateSelection: examDateSelection,
      );
    } on Object catch (error, stackTrace) {
      return BootstrapUnexpectedFailure(error: error, stackTrace: stackTrace);
    }
  }

  /// Only one exam is currently supported. A stored ID is trusted only
  /// if it names that exam; no selection ever stored, or a stale/
  /// unrecognized one (e.g. left over from a future app version, or a
  /// removed exam), both safely resolve to [defaultExamId] — and that
  /// correction is written back, so storage self-heals rather than
  /// repeating the same resolution on every future launch.
  static const Set<String> _knownExamIds = {kDefaultExamId};

  Future<String> _resolveSelectedExamId() async {
    final String? stored = await _localStore.readSelectedExamId();
    if (stored != null && _knownExamIds.contains(stored)) return stored;
    await _localStore.writeSelectedExamId(defaultExamId);
    return defaultExamId;
  }
}
