import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_controller.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/models/exam_date_precision.dart';
import '../domain/models/experience_level.dart';
import '../domain/repositories/bootstrap_local_store.dart';
import '../domain/repositories/user_settings_repository.dart';
import '../services/theme_mode_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';
import 'exam_date_screen.dart';
import 'experience_level_screen.dart';
import 'study_help_screen.dart';

/// Accountless settings. Only controls backed by working behavior are shown.
class ProfileSettingsScreen extends StatefulWidget {
  static const String route = 'settings';
  const ProfileSettingsScreen(
      {super.key,
      required this.themeModeController,
      this.session,
      this.localStore,
      this.userSettingsRepository,
      this.onResetProgress});
  final ThemeModeController themeModeController;
  final BootstrapSessionController? session;
  final BootstrapLocalStore? localStore;
  final UserSettingsRepository? userSettingsRepository;
  final Future<void> Function()? onResetProgress;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _resetting = false;
  bool _confirmingReset = false;
  bool _resetFailed = false;

  Future<void> _reset() async {
    if (_resetting || _confirmingReset) return;
    _confirmingReset = true;
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Reset study progress?',
      message: 'This deletes answers, saved questions, unfinished sessions, '
          'mock exam history and progress for this exam on this device. '
          'Your study plan and appearance stay unchanged. This cannot be undone.',
      actions: const [
        AppDialogAction(
            label: 'Keep my progress',
            value: false,
            style: AppDialogActionStyle.cancel),
        AppDialogAction(
            label: 'Reset progress',
            value: true,
            style: AppDialogActionStyle.destructive),
      ],
    );
    _confirmingReset = false;
    if (!mounted || confirmed != true) return;
    setState(() {
      _resetting = true;
      _resetFailed = false;
    });
    try {
      await widget.onResetProgress!();
    } catch (_) {
      if (mounted) setState(() => _resetFailed = true);
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  Future<void> _edit(bool date) async {
    final session = widget.session!;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BootstrapSessionScope(
        controller: session,
        child: date
            ? ExamDateScreen(
                localStore: widget.localStore!,
                editing: true,
                userSettingsRepository: widget.userSettingsRepository)
            : ExperienceLevelScreen(
                localStore: widget.localStore!,
                editing: true,
                userSettingsRepository: widget.userSettingsRepository),
      ),
    ));
    if (mounted) setState(() {});
  }

  String _dateLabel(BuildContext context) {
    final selection = widget.session?.snapshot.examDateSelection;
    if (selection == null) return 'Choose your timeframe';
    return switch (selection.precision) {
      ExamDatePrecision.withinMonth => 'Within a month',
      ExamDatePrecision.oneToThreeMonths => 'In 1–3 months',
      ExamDatePrecision.later => 'Later',
      ExamDatePrecision.notScheduled => 'Not scheduled yet',
      ExamDatePrecision.exact ||
      ExamDatePrecision.approximate =>
        MaterialLocalizations.of(context).formatMediumDate(selection.date!),
    };
  }

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return PopScope(
      canPop: !_resetting,
      child: AppScaffold(
        leading: CircleIconButton(
          icon: Icons.chevron_left_rounded,
          onPressed: _resetting ? null : () => Navigator.of(context).maybePop(),
          semanticLabel: 'Back',
        ),
        title: 'Settings',
        body: AbsorbPointer(
          absorbing: _resetting,
          child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: AppSpacing.lg),
              Text('Make it yours.', style: styles.h1),
              const SizedBox(height: AppSpacing.sm),
              Text('Your study plan. Your pace.', style: styles.body),
              const SizedBox(height: AppSpacing.xxl),
              AppCard(
                backgroundColor: context.colors.primaryContainer,
                child: Row(children: [
                  const _IconBadge(icon: Icons.auto_stories_rounded),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Your study space', style: styles.h3),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Small adjustments. A better routine.',
                            style: styles.bodySmall),
                      ])),
                ]),
              ),
              if (widget.session != null && widget.localStore != null) ...[
                const SizedBox(height: AppSpacing.xxxl),
                Text('YOUR STUDY PLAN', style: styles.label),
                const SizedBox(height: AppSpacing.md),
                _SettingsAction(
                    icon: Icons.event_rounded,
                    title: 'Exam timeframe',
                    subtitle: _dateLabel(context),
                    onTap: () => _edit(true)),
                const SizedBox(height: AppSpacing.md),
                _SettingsAction(
                    icon: Icons.school_rounded,
                    title: 'Study experience',
                    subtitle: switch (
                        widget.session!.snapshot.experienceLevel) {
                      ExperienceLevel.justStarting => 'Just starting',
                      ExperienceLevel.studyingAlready => 'Studying already',
                      ExperienceLevel.retakingExam => 'Taking the exam again',
                      null => 'Choose your experience',
                    },
                    onTap: () => _edit(false)),
              ],
              const SizedBox(height: AppSpacing.xxxl),
              Text('LOOK & FEEL', style: styles.label),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      const _IconBadge(icon: Icons.contrast_rounded),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Appearance', style: styles.h3),
                            Text('Easy on your eyes', style: styles.bodySmall),
                          ])),
                    ]),
                    const SizedBox(height: AppSpacing.xl),
                    _AppearanceChoices(controller: widget.themeModeController),
                    const SizedBox(height: AppSpacing.md),
                    Text('Applies throughout the app.',
                        style: styles.bodySmall),
                  ])),
              const SizedBox(height: AppSpacing.xxxl),
              Text('HELP & YOUR DATA', style: styles.label),
              const SizedBox(height: AppSpacing.md),
              _SettingsAction(
                  icon: Icons.auto_stories_rounded,
                  title: 'Study help',
                  subtitle: 'Answers, progress & getting started',
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const StudyHelpScreen()))),
              const SizedBox(height: AppSpacing.md),
              const _InformationSection(
                  icon: Icons.shield_outlined,
                  title: 'Your data',
                  text:
                      'No account is needed. Study progress is stored locally in the standard app. The debug demo uses temporary data that resets when it restarts.'),
              const SizedBox(height: AppSpacing.md),
              const _InformationSection(
                  icon: Icons.info_outline_rounded,
                  title: 'About RHS Prep',
                  text:
                      'An independent study tool, not affiliated with or endorsed by DANB. Practice results are educational estimates, not official exam results.'),
              const SizedBox(height: AppSpacing.xxxl),
              if (widget.onResetProgress != null) ...[
                Text('START FRESH', style: styles.label),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('A fresh start', style: styles.h3),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                          'Clear study progress for this exam. Keep your plan and appearance.',
                          style: styles.body),
                      const SizedBox(height: AppSpacing.lg),
                      if (_resetFailed) ...[
                        Semantics(
                            liveRegion: true,
                            child: const Text(
                                'Could not reset progress. Your saved data is unchanged. Try again.')),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      PrimaryButton(
                          color: context.colors.errorContainer,
                          textColor: context.colors.onErrorContainer,
                          trailingIcon: Icons.restart_alt_rounded,
                          label: _resetting
                              ? 'Resetting progress…'
                              : 'Reset study progress',
                          onPressed: _resetting ? null : _reset),
                    ])),
                const SizedBox(height: AppSpacing.xxxl),
              ],
              Center(child: Text('RHS PREP', style: styles.label)),
              const SizedBox(height: AppSpacing.huge),
            ]),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, color: context.colors.primary, size: 25),
      );
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(children: [
          _IconBadge(icon: icon),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title, style: context.textStyles.h3),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: context.textStyles.bodySmall),
              ])),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right_rounded,
              color: context.colors.onSurfaceVariant),
        ]),
      );
}

