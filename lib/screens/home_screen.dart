import '../domain/models/mock_attempt.dart';
import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/models/answer_attempt.dart';
import '../domain/models/practice_session.dart';
import '../domain/repositories/progress_repository.dart';
import '../practice_session/practice_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../progress/learning_progress.dart';
import 'mock_exam_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _initialized && mounted) _load();
  }

  bool _initialized = false,
      _wasActive = false,
      _loading = true,
      _failed = false;
  int _revision = 0;
  bool _opening = false;
  PracticeSession? _active;
  bool _activeMock = false;
  int _saved = 0;
  LearningProgress? _progress;
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
      final mocks = repo != null && snap != null
          ? await repo.mockAttemptsForExam(snap.selectedExamId)
          : <MockAttempt>[];
      final states = repo != null && snap != null
          ? await repo.questionStatesForExam(snap.selectedExamId)
          : null;
      if (!mounted || revision != _revision) return;
      setState(() {
        _active = active;
        _activeMock =
            mocks.any((m) => m.status == MockAttemptStatus.inProgress);
        _saved = states?.where((s) => s.bookmarked).length ?? 0;
        _progress = snap == null
            ? null
            : LearningProgress.fromHistory(
                package: snap.contentPackage, attempts: attempts, mocks: mocks);
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
    final bootstrap = BootstrapSessionScope.maybeControllerOf(context);
    try {
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => BootstrapSessionScope.carry(bootstrap, screen)));
    } finally {
      if (mounted) {
        setState(() => _opening = false);
        await _load();
      }
    }
  }

  Future<void> _practice({bool start = false}) async {
    final session = BootstrapSessionScope.maybeControllerOf(context);
    if (start && _active == null && _activeMock) {
      await _open(MockExamScreen(
          contentPackage: session?.snapshot.contentPackage,
          progressRepository: widget.progressRepository,
          now: widget.now));
      return;
    }
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

  Future<void> _launch(PracticeLaunch mode) async {
    final session = BootstrapSessionScope.maybeControllerOf(context);
    await _open(ExamOverviewScreen(
      contentPackage: session?.snapshot.contentPackage,
      progressRepository: widget.progressRepository,
      entitlement: session?.snapshot.entitlement,
      now: widget.now,
      launch: mode,
      autoStart: mode != PracticeLaunch.topic && mode != PracticeLaunch.timed,
    ));
  }

  Future<void> _settings({bool date = false}) async {
    final session = BootstrapSessionScope.maybeControllerOf(context);
    await Navigator.of(context, rootNavigator: true).pushNamed(
        date ? '/settings/exam-date' : ProfileSettingsScreen.route,
        arguments: session);
    if (mounted) await _load();
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
      } on PracticeGenerationUnavailable {/* Honest content gate. */}
    }
    final progress = _progress;
    final mistakes = progress?.total.needsReview ?? 0;
    final examDate = session?.snapshot.examDateSelection?.date;
    final current = widget.now();
    final days = examDate == null
        ? null
        : DateTime.utc(examDate.year, examDate.month, examDate.day)
            .difference(DateTime.utc(current.year, current.month, current.day))
            .inDays;
    final styles = context.textStyles;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.8;
    final available = !_loading && !_failed && !_opening && eligible > 0;
    final blue = dark ? AppHomeColors.progressDark : AppHomeColors.progress;
    final dateLabel = days == null
        ? 'Set exam date'
        : days < 0
            ? 'Exam date passed · Update date'
            : days == 0
                ? 'Exam today'
                : '$days days to exam';
    final calendar = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _settings(date: true),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    color: AppHomeColors.onProgress, size: 18),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(dateLabel,
                        style: styles.bodySmall
                            .copyWith(color: AppHomeColors.onProgress))),
              ])),
        ));
    final values = [
      _TodayMetric('Correct',
          _failed || _loading ? '—' : '${progress?.total.correct ?? 0}'),
      _TodayMetric('Needs review', _failed || _loading ? '—' : '$mistakes'),
      _TodayMetric(
          'Correct today',
          _failed || _loading
              ? '—'
              : '${progress?.correctToday(widget.now()) ?? 0}'),
    ];
    final metrics = large
        ? Column(
            key: const ValueKey('home-progress-metrics'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: values)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final metric in values) Expanded(child: metric)]);
    return Scaffold(
      backgroundColor: dark ? AppHomeColors.canvasDark : AppHomeColors.canvas,
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child:
                    Text('Let’s study', style: large ? styles.h3 : styles.h1)),
            Tooltip(
                message: 'Settings',
                child: CircleIconButton(
                    icon: Icons.settings_rounded,
                    semanticLabel: 'Settings',
                    onPressed: _settings))
          ]),
          const SizedBox(height: 20),
          AppCard(
              backgroundColor: blue,
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Your progress',
                        style: styles.h3
                            .copyWith(color: AppHomeColors.onProgress)),
                    const SizedBox(height: 16),
                    calendar,
                    const SizedBox(height: 12),
                    metrics,
                    const SizedBox(height: 10),
                    Text(
                        'Correct and Needs review: latest answers. Today includes repeat answers.',
                        style: styles.bodySmall
                            .copyWith(color: AppHomeColors.onProgress)),
                  ])),
          if (!_failed &&
              !_loading &&
              (progress?.total.gradeUnavailable ?? 0) > 0)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                    '${progress!.total.gradeUnavailable} questions have older mock answers without saved grades. See Progress for details.')),
          if (_loading)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(
                    semanticsLabel: 'Loading progress')),
          if (_failed) ...[
            const SizedBox(height: 12),
            const Text(
                'Your saved progress could not be loaded. Retry to safely continue.'),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ] else if (!_loading && eligible == 0) ...[
            const SizedBox(height: 12),
            const Text(
                'No approved practice questions are available yet. Your saved progress is preserved.'),
          ],
          if ((_active != null || _activeMock) && !_loading && !_failed)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SecondaryButton(
                    label: 'Continue session',
                    onPressed: _opening ? null : () => _practice(start: true))),
          const SizedBox(height: 24),
          Text('Choose your practice', style: styles.h3),
          const SizedBox(height: 12),
          _ActivityTile(
              icon: Icons.shuffle_rounded,
              title: 'Practise questions',
              detail: 'One question. A fresh perspective.',
              onTap: available ? () => _launch(PracticeLaunch.random) : null),
          _ActivityTile(
              icon: Icons.category_outlined,
              title: 'Practice by topics',
              detail: 'Focus on one part of the exam.',
              onTap: available ? () => _launch(PracticeLaunch.topic) : null),
          _ActivityTile(
              icon: Icons.bookmark_border_rounded,
              title: 'Saved questions',
              detail: _loading || _failed
                  ? 'Your answer library'
                  : '$_saved saved · answers and explanations',
              onTap: _opening
                  ? null
                  : () => _open(SavedQuestionsScreen(
                      contentPackage: package,
                      progressRepository: widget.progressRepository))),
          _ActivityTile(
              icon: Icons.replay_rounded,
              title: 'Review mistakes',
              detail: _loading || _failed
                  ? 'Waiting for your history'
                  : mistakes == 0
                      ? 'No mistakes to review'
                      : 'Questions whose latest answer was incorrect.',
              onTap: available && mistakes > 0
                  ? () => _launch(PracticeLaunch.mistakes)
                  : null),
          _ActivityTile(
              icon: Icons.assignment_outlined,
              title: 'Mock exam',
              detail: 'A full practice exam, with saved progress.',
              onTap: _opening
                  ? null
                  : () => _open(MockExamScreen(
                      contentPackage: package,
                      progressRepository: widget.progressRepository,
                      now: widget.now))),
          const SizedBox(height: 8),
          TextButton.icon(
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Optional starting check'),
              onPressed: session == null || _opening
                  ? null
                  : () => _open(DiagnosticScreen(session: session))),
          TextButton.icon(
              icon: const Icon(Icons.insights_outlined),
              label: const Text('Explore progress'),
              onPressed: _opening
                  ? null
                  : () => _open(ProgressScreen(
                      contentPackage: package,
                      progressRepository: widget.progressRepository))),
        ]),
      )),
    );
  }
}

