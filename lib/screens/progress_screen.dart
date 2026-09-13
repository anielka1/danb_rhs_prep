import '../progress/learning_progress.dart';
import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/models/mock_attempt.dart';
import '../domain/models/question_state.dart';
import '../domain/models/readiness_snapshot.dart';
import '../domain/repositories/progress_repository.dart';
import '../features/content/domain/content_package.dart';
import '../features/exams/domain/exam_config.dart';
import '../features/questions/domain/question.dart';
import '../mock_exam/mock_exam_blueprint.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import 'exam_overview_screen.dart';
import 'main_shell.dart';
import '../widgets/app_bottom_navigation.dart';

class _ProgressData {
  const _ProgressData({
    required this.progress,
    required this.readinessHistory,
    required this.questionStates,
    required this.mockAttempts,
  });

  final LearningProgress progress;
  final List<ReadinessSnapshot> readinessHistory;
  final List<QuestionState> questionStates;
  final List<MockAttempt> mockAttempts;

  bool get hasAnyData =>
      readinessHistory.isNotEmpty ||
      questionStates.any((s) => s.hasBeenAnswered) ||
      mockAttempts.isNotEmpty;
}

/// Per-domain answer accuracy, aggregated from [QuestionState]s already
/// seen. Exposed (not file-private) and `@visibleForTesting` so
/// [aggregateDomainBreakdown]'s edge cases — zero-evidence domains,
/// question ids no longer present in content — can be unit-tested directly,
/// without going through a full widget pump.
@visibleForTesting
class DomainStats {
  const DomainStats(this.domainId, this.correct, this.seen);
  final String domainId;
  final int correct;
  final int seen;

  /// 0 when [seen] is zero — never NaN or a division-by-zero artifact.
  /// [aggregateDomainBreakdown] only ever adds a domain here from a
  /// [QuestionState] with `hasBeenAnswered == true` (which itself implies
  /// `timesSeen > 0`), so `seen == 0` shouldn't currently occur in
  /// practice — this guard exists so that stays true by construction
  /// rather than by accident if that aggregation logic ever changes.
  double get accuracy => seen == 0 ? 0 : correct / seen;
}

/// Groups [states] by the domain of the question each answers (looked up
/// in [questions] by id), summing times-correct/times-seen per domain.
/// States for a question id no longer present in [questions] (e.g.
/// retired/removed content) are skipped rather than throwing — a
/// [QuestionState] can outlive the specific content version it was
/// recorded against.
@visibleForTesting
List<DomainStats> aggregateDomainBreakdown(
  List<QuestionState> states,
  List<Question> questions,
) {
  final Map<String, Question> byId = {for (final q in questions) q.id: q};
  final Map<String, DomainStats> byDomain = {};
  for (final state in states) {
    if (!state.hasBeenAnswered) continue;
    final Question? question = byId[state.questionId];
    if (question == null) continue;
    final DomainStats prior =
        byDomain[question.domainId] ?? DomainStats(question.domainId, 0, 0);
    byDomain[question.domainId] = DomainStats(
      question.domainId,
      prior.correct + state.timesCorrect,
      prior.seen + state.timesSeen,
    );
  }
  return byDomain.values.toList(growable: false);
}

/// A defensive copy of [snapshots], sorted oldest-first — a real
/// repository has no ordering guarantee, so this screen (not the caller)
/// is responsible for turning readiness history into a genuine
/// chronological trend rather than whatever order it happened to arrive
/// in.
@visibleForTesting
List<ReadinessSnapshot> chronologicalReadinessHistory(
  List<ReadinessSnapshot> snapshots,
) {
  final List<ReadinessSnapshot> sorted = [...snapshots];
  sorted.sort((a, b) => a.calculatedAt.compareTo(b.calculatedAt));
  return sorted;
}

/// Only [MockAttemptStatus.completed] attempts, most recent first — an
/// in-progress attempt has no [MockAttempt.correctCount]/outcome yet and
/// must never appear in a "history of results" list.
@visibleForTesting
List<MockAttempt> completedMockHistory(List<MockAttempt> attempts) {
  final List<MockAttempt> completed =
      attempts.where((a) => a.status == MockAttemptStatus.completed).toList();
  completed.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  return completed;
}

/// No fabricated activity/trend/breakdown: every value below comes from
/// [ProgressRepository] queries (optional — see [progressRepository]'s doc
/// comment), never a widget-local literal. See docs/PROTOTYPE_CONTENT_AUDIT.md
/// for the fabricated weekly-activity/streak/mastery numbers this replaced.
/// Production wires a real `DriftProgressRepository`, so the trend/
/// breakdown/history below reflect genuine on-device history there too —
/// a fresh install simply has none yet, so it honestly shows the empty
/// state below until the user has actually answered questions.
class ProgressScreen extends StatefulWidget {
  static const String route = '/progress';
  const ProgressScreen(
      {super.key, this.progressRepository, this.contentPackage});

