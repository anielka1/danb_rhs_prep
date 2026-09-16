import '../features/content/sync/content_update_scope.dart';
import 'package:flutter/material.dart';

import '../bootstrap/app_bootstrap_service.dart';
import '../bootstrap/bootstrap_session_controller.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/repositories/bootstrap_local_store.dart';
import '../domain/repositories/progress_repository.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';
import '../widgets/radiation_icon.dart';
import 'main_shell.dart';
import 'welcome_screen.dart';

/// The app's entry screen: drives real startup ([AppBootstrapService])
/// instead of a fixed delay, showing the same splash artwork while that
/// runs. Its lifetime is determined entirely by bootstrap completion —
/// there is no timer here of any kind.
class SplashScreen extends StatefulWidget {
  static const String route = '/';

  const SplashScreen({
    super.key,
    required this.bootstrapService,
    required this.localStore,
    this.analytics = const NoOpAnalyticsService(),
    this.onReady,
    this.updatingQuestions,
    this.progressRepository,
  });

  final AppBootstrapService bootstrapService;
  final ValueNotifier<bool>? updatingQuestions;
  final BootstrapLocalStore localStore;
  final AnalyticsService analytics;
  final ProgressRepository? progressRepository;

  /// Called once, synchronously, with a [BootstrapReady] result before
  /// this screen navigates away — the app shell's hook for applying
  /// bootstrap-loaded state (e.g. the persisted theme preference) that
  /// lives above this screen and isn't part of the navigated-to route
  /// itself.
  final ValueChanged<BootstrapReady>? onReady;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Non-null only for a failure — a successful result navigates away
  /// immediately rather than ever being stored here. `null` is also the
  /// initial ("still loading") state.
  BootstrapResult? _failure;

  /// Guards against a second concurrent bootstrap run — from a retry tap
  /// while one is already in flight, not from normal `initState`, which
  /// runs exactly once per State lifetime regardless.
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _running = true;
    widget.bootstrapService.initialize().then(_handleResult);
  }

  void _handleResult(BootstrapResult result) {
    // The tree (or just this State) may have been disposed while
    // bootstrap was in flight — touching `context`/`setState` after that
    // would throw, so this must be the first thing checked.
    if (!mounted) return;
    _running = false;

    switch (result) {
      case BootstrapReady():
        _navigateAfterReady(result);
      case BootstrapContentFailure():
      case BootstrapUnexpectedFailure():
        setState(() => _failure = result);
    }
  }

  void _navigateAfterReady(BootstrapReady ready) {
    widget.onReady?.call(ready);
    // Local bootstrap is finished; network work cannot hold the splash open.
    ContentUpdateScope.maybeOf(context)?.start(ready.selectedExamId);

    // Created exactly once per app session, here — the only place a
    // BootstrapReady is first produced. Every route from here on
    // (Welcome, Exam Date, optional check, Main) forwards this same
    // instance; none of them ever constructs another one.
    final BootstrapSessionController controller = BootstrapSessionController(
        ready,
        progressRepository: widget.progressRepository,
        userSettingsRepository: widget.bootstrapService.userSettingsRepository);

    final Widget screen = ready.onboardingComplete
        ? MainShell(analytics: widget.analytics)
        : WelcomeScreen(
            userSettingsRepository:
                widget.bootstrapService.userSettingsRepository,
            localStore: widget.localStore,
            analytics: widget.analytics,
          );
    final String routeName =
        ready.onboardingComplete ? MainShell.route : WelcomeScreen.route;

    // pushReplacement, not push: the splash route must not remain
    // reachable by navigating back to it once startup has resolved.
    // An explicit MaterialPageRoute (rather than pushReplacementNamed)
    // is what lets this carry the shared BootstrapSessionController to
    // the next screen; RouteSettings(name:) on it is what keeps
    // AnalyticsNavigatorObserver's named-route reporting working exactly
    // as it did before this screen owned real logic.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (_) =>
            BootstrapSessionScope(controller: controller, child: screen),
      ),
    );
  }

  void _retry() {
    // Duplicate taps while a retry is already loading must not start a
    // second concurrent bootstrap run.
    if (_running) return;
    _running = true;
    setState(() => _failure = null);
    widget.bootstrapService.retry().then(_handleResult);
  }

  @override
  Widget build(BuildContext context) {
    final BootstrapResult? failure = _failure;
    if (failure != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ErrorState(
              title: 'Study content could not be loaded',
              message: 'Please try again. If this keeps happening, '
                  'reinstalling the app may help.',
              onRetry: _retry,
            ),
          ),
        ),
      );
    }
    return _SplashVisual(updatingQuestions: widget.updatingQuestions);
  }
}

/// The splash artwork itself — unchanged from before this screen owned
/// real bootstrap logic, and shown for exactly as long as that logic
/// takes, whether that's shorter or longer than the old fixed delay.
class _SplashVisual extends StatelessWidget {
  const _SplashVisual({this.updatingQuestions});
  final ValueNotifier<bool>? updatingQuestions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Background fading toward the primary-container tint, matching
          // the prototype's cream-to-periwinkle splash gradient using
          // theme-aware roles instead of a bespoke fixed color.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surface, colors.surface, colors.primaryContainer],
            stops: const [0.0, 0.62, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
            // Scrollable, not a plain Column: preserves the exact same
            // appearance at ordinary text sizes (nothing scrolls when
            // content already fits), but avoids clipping the headline at
            // large Dynamic Type sizes instead of overflowing.
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 160),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.5),
                        width: AppBorderWidth.regular,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const RadiationIcon(size: 46),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'DANB RHS Prep',
                    textAlign: TextAlign.center,
                    style: textStyles.h1,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ace Your Radiation Health and Safety Exam',
                    textAlign: TextAlign.center,
                    style: textStyles.body.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // A loading announcement for assistive tech — the
                  // splash artwork above it is otherwise silent/decorative.
                  if (updatingQuestions != null)
                    ValueListenableBuilder<bool>(
                      valueListenable: updatingQuestions!,
                      builder: (context, updating, _) => updating
                          ? Semantics(
                              liveRegion: true,
                              child: Text('Updating questions…',
                                  style: context.textStyles.bodySmall))
                          : const SizedBox.shrink(),
                    ),
                  Semantics(
                    liveRegion: true,
                    label: 'Loading',
                    child: const ExcludeSemantics(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
