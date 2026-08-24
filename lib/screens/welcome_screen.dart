import 'package:flutter/material.dart';

import '../bootstrap/app_bootstrap_service.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/repositories/bootstrap_local_store.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';
import '../widgets/radiation_icon.dart';
import 'main_shell.dart';

/// The first screen of onboarding: introduces the exam and starts it via
/// a single `Start Preparing` CTA. Replaces Section 3.1's minimal
/// `OnboardingEntryScreen` — see [_WelcomeScreenState] for what's a
/// temporary bridge versus what's the real Section 3.2 behavior.
///
/// This widget (the routed [State]) owns orchestration only —
/// persistence, analytics, and navigation. All rendering is delegated to
/// [_WelcomeContent], a presentation-only widget that receives everything
/// it displays as plain data/callbacks and itself calls
/// `BootstrapSessionScope`, `AnalyticsService`, or `Navigator` nowhere —
/// mirroring `SplashScreen`/`_SplashVisual`'s existing split in this
/// codebase.
class WelcomeScreen extends StatefulWidget {
  static const String route = '/welcome';

  const WelcomeScreen({
    super.key,
    required this.localStore,
    this.analytics = const NoOpAnalyticsService(),
  });

  final BootstrapLocalStore localStore;
  final AnalyticsService analytics;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  /// Guards Start Preparing/Retry/Continue-for-this-session against a
  /// second concurrent activation — not against normal rebuilds.
  bool _busy = false;

  /// True only after a save has actually failed. Reuses Section 3.1's
  /// recoverable save-failure behavior verbatim (see
  /// `OnboardingEntryScreen`'s original implementation): stay on this
  /// screen, offer Retry, offer an explicit session-only continuation
  /// that never claims persistence succeeded.
  bool _saveFailed = false;

  /// `onboarding_started` must fire exactly once per CTA activation —
  /// the very first "Start Preparing" tap — and never again for a
  /// subsequent Retry of the same attempt. This sticky flag is what
  /// enforces that: it is set the first time the event is sent and never
  /// cleared, so `_startOrRetry` (reused for both the initial tap and
  /// Retry) only ever sends it once per screen lifetime.
  bool _onboardingStartedSent = false;

  /// **Temporary bridge (Section 3.1, still in effect until Section 3.3
  /// exists):** the real onboarding flow (exam date, experience level,
  /// diagnostic) isn't built yet, so activating the CTA here persists
  /// `onboardingComplete` and enters `MainShell` directly, exactly as
  /// `OnboardingEntryScreen` did. Section 3.3 replaces this method's
  /// body with real navigation to the next onboarding step — nothing
  /// else in this file (the presentation widget, the analytics call, the
  /// route name) needs to change when that happens.
  Future<void> _startOrRetry() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _saveFailed = false;
    });

    // Captured before the `await` below (and thus before any risk of
    // this screen's own route having been replaced/removed by the time
    // it resumes) — the snapshot the *new* route needs to carry forward
    // must come from this screen's own ancestor scope, not from the new
    // route's builder context, which won't have this screen as an
    // ancestor once navigation replaces it.
    final BootstrapReady snapshot = BootstrapSessionScope.of(context);

    // Fires on CTA activation, not screen render, and exactly once per
    // attempt — a Retry after a save failure continues the same
    // already-reported "started" intent, it doesn't start a new one.
    // Analytics failure must never be able to block onboarding, so any
    // exception here is swallowed, not surfaced.
    if (!_onboardingStartedSent) {
      _onboardingStartedSent = true;
      try {
        widget.analytics.trackEvent(
          'onboarding_started',
          properties: {'exam_id': snapshot.selectedExamId},
        );
      } on Object {
        // Intentionally swallowed — see doc comment above.
      }
    }

    bool saved = true;
    try {
      await widget.localStore.writeOnboardingComplete(true);
    } on Object {
      saved = false;
    }

    if (!mounted) return;
    if (saved) {
      _navigateToMainShell(snapshot);
    } else {
      // Stay on this screen rather than silently entering the main app
      // on an unsaved flag — a silent success here would mean onboarding
      // reappears next launch with no explanation of why.
      setState(() {
        _busy = false;
        _saveFailed = true;
      });
    }
  }

  /// Lets the user proceed this session without durable persistence, so
  /// a local-storage failure can't trap them offline. Deliberately does
  /// *not* retry the write or claim success — `onboardingComplete` stays
  /// unset, so onboarding will honestly show again next launch.
  void _continueForSessionOnly() {
    if (_busy) return;
    setState(() => _busy = true);
    final BootstrapReady snapshot = BootstrapSessionScope.of(context);
    _navigateToMainShell(snapshot);
  }

  void _navigateToMainShell(BootstrapReady snapshot) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: MainShell.route),
        builder: (_) => BootstrapSessionScope(
          snapshot: snapshot,
          child: MainShell(analytics: widget.analytics),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The exam's public display name comes from the validated
    // `ExamConfig` inside the bootstrap session — never a hardcoded
    // screen string, and never read from a bundled content asset by
    // this screen directly (that's the content pipeline's job, already
    // done by the time bootstrap produces this snapshot).
    final BootstrapReady snapshot = BootstrapSessionScope.of(context);
    return _WelcomeContent(
      examName: snapshot.contentPackage.exam.name,
      isBusy: _busy,
      errorMessage: _saveFailed
          ? "We couldn't save this on your device. Check your storage "
              'and try again.'
          : null,
      onStartPreparing: _busy ? null : _startOrRetry,
      onContinueForSessionOnly:
          (_saveFailed && !_busy) ? _continueForSessionOnly : null,
    );
  }
}

/// Pure presentation: renders exactly what it's told via constructor
/// parameters, and reports interaction only through the callbacks it's
/// given. No `BootstrapSessionScope`, `AnalyticsService`, `Navigator`, or
/// persistence access of any kind — that all lives in
/// [_WelcomeScreenState] above, which is what Section 3.3 will change
/// when it replaces the temporary onboarding-completion bridge.
class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({
    required this.examName,
    required this.isBusy,
    required this.errorMessage,
    required this.onStartPreparing,
    required this.onContinueForSessionOnly,
  });

  final String examName;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback? onStartPreparing;
  final VoidCallback? onContinueForSessionOnly;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final bool hasError = errorMessage != null;

    return AppScaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. App/exam identity.
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  alignment: Alignment.center,
                  child: const RadiationIcon(size: 40),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  examName,
                  style: textStyles.label.copyWith(
                    color: colors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                // 2. Headline.
                Text(
                  "Know when you're ready to pass.",
                  style: textStyles.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                // 3. Supporting copy.
                Text(
                  'Build confidence with focused practice, clear '
                  'explanations, and progress you can understand.',
                  style: textStyles.body,
                  textAlign: TextAlign.center,
                ),
                if (hasError) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    liveRegion: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: colors.error,
                          size: AppIconSize.medium,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            errorMessage!,
                            style: textStyles.body.copyWith(
                              color: colors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                // 4. The one primary CTA.
                PrimaryButton(
                  label: hasError ? 'Retry' : 'Start Preparing',
                  isLoading: isBusy,
                  onPressed: onStartPreparing,
                ),
                if (hasError) ...[
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    label: 'Continue for this session',
                    onPressed: onContinueForSessionOnly,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "This won't be saved — you'll see this setup again "
                    'next time you open the app.',
                    style: textStyles.body.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