class _InformationSection extends StatelessWidget {
  const _InformationSection(
      {required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(AppSpacing.xl),
          leading: _IconBadge(icon: icon),
          title: Text(title, style: context.textStyles.h3),
          shape: const Border(),
          collapsedShape: const Border(),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [Text(text, style: context.textStyles.body)],
        ),
      );
}

class _AppearanceChoices extends StatelessWidget {
  const _AppearanceChoices({required this.controller});
  final ThemeModeController controller;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: controller,
        builder: (context, mode, _) =>
            LayoutBuilder(builder: (context, constraints) {
          final stacked = MediaQuery.textScalerOf(context).scale(16) > 22 ||
              constraints.maxWidth < 260;
          final choices = <Widget>[
            for (final entry in const {
              ThemeMode.system: 'System',
              ThemeMode.light: 'Light',
              ThemeMode.dark: 'Dark'
            }.entries)
              SizedBox(
                width: stacked
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 3,
                child: AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  selected: mode == entry.key,
                  backgroundColor: mode == entry.key
                      ? context.colors.surfaceContainer
                      : context.colors.primaryContainer,
                  onTap: () => controller.value = entry.key,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        mode == entry.key
                            ? Icons.check_circle_rounded
                            : switch (entry.key) {
                                ThemeMode.system =>
                                  Icons.brightness_auto_rounded,
                                ThemeMode.light => Icons.light_mode_outlined,
                                ThemeMode.dark => Icons.dark_mode_outlined,
                              },
                        color: context.colors.primary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(entry.value,
                        textAlign: TextAlign.center,
                        style: context.textStyles.body.copyWith(
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
          ];
          return Wrap(spacing: 8, runSpacing: 8, children: choices);
        }),
      );
}
