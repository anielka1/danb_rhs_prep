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

/// A minimal, honest stand-in for the real onboarding questionnaire
/// (Welcome/exam-date/experience-level/diagnostic screens, Phase 3.2-3.6
/// — not built yet). This screen makes no claims about a study plan,
/// exam date, or diagnostic result, and does not fabricate a
/// `UserProfile` — it only records that onboarding was acknowledged and
/// enters the main app, which the real questionnaire will replace this
/// with once it exists.
class OnboardingEntryScreen extends StatefulWidget {
  static const String route = '/onboarding';

  const OnboardingEntryScreen({
    super.key,
    required this.localStore,
    this.analytics = const NoOpAnalyticsService(),
  });

  final BootstrapLocalStore localStore;
  final AnalyticsService analytics;

  @override
  State<OnboardingEntryScreen> createState() => _OnboardingEntryScreenState();
}

class _OnboardingEntryScreenState extends State<OnboardingEntryScreen> {
  /// True while a save (Continue/Retry) is in flight — guards against a
  /// second concurrent write, not against normal rebuilds.
  bool _busy = false;

  /// True only after a save has actually failed — drives showing the
  /// recoverable error UI and switches the primary button to "Retry".
  bool _saveFailed = false;

  Future<void> _continue() async {
    // Idempotent and re-entrant-safe: a second tap while the first is
    // still writing is a no-op rather than a duplicate write or a
    // duplicate navigation.
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
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: const RadiationIcon(size: 40),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Welcome',
                    style: textStyles.h1, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'A short setup that gets to know your exam date and '
                  'experience level is coming soon. For now, you can head '
                  'straight into the app and start exploring.',
                  style: textStyles.body,
                  textAlign: TextAlign.center,
                ),
                if (_saveFailed) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      "We couldn't save this on your device. Check your "
                      'storage and try again.',
                      style: textStyles.body.copyWith(color: colors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                PrimaryButton(
                  label: _saveFailed ? 'Retry' : 'Continue',
                  isLoading: _busy,
                  onPressed: _busy ? null : _continue,
                ),
                if (_saveFailed) ...[
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    label: 'Continue for this session',
                    isLoading: false,
                    onPressed: _busy ? null : _continueForSessionOnly,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "This won't be saved — you'll see this setup again "
                    'next time you open the app.',
                    style: textStyles.body
                        .copyWith(color: colors.onSurfaceVariant),
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