  /// A real `DriftProgressRepository` in production (`main.dart`'s
  /// default); the trend/breakdown/history below reflect exactly what the
  /// repository reports, empty or not. Null only when a caller has
  /// nothing to query at all (e.g. `lib/main_demo.dart`, which supplies
  /// its own `DebugDemoEnvironment.buildProgressRepository()` instead).
  final ProgressRepository? progressRepository;

  /// Needed alongside [progressRepository] for the exam id to query by and
  /// for resolving each [QuestionState]'s domain — threaded in as a plain
  /// constructor value from `MainShell`'s own ambient
  /// `BootstrapSessionScope`, the same pattern `ExamOverviewScreen`/
  /// `MockExamScreen` already use and for the same reason (this screen can
  /// also be reached by `Navigator.push`, a sibling route that cannot see
  /// that ambient scope itself).
  final ContentPackage? contentPackage;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Future<_ProgressData>? _future;

  /// Guards against a second, concurrent load — e.g. the error state's
  /// retry action tapped (or otherwise invoked) more than once before the
  /// first attempt has settled and this widget has had a chance to
  /// rebuild. Deliberately not surfaced via `setState`: this only ever
  /// needs to suppress a *duplicate* request, not drive any visible UI —
  /// the in-flight request's own `LoadingState` (via `FutureBuilder`)
  /// already covers that.
  bool _loading = false;
  bool _wasActive = false;
  bool _refreshAfterLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = MainShellScope.activeTabOf(context) == AppTab.progress;
    final entering = active && !_wasActive;
    _wasActive = active;
    if (_future == null || entering) {
      if (_loading) {
        _refreshAfterLoad = true;
      } else {
        _startLoad();
      }
    }
  }

  void _loadFinished() {
    _loading = false;
    if (_refreshAfterLoad && mounted) {
      _refreshAfterLoad = false;
      _startLoad();
    }
  }

  void _startLoad() {
    if (_loading) return;
    final ProgressRepository? repository = widget.progressRepository;
    final ContentPackage? package = widget.contentPackage;
    if (repository == null || package == null) return;
    _loading = true;
    final Future<_ProgressData> future = _load(repository, package.exam.id);
    // Attaches a listener immediately, before this Future is ever handed
    // to FutureBuilder: a rejection with no listener attached
    // synchronously enough (e.g. this method called from a gesture
    // callback, well after the widget's initial build) is reported by the
    // zone as an unhandled error the moment it rejects, even though
    // FutureBuilder itself will attach its own listener and render
    // `snapshot.hasError` correctly one frame later — that gap is enough
    // to trip it. Resetting `_loading` here (rather than via a second,
    // separate listener) keeps this the single place that "this load has
    // finished, one way or another" is recorded.
    future.then(
      (_) => _loadFinished(),
      onError: (Object _, StackTrace __) => _loadFinished(),
    );
    setState(() {
      _future = future;
    });
  }

  Future<_ProgressData> _load(
      ProgressRepository repository, String examId) async {
    final List<ReadinessSnapshot> readinessHistory =
        await repository.readinessSnapshotsForExam(examId);
    final List<QuestionState> questionStates =
        await repository.questionStatesForExam(examId);
    final List<MockAttempt> mockAttempts =
        await repository.mockAttemptsForExam(examId);
    return _ProgressData(
      progress: LearningProgress.fromHistory(
          package: widget.contentPackage!,
          attempts: await repository.answerAttemptsForExam(examId),
          mocks: mockAttempts),
      readinessHistory: readinessHistory,
      questionStates: questionStates,
      mockAttempts: mockAttempts,
    );
  }

  String _domainName(String domainId) {
    final List<DomainConfig> domains =
        widget.contentPackage?.exam.domains ?? const [];
    for (final domain in domains) {
      if (domain.id == domainId) return domain.name;
    }
    return domainId;
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.8;
    final Future<_ProgressData>? future = _future;

    Widget body;
    if (future == null) {
      body = _emptyState();
    } else {
      body = FutureBuilder<_ProgressData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading your progress…');
          }
          if (snapshot.hasError) {
            return ErrorState(
              title: 'Could not load your progress',
              message: 'Please try again.',
              onRetry: _startLoad,
            );
          }
          final _ProgressData data = snapshot.data!;
          return _ProgressContent(
            data: data,
            onPractice: () => _openExamOverview(context),
            domainName: _domainName,
            threshold:
                widget.contentPackage!.exam.mockExam.practicePassingPercent,
          );
        },
      );
    }

    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            if (!large) Text('YOUR LEARNING', style: textStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Text('Your Progress', style: large ? textStyles.h3 : textStyles.h1),
            const SizedBox(height: AppSpacing.sm),
            Text('Based on your latest answer to each question',
                style: textStyles.body),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.contentPackage?.questions
                          .any((q) => q.tags.contains('demo')) ==
                      true
                  ? 'Demo includes sample history. These results do not assess your exam readiness.'
                  : 'Accuracy reflects recorded answers, not your chance of passing. A personalized readiness estimate is not available yet.',
              style: textStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(padding: const EdgeInsets.all(AppSpacing.xl), child: body),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return EmptyState(
      icon: Icons.insights_rounded,
      title: 'No progress yet',
      message: 'Your recorded activity and question progress will '
          'appear here once you start practicing.',
      primaryActionLabel: 'Start Practicing',
      onPrimaryAction: () => _openExamOverview(context),
    );
  }

  // Not `Navigator.pushNamed`: see `HomeScreen._openExamOverview`'s doc
  // comment for why `ExamOverviewScreen` needs its content threaded in
  // directly rather than read from an ambient scope. The nullable,
  // non-asserting scope lookup — used only as a fallback when
  // `widget.contentPackage` is itself null — so this action stays safe to
  // reach in a test/context that never supplied a `BootstrapSessionScope`
  // ancestor at all, exactly like `MainShell`'s own contentPackage lookup.
  Future<void> _openExamOverview(BuildContext context) async {
    final session = BootstrapSessionScope.maybeControllerOf(context);
    final ContentPackage? package =
        widget.contentPackage ?? session?.snapshot.contentPackage;
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: ExamOverviewScreen.route),
        builder: (_) => ExamOverviewScreen(
          contentPackage: package,
          progressRepository: widget.progressRepository,
          entitlement: session?.snapshot.entitlement,
        ),
      ),
    );
    if (mounted) _startLoad();
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent(
      {required this.data,
      required this.domainName,
      required this.threshold,
      required this.onPractice});
  final _ProgressData data;
  final String Function(String) domainName;
  final double threshold;
  final VoidCallback onPractice;
  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final progress = data.progress;
    final sectionStyle = MediaQuery.textScalerOf(context).scale(1) >= 1.8
        ? styles.body.copyWith(fontWeight: FontWeight.w800)
        : styles.h3;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Counts(progress.total, key: const ValueKey('bank-progress-counts')),
      if (progress.total.total == 0)
        const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
                'No approved questions are available yet. Your history is preserved.')),
      const SizedBox(height: 28),
      Text('Progress by subject', style: sectionStyle),
      for (final entry in progress.domains.entries)
        Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(domainName(entry.key),
                      style: styles.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _Counts(entry.value),
                ])),
      const SizedBox(height: 28),
      Text('Daily activity', style: sectionStyle),
      if (progress.days.isEmpty) const Text('No answers recorded yet.'),
      for (final day in progress.days)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
                '${day.date} · ${day.correct} correct · ${day.incorrect} incorrect · ${day.answers} answers',
                style: styles.body)),
      if (progress.hasMockDetailLimitation)
        Text(
            'Older mock scores contribute to daily totals when reliable. Their question-level grades were not saved. Those questions are marked Grade unavailable unless a later graded answer exists. Partially imported mock history is not expanded.',
            style: styles.bodySmall),
      TextButton(onPressed: onPractice, child: const Text('Practice More')),
      if (completedMockHistory(data.mockAttempts).isNotEmpty) ...[
        const SizedBox(height: 28),
        Text('MOCK EXAM HISTORY', style: styles.label),
        for (final attempt in completedMockHistory(data.mockAttempts))
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                  '${_formatDate(attempt.startedAt)} · ${attempt.correctCount}/${attempt.questionIds.length} · ${MockExamResult.outcomeFor(correctCount: attempt.correctCount!, totalQuestions: attempt.questionIds.length, thresholdPercent: threshold)}',
                  style: styles.body)),
      ],
    ]);
  }
}

