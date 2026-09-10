import 'diagnostic_screen.dart';
import 'study_availability_screen.dart';
import 'package:flutter/material.dart';

import '../bootstrap/app_bootstrap_service.dart';
import '../bootstrap/bootstrap_session_controller.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../bootstrap/sync_study_profile.dart';
import '../domain/models/exam_date_selection.dart';
import '../domain/models/experience_level.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/bootstrap_local_store.dart';
import '../domain/repositories/user_settings_repository.dart';
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
///
/// Also where a real, durable [UserProfile] gets saved (PREP-663), once
/// `onboardingComplete` itself has — see
/// [_ExperienceLevelScreenState._saveProfileBestEffort].
class ExperienceLevelScreen extends StatefulWidget {
  static const String route = '/onboarding/experience-level';

  const ExperienceLevelScreen({
    super.key,
    required this.localStore,
    this.analytics = const NoOpAnalyticsService(),
    this.userSettingsRepository,
    this.now,
    this.editing = false,
  });

  final BootstrapLocalStore localStore;

  /// Saves back to settings without changing onboarding completion.
  final bool editing;
  final AnalyticsService analytics;

  /// A real `DriftUserSettingsRepository` in production (`main.dart`'s
  /// default), forwarded here from `WelcomeScreen`/`ExamDateScreen`. When
  /// non-null, a successful onboarding completion (PREP-663) also saves a
  /// real [UserProfile] through it — see [_ExperienceLevelScreenState._continue].
  /// Null skips that save entirely (never fabricates a profile): tests
  /// that don't care about it, and any future caller with nothing to
  /// persist through.
  final UserSettingsRepository? userSettingsRepository;

  /// Test-only injection point for a deterministic "now", used as both
  /// [UserProfile.createdAt] (for a brand new profile) and
  /// [UserProfile.updatedAt]. Null in production, where the [State]
  /// defaults to [DateTime.now].
  final DateTime Function()? now;

  @override
  State<ExperienceLevelScreen> createState() => _ExperienceLevelScreenState();
}

class _ExperienceLevelScreenState extends State<ExperienceLevelScreen> {
  late final DateTime Function() _now = widget.now ?? DateTime.now;

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

    if (widget.editing) {
      try {
        await syncStudyProfile(controller, widget.userSettingsRepository);
      } on Object {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _selectionSaveFailed = true;
        });
        return;
      }
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (!mounted) return;
    bool completed = true;
    if (controller.userSettingsRepository != null ||
        widget.userSettingsRepository != null) {
      final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) => StudyAvailabilityScreen(
              session: controller,
              repository: widget.userSettingsRepository,
              now: _now)));
      if (!mounted) return;
      if (saved != true) {
        setState(() => _busy = false);
        return;
      }
    }
    if (!mounted) return;
    if (controller.userSettingsRepository != null ||
        widget.userSettingsRepository != null) {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DiagnosticScreen(session: controller)));
      if (!mounted) return;
    }
    try {
      await widget.localStore.writeOnboardingComplete(true);
    } on Object {
      completed = false;
    }

    if (!mounted) return;
    if (completed) {
      controller.update(controller.snapshot.copyWith(onboardingComplete: true));
      await _saveProfileBestEffort(
        examId: controller.snapshot.selectedExamId,
        experienceLevel: selection,
        examDateSelection: controller.snapshot.examDateSelection,
        themePreference: controller.snapshot.themePreference,
      );
      if (!mounted) return;
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

  /// Persists a real [UserProfile] (PREP-663) reflecting the answers
  /// onboarding just collected, through [widget.userSettingsRepository] —
  /// completely best-effort, mirroring `PracticeSessionController`'s
  /// established pattern elsewhere in this codebase: a missing repository
  /// or a failed write must never block or roll back the
  /// `onboardingComplete` flag already durably saved above, since that
  /// flag — not this profile — is what actually gates entering the app.
  /// [examDateSelection] is only ever null here if this screen was
  /// somehow reached without going through `ExamDateScreen` first (never
  /// true in the real app, but guarded rather than assumed); the save is
  /// silently skipped in that case too, exactly like a null repository.
  Future<void> _saveProfileBestEffort({
    required String examId,
    required ExperienceLevel experienceLevel,
    required ExamDateSelection? examDateSelection,
    required ThemePreference themePreference,
  }) async {
    final UserSettingsRepository? repository = widget.userSettingsRepository;
    if (repository == null || examDateSelection == null) return;
    try {
      final UserProfile? existing = await repository.loadProfile(examId);
      final UserProfile profile = UserProfile.fromOnboarding(
        examId: examId,
        experienceLevel: experienceLevel,
        examDateSelection: examDateSelection,
        themePreference: themePreference,
        now: _now(),
        existing: existing,
      );
      await repository.saveProfile(profile);
    } on Object {
      // Best-effort: see this method's own doc comment.
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
  void _navigateToMainShell(BootstrapSessionController controller) async {
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
        ? widget.editing
            ? "We couldn't finish saving your changes. Please try again."
            : "We couldn't save this. Please try again."
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
              style: textStyles.h1,
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose the option that best describes you right now.',
              style: textStyles.body,
              textAlign: TextAlign.start,
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
              label: hasFailure
                  ? 'Retry'
                  : widget.editing
                      ? 'Save changes'
                      : 'Continue',
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
                textAlign: TextAlign.start,
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
                color: selected ? colors.primary : colors.outlineVariant,
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
