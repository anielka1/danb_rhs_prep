import 'package:flutter/material.dart';

import '../bootstrap/app_bootstrap_service.dart';
import '../bootstrap/bootstrap_session_controller.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../bootstrap/sync_study_profile.dart';
import '../domain/models/exam_date_precision.dart';
import '../domain/models/exam_date_selection.dart';
import '../domain/repositories/bootstrap_local_store.dart';
import '../domain/repositories/user_settings_repository.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';
import 'main_shell.dart';

/// Collects an exam timeframe, then opens Home.
/// Saves profile and completion before replacing onboarding with the app shell.
/// No self-assessed experience or availability is collected.
class ExamDateScreen extends StatefulWidget {
  static const String route = '/onboarding/exam-date';

  const ExamDateScreen({
    super.key,
    required this.localStore,
    this.analytics = const NoOpAnalyticsService(),
    this.userSettingsRepository,
    this.now,
    this.editing = false,
  });

  final BootstrapLocalStore localStore;

  /// Saves back to settings instead of advancing onboarding.
  final bool editing;
  final AnalyticsService analytics;

  /// Synchronizes the profile before completing onboarding or editing.
  final UserSettingsRepository? userSettingsRepository;

  /// Test-only injection point for a deterministic "today". Null in
  /// production, where the [State] defaults to [DateTime.now] — nothing
  /// in this screen's validation logic calls that directly.
  final DateTime Function()? now;

  @override
  State<ExamDateScreen> createState() => _ExamDateScreenState();
}

class _ExamDateScreenState extends State<ExamDateScreen> {
  late final DateTime Function() _now = widget.now ?? DateTime.now;
  DateTime get _today => normalizeToLocalDate(_now());

  ExamDatePrecision? _precision;
  DateTime? _selectedDate;

  /// Set once, from `BootstrapSessionScope`'s restored
  /// [BootstrapReady.examDateSelection], the first time this State's
  /// `context` is usable — guards against re-reading it on every
  /// rebuild, which would stomp the user's in-progress choice.
  bool _restoredFromSession = false;

  /// True only when a *previously saved* date has since become past —
  /// distinct from simply never having chosen one. Cleared as soon as
  /// the user picks a new date or a different precision.
  bool _restoredDateExpired = false;

  /// Guards Continue/Retry against concurrent saves.
  bool _busy = false;

