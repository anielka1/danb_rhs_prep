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
import '../widgets/domain_progress_row.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/primary_button.dart';
import 'exam_overview_screen.dart';

class _ProgressData {
  const _ProgressData({
    required this.readinessHistory,
    required this.questionStates,
    required this.mockAttempts,
  });

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future != null) return;
    _startLoad();
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
      (_) => _loading = false,
      onError: (Object _, StackTrace __) => _loading = false,
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

  String _bandLabel(ReadinessSnapshot snapshot) {
    final List<ReadinessThreshold> thresholds =
        widget.contentPackage?.exam.readiness.thresholds ?? const [];
    for (final threshold in thresholds) {
      if (threshold.band == snapshot.band) return threshold.label;
    }
    return snapshot.band.name;
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
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
          if (!data.hasAnyData) return _emptyState();
          return _ProgressContent(
            data: data,
            domainBreakdown: aggregateDomainBreakdown(
              data.questionStates,
              widget.contentPackage!.questions,
            ),
            domainName: _domainName,
            bandLabel: _bandLabel,
            threshold:
                widget.contentPackage!.exam.mockExam.practicePassingPercent,
            onOpenExamOverview: () => _openExamOverview(context),
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
            Text('YOUR LEARNING', style: textStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Text('Your Progress', style: textStyles.h1),
            const SizedBox(height: AppSpacing.sm),
            Text('Progress you can see.', style: textStyles.body),
            const SizedBox(height: AppSpacing.xxl + 2),
            AppCard(padding: const EdgeInsets.all(AppSpacing.xl), child: body),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return EmptyState(
      icon: Icons.insights_rounded,
      title: 'No progress yet',
      message: 'Your activity, accuracy, and subject mastery will '
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
  void _openExamOverview(BuildContext context) {
    final session = BootstrapSessionScope.maybeControllerOf(context);
    final ContentPackage? package =
        widget.contentPackage ?? session?.snapshot.contentPackage;
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: ExamOverviewScreen.route),
        builder: (_) => ExamOverviewScreen(
          contentPackage: package,
          progressRepository: widget.progressRepository,
          entitlement: session?.snapshot.entitlement,
        ),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({
    required this.data,
    required this.domainBreakdown,
    required this.domainName,
    required this.bandLabel,
    required this.threshold,
    required this.onOpenExamOverview,
  });

  final _ProgressData data;
  final List<DomainStats> domainBreakdown;
  final String Function(String domainId) domainName;
  final String Function(ReadinessSnapshot snapshot) bandLabel;
  final double threshold;
  final VoidCallback onOpenExamOverview;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final List<ReadinessSnapshot> trend =
        chronologicalReadinessHistory(data.readinessHistory);
    final List<MockAttempt> history = completedMockHistory(data.mockAttempts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trend.isNotEmpty) ...[
          Text('READINESS TREND', style: textStyles.label),
          const SizedBox(height: AppSpacing.sm),
          for (final snapshot in trend)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Semantics(
                label: '${_formatDate(snapshot.calculatedAt)}: '
                    '${snapshot.overallScore.round()} percent, '
                    '${bandLabel(snapshot)}',
                child: ExcludeSemantics(
                  // Flexible, not a bare Text, on both sides: at large
                  // Dynamic Type sizes (or a long, exam-config-supplied
                  // band label) the two together can exceed the row's
                  // width — each wraps within its own fair share instead
                  // of overflowing off the right edge.
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(_formatDate(snapshot.calculatedAt),
                            style: textStyles.body),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          '${snapshot.overallScore.round()}% · ${bandLabel(snapshot)}',
                          style: textStyles.body
                              .copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
        ],
        if (domainBreakdown.isNotEmpty) ...[
          Text('DOMAIN BREAKDOWN', style: textStyles.label),
          const SizedBox(height: AppSpacing.md),
          for (final stats in domainBreakdown)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: DomainProgressRow(
                domainName: domainName(stats.domainId),
                progress: stats.accuracy,
                supportingText: '${stats.correct}/${stats.seen} correct',
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (history.isNotEmpty) ...[
          Text('MOCK EXAM HISTORY', style: textStyles.label),
          const SizedBox(height: AppSpacing.sm),
          for (final attempt in history)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Semantics(
                label: '${_formatDate(attempt.startedAt)}: '
                    '${attempt.correctCount} of ${attempt.questionIds.length} '
                    'correct, ${MockExamResult.outcomeFor(
                  correctCount: attempt.correctCount!,
                  totalQuestions: attempt.questionIds.length,
                  thresholdPercent: threshold,
                )}',
                child: ExcludeSemantics(
                  // See the Readiness Trend row above for why each side
                  // is Flexible rather than a bare Text.
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(_formatDate(attempt.startedAt),
                            style: textStyles.body),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          '${attempt.correctCount}/${attempt.questionIds.length}',
                          style: textStyles.body
                              .copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
        PrimaryButton(label: 'Practice More', onPressed: onOpenExamOverview),
      ],
    );
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
