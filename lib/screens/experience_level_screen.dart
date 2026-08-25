import 'package:flutter/material.dart';

import '../bootstrap/app_bootstrap_service.dart';
import '../bootstrap/bootstrap_session_controller.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/models/experience_level.dart';
import '../domain/repositories/bootstrap_local_store.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';
import 'main_shell.dart';

/// Section 3.4: the third onboarding screen, reached by pushing (not
/// replacing) from [ExamDateScreen] so Back returns there with its
/// selection still visible. Lets the user record their study experience
/// level, then — since the real next onboarding step (diagnostic,
/// Section 3.5) doesn't exist yet — persists `onboardingComplete` and
/// enters `MainShell`. That completion bridge is isolated to
/// [_ExperienceLevelScreenState._continue] and documented there as
/// temporary, exactly like the one `ExamDateScreen` used to own before
/// this screen existed.
class ExperienceLevelScreen extends StatefulWidget {
  static const String route = '/onboarding/experience-level';

  const ExperienceLevelScreen({
    super.key,
    required this.localStore,
    this.analytics = const NoOpAnalyticsService(),
  });

  final BootstrapLocalStore localStore;
  final AnalyticsService analytics;

  @override
  State<ExperienceLevelScreen> createState() => _ExperienceLevelScreenState();
}

class _ExperienceLevelScreenState extends State<ExperienceLevelScreen> {
  ExperienceLevel? _selection;

  /// Set once, from `BootstrapSessionScope`'s restored
  /// [BootstrapReady.experienceLevel], the first time this State's
  /// `context` is usable — guards against re-reading it on every
  /// rebuild, which would stomp the user's in-progress choice.
  bool _restoredFromSession = false;

  /// Guards Continue/Retry/Continue-for-this-session against a second
  /// concurrent activation.
  bool _busy = false;

  /// True only after saving the experience-level selection itself
  /// failed.
  bool _selectionSaveFailed = false;

