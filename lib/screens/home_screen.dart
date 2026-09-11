import '../widgets/study_plan_panel.dart';
import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/repositories/progress_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';
import 'exam_overview_screen.dart';
import 'profile_settings_screen.dart';
import 'progress_screen.dart';
import 'saved_questions_screen.dart';
import 'main_shell.dart';
import '../widgets/app_bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  static const String route = '/home';
  const HomeScreen(
      {super.key, this.progressRepository, this.now = DateTime.now});
  final ProgressRepository? progressRepository;
  final DateTime Function() now;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialized = false;
  bool _wasActive = false;
  int _planRevision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = MainShellScope.activeTabOf(context) == AppTab.home;
    if (widget.progressRepository != null &&
        (!_initialized || (active && !_wasActive))) {
      _initialized = true;
      _planRevision++;
    }
    _wasActive = active;
  }

  Future<void> _openPractice() async {
    final state = BootstrapSessionScope.maybeControllerOf(context);
    await Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: ExamOverviewScreen.route),
      builder: (_) => ExamOverviewScreen(
        contentPackage: state?.snapshot.contentPackage,
        progressRepository: widget.progressRepository,
        entitlement: state?.snapshot.entitlement,
      ),
    ));
    if (mounted) {
      setState(() {
        _planRevision++;
      });
    }
  }

  void _openProgress() {
    final state = BootstrapSessionScope.maybeControllerOf(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProgressScreen(
        contentPackage: state?.snapshot.contentPackage,
        progressRepository: widget.progressRepository,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('RHS PREP', style: styles.label),
                    Text('Your study day', style: styles.h2),
                    Text(
                        BootstrapSessionScope.maybeControllerOf(context)
                                    ?.snapshot
                                    .examDateSelection
                                    ?.date ==
                                null
                            ? 'Exam date not set'
                            : 'Exam · ${MaterialLocalizations.of(context).formatCompactDate(BootstrapSessionScope.controllerOf(context).snapshot.examDateSelection!.date!)}',
                        style: styles.bodySmall)
                  ])),
              Tooltip(
                  message: 'Settings',
                  child: CircleIconButton(
                      icon: Icons.settings_rounded,
                      semanticLabel: 'Settings',
                      onPressed: () async {
                        await Navigator.of(context, rootNavigator: true)
                            .pushNamed(ProfileSettingsScreen.route,
                                arguments:
                                    BootstrapSessionScope.maybeControllerOf(
                                        context));
                        if (mounted) setState(() => _planRevision++);
                      })),
            ]),
            const SizedBox(height: AppSpacing.md),
            if (BootstrapSessionScope.maybeControllerOf(context) != null &&
                widget.progressRepository != null) ...[
              StudyPlanPanel(
                  key: ValueKey(_planRevision),
                  session: BootstrapSessionScope.controllerOf(context),
                  repository: widget.progressRepository!,
                  now: widget.now),
              const SizedBox(height: AppSpacing.md),
            ],
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        widget.progressRepository == null
                            ? 'Build your confidence'
                            : 'Free practice',
                        style: styles.h3),
                    Text(
                        'Choose topics, saved questions or another practice mode.',
                        style: styles.bodySmall),
                    if (widget.progressRepository == null)
                      PrimaryButton(
                          label: 'Start Practicing', onPressed: _openPractice)
                    else
                      TextButton.icon(
                          onPressed: _openPractice,
                          icon: const Icon(Icons.auto_stories_rounded),
                          label: const Text('Browse practice modes')),
                  ]),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Explore', style: styles.h3),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: _openProgress,
              child: Row(children: [
                Icon(Icons.insights_rounded, color: colors.secondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('View your progress', style: styles.h3),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Accuracy, topics and exam history',
                        style: styles.bodySmall),
                  ],
                )),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: () {
                final state = BootstrapSessionScope.maybeControllerOf(context);
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => SavedQuestionsScreen(
                    contentPackage: state?.snapshot.contentPackage,
                    progressRepository: widget.progressRepository,
                  ),
                ));
              },
              child: Row(children: [
                Icon(Icons.bookmark_rounded, color: colors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved questions', style: styles.h3),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Answers & explanations, ready to review',
                        style: styles.bodySmall),
                  ],
                )),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