class _TodayMetric extends StatelessWidget {
  const _TodayMetric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: context.textStyles.h2.copyWith(
                color: AppHomeColors.onProgress, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            style: context.textStyles.bodySmall
                .copyWith(color: AppHomeColors.onProgress)),
      ]));
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile(
      {required this.icon,
      required this.title,
      required this.detail,
      this.onTap});
  final IconData icon;
  final String title, detail;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final large = MediaQuery.textScalerOf(context).scale(1) >= 2;
    final colors = context.colors;
    final texts =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: context.textStyles.body.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(detail, style: context.textStyles.bodySmall),
    ]);
    final glyph = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: colors.onPrimaryContainer));
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(
            button: true,
            enabled: onTap != null,
            child: Material(
              color: dark ? colors.surfaceContainer : AppHomeColors.onProgress,
              elevation: 2,
              shadowColor: AppHomeColors.shadow,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: large
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  glyph,
                                  const SizedBox(height: 12),
                                  texts
                                ])
                          : Row(children: [
                              glyph,
                              const SizedBox(width: 16),
                              Expanded(child: texts),
                              const SizedBox(width: 8),
                              Icon(
                                  onTap == null
                                      ? Icons.remove_rounded
                                      : Icons.chevron_right_rounded,
                                  size: 20,
                                  color: colors.primary)
                            ]))),
            )));
  }
}