  /// A timeframe, profile or completion write failed; retry keeps saved answers.
  bool _selectionSaveFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restoredFromSession) return;
    _restoredFromSession = true;

    final ExamDateSelection? saved =
        BootstrapSessionScope.snapshotOf(context).examDateSelection;
    if (saved == null) return;

    if (!saved.precision.requiresDate) {
      _precision = saved.precision;
      return;
    }

    _precision = saved.precision;
    final DateTime? date = saved.date;
    if (date != null && !date.isBefore(_today)) {
      _selectedDate = date;
    } else {
      // The choice itself is still honored (kept visible/selected) but
      // the stale date is not presented as valid, and is not silently
      // replaced with anything — the user must pick a new one.
      _restoredDateExpired = true;
    }
  }

  bool get _canContinue {
    final ExamDatePrecision? precision = _precision;
    if (precision == null) return false;
    if (!precision.requiresDate) return true;
    final DateTime? date = _selectedDate;
    if (date == null) return false;
    return !date.isBefore(_today);
  }

  /// Builds the selection to save, re-validating it against "today" one
  /// more time regardless of what UI state got us here — the defense
  /// this screen owes independently of the date picker's own
  /// `firstDate` restriction, per Section 3.3's explicit requirement
  /// that validation not live only inside the picker.
  ExamDateSelection? _buildValidatedSelection() {
    final ExamDatePrecision? precision = _precision;
    if (precision == null) return null;
    final ExamDateSelection selection = ExamDateSelection(
      precision: precision,
      date: precision.requiresDate ? _selectedDate : null,
    );
    return isExamDateSelectionValid(selection, _today) ? selection : null;
  }

  void _selectPrecision(ExamDatePrecision precision) {
    if (_busy) return;
    setState(() {
      _precision = precision;
      if (!precision.requiresDate) {
        _selectedDate = null;
      }
      _restoredDateExpired = false;
      _selectionSaveFailed = false;
    });
  }

  Future<void> _pickDate() async {
    if (_busy) return;
    final DateTime today = _today;
    final DateTime initial =
        (_selectedDate != null && !_selectedDate!.isBefore(today))
            ? _selectedDate!
            : today;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3653)),
      currentDate: today,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = normalizeToLocalDate(picked);
      _restoredDateExpired = false;
      _selectionSaveFailed = false;
    });
  }

  /// Retry preserves the saved timeframe and any diagnostic answers.
  Future<void> _continue() async {
    if (_busy) return;
    final ExamDateSelection? selection = _buildValidatedSelection();
    if (selection == null) return;

    setState(() {
      _busy = true;
      _selectionSaveFailed = false;
    });

    final BootstrapSessionController controller =
        BootstrapSessionScope.controllerOf(context);

    try {
      await widget.localStore.writeExamDateSelection(selection);
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _selectionSaveFailed = true;
      });
      return;
    }

    // Only update the shared session after the write actually succeeded
    // — a failed write above returns before reaching this line, so the
    // controller retains whatever it held before.
    controller
        .update(controller.snapshot.copyWith(examDateSelection: selection));

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

    try {
      await syncStudyProfile(controller,
          widget.userSettingsRepository ?? controller.userSettingsRepository);
      await widget.localStore.writeOnboardingComplete(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _selectionSaveFailed = true;
        });
      }
      return;
    }
    controller.update(controller.snapshot.copyWith(onboardingComplete: true));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
            settings: const RouteSettings(name: MainShell.route),
            builder: (_) => BootstrapSessionScope(
                controller: controller,
                child: MainShell(
                    analytics: widget.analytics,
                    progressRepository: controller.progressRepository))),
        (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    final String? errorMessage = _selectionSaveFailed
        ? widget.editing
            ? "We couldn't finish saving your changes. Please try again."
            : "We couldn't finish saving your setup. Please try again."
        : _restoredDateExpired
            ? 'Your saved exam date has already passed. Please choose a '
                'new date.'
            : null;
    final bool needsDateSelector = _precision == ExamDatePrecision.exact ||
        _precision == ExamDatePrecision.approximate;

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
              'When is your exam?',
              style: textStyles.h1,
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'A rough idea is enough. You can change this anytime.',
              style: textStyles.body,
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final entry in const {
              ExamDatePrecision.withinMonth: 'Within a month',
              ExamDatePrecision.oneToThreeMonths: 'In 1–3 months',
              ExamDatePrecision.later: 'Later',
              ExamDatePrecision.notScheduled: "I haven't scheduled it yet",
            }.entries) ...[
              _ChoiceCard(
                  label: entry.value,
                  selected: _precision == entry.key,
                  onTap: () => _selectPrecision(entry.key)),
              const SizedBox(height: AppSpacing.sm),
            ],
            _ChoiceCard(
              label: 'I know the exact date',
              selected: _precision == ExamDatePrecision.exact,
              onTap: () => _selectPrecision(ExamDatePrecision.exact),
            ),
            if (_precision == ExamDatePrecision.approximate)
              Text('Previously saved approximate date',
                  style: textStyles.bodySmall),
            if (needsDateSelector) ...[
              const SizedBox(height: AppSpacing.lg),
              _DateSelector(
                date: _selectedDate,
                localizations: localizations,
                onTap: _busy ? null : _pickDate,
              ),
            ],
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
              label: _selectionSaveFailed
                  ? 'Retry'
                  : widget.editing
                      ? 'Save changes'
                      : 'Continue',
              isLoading: _busy,
              onPressed: (_busy || !_canContinue) ? null : _continue,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// One of the three mutually-exclusive exam-date-precision choices.
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
                horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
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

/// The tappable row that opens the date picker and displays the
/// currently-chosen date, localized via [MaterialLocalizations] — never
/// a manually-formatted string, and never an added formatting
/// dependency.
class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.date,
    required this.localizations,
    required this.onTap,
  });

  final DateTime? date;
  final MaterialLocalizations localizations;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String valueLabel =
        date == null ? 'Choose a date' : localizations.formatMediumDate(date!);
    return Semantics(
      button: true,
      label: date == null ? 'Exam date, not set' : 'Exam date, $valueLabel',
      child: GestureDetector(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Container(
            width: double.infinity,
            constraints:
                const BoxConstraints(minHeight: AppTapTarget.minInteractive),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadii.smallIcon),
              border: Border.all(color: colors.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: colors.primary, size: AppIconSize.medium),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    valueLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: date == null
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