  /// True only after the selection saved successfully but the
  /// subsequent `onboardingComplete` write failed — Section 3.2/3.3's
  /// recoverable behavior, reused here verbatim.
  bool _completionSaveFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restoredFromSession) return;
    _restoredFromSession = true;

    final ExperienceLevel? saved =
        BootstrapSessionScope.snapshotOf(context).experienceLevel;
    if (saved != null) _selection = saved;
  }

  void _selectLevel(ExperienceLevel level) {
    if (_busy) return;
    setState(() {
      _selection = level;
      _selectionSaveFailed = false;
      _completionSaveFailed = false;
    });
  }

  /// **Temporary bridge (Section 3.4, pending Section 3.5):** the real
  /// next onboarding step (diagnostic) isn't built yet, so a successful
  /// experience-level save is followed immediately by persisting
  /// `onboardingComplete` and entering `MainShell`. Section 3.5 replaces
  /// only the "on success" branch below with real navigation — the
  /// experience-level save itself, and its own recoverable-failure
  /// handling, stay exactly as they are.
  Future<void> _continue() async {
    if (_busy) return;
    final ExperienceLevel? selection = _selection;
    if (selection == null) return;

    setState(() {
      _busy = true;
      _selectionSaveFailed = false;
      _completionSaveFailed = false;
    });

    final BootstrapSessionController controller =
        BootstrapSessionScope.controllerOf(context);

    try {
      await widget.localStore.writeExperienceLevel(selection);
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _selectionSaveFailed = true;
      });
      return;
    }

    // The experience answer is durably saved now — reflect it in the
    // shared session immediately, regardless of whether the subsequent
    // onboardingComplete write below succeeds. A failed write above
    // returns before reaching this line, so the controller is never
    // updated with a value that failed to persist.
    controller.update(controller.snapshot.copyWith(experienceLevel: selection));

    bool completed = true;
    try {
      await widget.localStore.writeOnboardingComplete(true);
    } on Object {
      completed = false;
    }

    if (!mounted) return;
    if (completed) {
      controller.update(controller.snapshot.copyWith(onboardingComplete: true));
      _navigateToMainShell(controller);
    } else {
      // The experience-level selection is already durably saved (and
      // already reflected in the shared session above) — only the
      // completion flag failed. Stay on this screen rather than
      // silently entering the main app on an unsaved flag.
      setState(() {
        _busy = false;
        _completionSaveFailed = true;
      });
    }
  }

  /// Lets the user proceed this session without durable
  /// `onboardingComplete` persistence, so a local-storage failure can't
  /// trap them offline. Only offered once the experience-level
  /// selection itself has already saved successfully. Does not retry
  /// the write or claim durable success — onboarding will honestly show
  /// again next launch — but the *shared session* is allowed to
  /// consider onboarding complete, per Section 3.4's session-sync
  /// requirement, so `MainShell` doesn't see a contradictory snapshot
  /// this session. Only the in-memory controller is touched; durable
  /// storage is never written here.
  void _continueForSessionOnly() {
    if (_busy) return;
    setState(() => _busy = true);
    final BootstrapSessionController controller =
        BootstrapSessionScope.controllerOf(context);
    controller.update(controller.snapshot.copyWith(onboardingComplete: true));
    _navigateToMainShell(controller);
  }

  /// `pushAndRemoveUntil` with a predicate that never matches — not
  /// `pushReplacement`, which would only remove this screen and leave
  /// `WelcomeScreen`/`ExamDateScreen` beneath `MainShell` in the stack.
  /// Onboarding is finished at this point: `MainShell` must become the
  /// sole, root route, so a system Back gesture/button has nothing left
  /// to pop to and can never reveal Welcome, Exam Date, or Splash again.
  /// `MainShell` receives the same shared controller — never a new one.
  void _navigateToMainShell(BootstrapSessionController controller) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: MainShell.route),
        builder: (_) => BootstrapSessionScope(
          controller: controller,
          child: MainShell(analytics: widget.analytics),
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    final bool hasFailure = _selectionSaveFailed || _completionSaveFailed;
    final String? errorMessage = _selectionSaveFailed
        ? "We couldn't save this. Please try again."
        : _completionSaveFailed
            ? "We couldn't finish setting up. Check your storage and "
                'try again.'
            : null;

    return AppScaffold(
      leading: CircleIconButton(
        icon: Icons.arrow_back_rounded,
        background: colors.surface,
        iconColor: colors.primary,
        semanticLabel: 'Back',
        onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              'Where are you in your preparation?',
              style: textStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose the option that best describes you right now.',
              style: textStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            _ChoiceCard(
              label: 'Just starting',
              selected: _selection == ExperienceLevel.justStarting,
              onTap: () => _selectLevel(ExperienceLevel.justStarting),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ChoiceCard(
              label: 'Studying already',
              selected: _selection == ExperienceLevel.studyingAlready,
              onTap: () => _selectLevel(ExperienceLevel.studyingAlready),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ChoiceCard(
              label: 'Taking the exam again',
              selected: _selection == ExperienceLevel.retakingExam,
              onTap: () => _selectLevel(ExperienceLevel.retakingExam),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                liveRegion: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: colors.error, size: AppIconSize.medium),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        errorMessage,
                        style: textStyles.body.copyWith(color: colors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: hasFailure ? 'Retry' : 'Continue',
              isLoading: _busy,
              onPressed: (_busy || _selection == null) ? null : _continue,
            ),
            if (_completionSaveFailed) ...[
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: 'Continue for this session',
                onPressed: _busy ? null : _continueForSessionOnly,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "This won't be saved — you'll see this setup again next "
                'time you open the app.',
                style: textStyles.body.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// One of the three mutually-exclusive experience-level choices.
/// Selected/unselected state is carried by an icon plus explicit
/// `Semantics.selected`/label text, never by color alone.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$label, selected' : '$label, not selected',
      child: GestureDetector(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Container(
            width: double.infinity,
            constraints:
                const BoxConstraints(minHeight: AppTapTarget.minInteractive),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color:
                  selected ? colors.primaryContainer : colors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadii.smallIcon),
              border: Border.all(
                color: selected ? colors.primary : Colors.transparent,
                width: AppBorderWidth.regular,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                  size: AppIconSize.medium,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
