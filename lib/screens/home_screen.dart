import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/models/practice_session.dart';
import '../domain/repositories/progress_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/study_page_heading.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/loading_state.dart';
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
  Future<PracticeSession?>? _session;
  bool _wasActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = MainShellScope.activeTabOf(context) == AppTab.home;
    if (widget.progressRepository != null &&
        (_session == null || (active && !_wasActive))) {
      _session = _loadSession();
    }
    _wasActive = active;
  }

  Future<PracticeSession?> _loadSession() async {
    final state = BootstrapSessionScope.maybeControllerOf(context);
    if (state == null) return null;
    return widget.progressRepository
        ?.inProgressPracticeSession(state.snapshot.selectedExamId);
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
      final next = _loadSession();
      setState(() {
        _session = next;
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
            const SizedBox(height: AppSpacing.lg),
            Text('RHS PREP', style: styles.label),
            const SizedBox(height: AppSpacing.md),
            StudyPageHeading(
              title: 'Small steps.\nSteady progress.',
              subtitle: 'Your next study session is ready.',
              icon: Icons.settings_rounded,
              trailing: Tooltip(
                message: 'Settings',
                child: SizedBox(
                  width: 64,
                  height: 72,
                  child: CircleIconButton(
                    icon: Icons.settings_rounded,
                    semanticLabel: 'Settings',
                    onPressed: () => Navigator.of(context, rootNavigator: true)
                        .pushNamed(ProfileSettingsScreen.route,
                            arguments: BootstrapSessionScope.maybeControllerOf(
                                context)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FutureBuilder<PracticeSession?>(
              future: _session,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingState(message: 'Checking your progress…');
                }
                final active = snapshot.data != null;
                return AppCard(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_stories_rounded,
                          color: colors.onPrimary, size: 32),
                      const SizedBox(height: AppSpacing.xl),
                      Text('TODAY’S PRACTICE',
                          style:
                              styles.label.copyWith(color: colors.onPrimary)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                          active
                              ? 'Pick up where you left off'
                              : 'Build your confidence',
                          style: styles.h2.copyWith(color: colors.onPrimary)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                          active
                              ? "You have a practice session you haven't finished yet."
                              : 'Focused questions. Clear explanations. Your pace.',
                          style: styles.body.copyWith(color: colors.onPrimary)),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        label: active ? 'Continue' : 'Start Practicing',
                        trailingIcon: Icons.arrow_forward_rounded,
                        color: colors.surfaceContainer,
                        textColor: colors.onSurface,
                        onPressed: _openPractice,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text('Your learning', style: styles.h3),
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
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }
}
