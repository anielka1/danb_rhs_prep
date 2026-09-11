import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/models/answer_attempt.dart';
import '../domain/models/practice_session.dart';
import '../domain/repositories/progress_repository.dart';
import '../practice_session/practice_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';
import '../widgets/app_bottom_navigation.dart';
import 'diagnostic_screen.dart';
import 'exam_overview_screen.dart';
import 'profile_settings_screen.dart';
import 'progress_screen.dart';
import 'saved_questions_screen.dart';
import 'main_shell.dart';

/// A session launcher and a view of recorded work. No scheduling or daily goals.
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
  bool _initialized = false,
      _wasActive = false,
      _loading = true,
      _failed = false;
  int _revision = 0;
  bool _opening = false;
  PracticeSession? _active;
  List<AnswerAttempt> _attempts = const [];
  int _saved = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = MainShellScope.activeTabOf(context) == AppTab.home;
    if (!_initialized || active && !_wasActive) {
      _initialized = true;
      _load();
    }
    _wasActive = active;
  }

  Future<void> _load() async {
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final repo = widget.progressRepository;
    final snap = BootstrapSessionScope.maybeControllerOf(context)?.snapshot;
    try {
      final active = repo != null && snap != null
          ? await repo.inProgressPracticeSession(snap.selectedExamId)
          : null;
      final attempts = repo != null && snap != null
          ? await repo.answerAttemptsForExam(snap.selectedExamId)
          : <AnswerAttempt>[];
      final states = repo != null && snap != null
          ? await repo.questionStatesForExam(snap.selectedExamId)
          : null;
      if (!mounted || revision != _revision) return;
      setState(() {
        _active = active;
        _attempts = attempts;
        _saved = states?.where((s) => s.bookmarked).length ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _open(Widget screen) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));
    } finally {
      if (mounted) {
        setState(() => _opening = false);
        await _load();
      }
    }
  }

  Future<void> _practice({bool start = false}) async {
    final session = BootstrapSessionScope.maybeControllerOf(context);
    if (start && _active?.mode == PracticeMode.diagnostic && session != null) {
      await _open(DiagnosticScreen(session: session));
    } else {
      await _open(ExamOverviewScreen(
          contentPackage: session?.snapshot.contentPackage,
          progressRepository: widget.progressRepository,
          entitlement: session?.snapshot.entitlement,
          now: widget.now,
          autoStart: start));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = BootstrapSessionScope.maybeControllerOf(context);
    final package = session?.snapshot.contentPackage;
    var eligible = 0;
    if (package != null && package.questions.isNotEmpty) {
      try {
        eligible = PracticeGenerator.select(
                package: package,
                questionStates: const [],
                requestedCount: package.questions.length)
            .questions
            .length;
      } on PracticeGenerationUnavailable {/* Explicit no-material state. */}
    }
    final hasWork = _attempts.isNotEmpty;
    final answered = _attempts.map((a) => a.questionId).toSet().length;
    final correct = _attempts.where((a) => a.isCorrect).length;
    final styles = context.textStyles;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 2;
    final colors = context.colors;
    return AppScaffold(
        body: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('RHS PREP', style: styles.label),
          Text('Your study space', style: largeText ? styles.h3 : styles.h1)
        ])),
        Tooltip(
            message: 'Settings',
            child: CircleIconButton(
                icon: Icons.settings_rounded,
                semanticLabel: 'Settings',
                onPressed: () async {
                  await Navigator.of(context, rootNavigator: true).pushNamed(
                      ProfileSettingsScreen.route,
                      arguments: session);
                  if (mounted) await _load();
                }))
      ]),
      const SizedBox(height: AppSpacing.xl),
      AppCard(
          backgroundColor: colors.primaryContainer,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.auto_stories_rounded,
                size: 36, color: colors.onPrimaryContainer),
            const SizedBox(height: AppSpacing.lg),
            Text(
                _active != null
                    ? 'Pick up where you left off.'
                    : 'Make room for learning.',
                style: largeText
                    ? styles.body.copyWith(fontWeight: FontWeight.w700)
                    : styles.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(
                _loading
                    ? 'Loading your saved work…'
                    : _failed
                        ? 'Your progress could not be loaded. Retry to safely continue.'
                        : _active != null
                            ? 'Your questions and answers are saved. Continue at your own pace.'
                            : eligible == 0
                                ? 'Questions are being prepared for review. Your saved progress stays here.'
                                : 'A few questions, clear explanations. Study at your own pace.',
                style: styles.body),
            const SizedBox(height: AppSpacing.xl),
            if (_failed)
              PrimaryButton(label: 'Retry', onPressed: _load)
            else
              PrimaryButton(
                  label:
                      _active != null ? 'Continue learning' : 'Start learning',
                  isLoading: _loading,
                  onPressed:
                      _loading || _opening || eligible == 0 && _active == null
                          ? null
                          : () => _practice(start: true)),
          ])),
      const SizedBox(height: AppSpacing.xl),
      Text('Your progress', style: styles.h3),
      const SizedBox(height: AppSpacing.md),
      if (_loading)
        const LinearProgressIndicator(semanticsLabel: 'Loading progress')
      else if (_failed)
        Text('Progress is temporarily unavailable.', style: styles.bodySmall)
      else if (!hasWork)
        Text(
            'Your first answer starts the story. Recorded practice and starting-check answers will appear here.',
            style: styles.body)
      else
        Wrap(spacing: AppSpacing.xl, runSpacing: AppSpacing.md, children: [
          _Metric(value: '$answered', label: 'Questions explored'),
          _Metric(value: '${_attempts.length}', label: 'Answers recorded'),
          _Metric(
              value: '${(100 * correct / _attempts.length).round()}%',
              label: 'Answer accuracy'),
        ]),
      if (hasWork && !_failed)
        Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
                'Based on recorded answers, including repeated questions. Not a prediction of passing.',
                style: styles.bodySmall)),
      const SizedBox(height: AppSpacing.xl),
      _StudyLink(
          icon: Icons.bookmark_rounded,
          title: 'Saved questions',
          detail: _loading || _failed
              ? 'Answers and explanations'
              : '$_saved saved · answers and explanations',
          onTap: () => _open(SavedQuestionsScreen(
              contentPackage: package,
              progressRepository: widget.progressRepository))),
      _StudyLink(
          icon: Icons.insights_rounded,
          title: 'Explore progress',
          detail: 'Topics, accuracy and exam history',
          onTap: () => _open(ProgressScreen(
              contentPackage: package,
              progressRepository: widget.progressRepository))),
      _StudyLink(
          icon: Icons.tune_rounded,
          title: 'Practice your way',
          detail: 'Choose topics and session length',
          onTap: () => _practice()),
      if (session != null)
        _StudyLink(
            icon: Icons.explore_outlined,
            title: 'Starting check',
            detail: 'Optional · discover areas to revisit',
            onTap: () => _open(DiagnosticScreen(session: session))),
      const SizedBox(height: AppSpacing.lg),
    ])));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: context.textStyles.h2),
        Text(label, style: context.textStyles.bodySmall)
      ]);
}

class _StudyLink extends StatelessWidget {
  const _StudyLink(
      {required this.icon,
      required this.title,
      required this.detail,
      required this.onTap});
  final IconData icon;
  final String title, detail;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          leading: Icon(icon, color: context.colors.primary),
          title: Text(title, style: context.textStyles.h3),
          subtitle: Text(detail, style: context.textStyles.bodySmall),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap));
}
