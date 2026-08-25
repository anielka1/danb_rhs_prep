import 'app_bootstrap_service.dart';

/// Holds the single, shared, in-memory [BootstrapReady] snapshot for the
/// current app session, and lets it be updated in place as onboarding
/// progresses.
///
/// Deliberately a plain mutable holder, not a `ValueNotifier`/
/// `ChangeNotifier` — nothing here needs to *react* to a change (no
/// screen rebuilds when another screen calls [update]; each screen only
/// ever reads [snapshot] at specific moments: when it first builds, and
/// again right before it saves or navigates). That makes this the
/// smallest mechanism that satisfies the actual requirement — one
/// shared, genuinely-mutated session, not a forward-only chain of
/// immutable copies — without pulling in a notifier's rebuild/dispose
/// machinery for behavior nothing here needs. It also holds no
/// disposable resources (no listeners, no subscriptions), so unlike
/// `ThemeModeController` it does not need an explicit `dispose()` or an
/// owner responsible for calling one.
///
/// Created exactly once per app session — by `SplashScreen`, the only
/// place a [BootstrapReady] is first produced — and the same instance is
/// then threaded through every onboarding route and into `MainShell` via
/// `BootstrapSessionScope`. No route may construct a new one; each only
/// ever forwards the instance it was given.
class BootstrapSessionController {
  BootstrapSessionController(BootstrapReady initial) : _snapshot = initial;

  BootstrapReady _snapshot;

  /// The current snapshot. Always the latest one successfully persisted
  /// (or, for a session-only onboarding completion, the latest one this
  /// session has chosen to treat as complete) — never a value a failed
  /// write produced.
  BootstrapReady get snapshot => _snapshot;

  /// Replaces the current snapshot. Callers update only after the write
  /// the new value represents has actually succeeded (or, for the
  /// explicit session-only completion path, when choosing to treat
  /// onboarding as complete for this session only) — never speculatively
  /// before a write, and never after one has failed.
  void update(BootstrapReady snapshot) {
    _snapshot = snapshot;
  }
}