class _Counts extends StatelessWidget {
  const _Counts(this.counts, {super.key});
  final QuestionCounts counts;
  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.8;
    final colors = [
      context.semanticColors.success,
      context.semanticColors.warning,
      context.colors.outlineVariant,
      context.colors.secondary
    ];
    final values = [
      counts.correct,
      counts.needsReview,
      counts.notAttempted,
      if (counts.gradeUnavailable > 0) counts.gradeUnavailable
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('${counts.total} available questions',
          style: context.textStyles.bodySmall),
      const SizedBox(height: 8),
      Wrap(spacing: 16, runSpacing: 8, children: [
        for (var i = 0; i < values.length; i++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            ExcludeSemantics(
                child: Icon(Icons.circle, size: 9, color: colors[i])),
            const SizedBox(width: 6),
            Flexible(
                child: Text(
                    '${values[i]} ${[
                      'Correct',
                      'Needs review',
                      'Not attempted',
                      'Grade unavailable'
                    ][i]}',
                    style: large
                        ? context.textStyles.bodySmall
                        : context.textStyles.body)),
          ]),
      ]),
      const SizedBox(height: 10),
      if (counts.total > 0)
        Semantics(
            label:
                '${counts.correct} correct, ${counts.needsReview} need review, ${counts.notAttempted} not attempted, ${counts.gradeUnavailable} grades unavailable',
            child: ExcludeSemantics(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                        height: 10,
                        child: Row(children: [
                          for (var i = 0; i < values.length; i++)
                            if (values[i] > 0)
                              Expanded(
                                  flex: values[i],
                                  child: ColoredBox(
                                      color: colors[i],
                                      child: const SizedBox.expand())),
                        ]))))),
    ]);
  }
}

String _formatDate(DateTime date) {
  const List<String> monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${monthNames[date.month - 1]} ${date.day}';
}
