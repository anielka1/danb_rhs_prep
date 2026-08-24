import 'package:flutter/material.dart';

import '../bootstrap/app_bootstrap_service.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/repositories/bootstrap_local_store.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';
import '../widgets/radiation_icon.dart';
import 'exam_date_screen.dart';

/// The first screen of onboarding: introduces the exam and starts it via
/// a single `Start Preparing` CTA, which reports `onboarding_started`
/// and hands off to [ExamDateScreen] — Section 3.3's screen, not this
/// one, now owns persisting `onboardingComplete` and entering
/// `MainShell`. Replaces Section 3.1's minimal `OnboardingEntryScreen`.
///
/// This widget (the routed [State]) owns orchestration only — analytics
/// and navigation. All rendering is delegated to [_WelcomeContent], a
/// presentation-only widget that receives everything it displays as
/// plain data/callbacks and itself calls `BootstrapSessionScope`,
/// `AnalyticsService`, or `Navigator` nowhere — mirroring
/// `SplashScreen`/`_SplashVisual`'s existing split in this codebase.
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
  /// Guards against a second concurrent activation while navigating to
  /// [ExamDateScreen] — not against normal rebuilds. Reset once the
  /// pushed route is popped (the user came back via Back), so tapping
  /// Start Preparing again works normally.
  bool _busy = false;

  /// `onboarding_started` must fire exactly once per CTA activation and
  /// never again — including if the user backs out to this screen and
  /// taps Start Preparing a second time, which continues the same
  /// already-reported onboarding attempt rather than starting a new one.
  /// This sticky flag (set once, never cleared) is what enforces that.
  bool _onboardingStartedSent = false;

  Future<void> _startPreparing() async {
    if (_busy) return;
    setState(() => _busy = true);

    // Captured before the `await` below (and thus before any risk of
    // this screen's context becoming invalid across the navigation) —
    // the snapshot the *next* route needs must come from this screen's
    // own ancestor scope.
    final BootstrapReady snapshot = BootstrapSessionScope.of(context);

    // Fires on CTA activation, not screen render, and exactly once.
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

    // A `push`, not `pushReplacement`: Welcome stays on the stack so
    // Back from the exam-date screen returns here, per Section 3.3 —
    // unlike the final onboarding-complete step, this hand-off is not
    // yet a point of no return.
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: ExamDateScreen.route),
        builder: (_) => BootstrapSessionScope(
          snapshot: snapshot,
          child: ExamDateScreen(
            localStore: widget.localStore,
            analytics: widget.analytics,
          ),
        ),
      ),
    );

    // Reached when the pushed route is popped (the user came back) —
    // clears the busy guard so a second Start Preparing tap works.
    if (!mounted) return;
    setState(() => _busy = false);
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
      onStartPreparing: _busy ? null : _startPreparing,
    );
  }
}

/// Pure presentation: renders exactly what it's told via constructor
/// parameters, and reports interaction only through the callback it's
/// given. No `BootstrapSessionScope`, `AnalyticsService`, `Navigator`, or
/// persistence access of any kind — that all lives in
/// [_WelcomeScreenState] above.
class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({
    required this.examName,
    required this.isBusy,
    required this.onStartPreparing,
  });

  final String examName;
  final bool isBusy;
  final VoidCallback? onStartPreparing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

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
                const SizedBox(height: AppSpacing.xxl),
                // 4. The one primary CTA.
                PrimaryButton(
                  label: 'Start Preparing',
                  isLoading: isBusy,
                  onPressed: onStartPreparing,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
