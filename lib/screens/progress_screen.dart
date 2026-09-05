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

class _DomainStats {
  const _DomainStats(this.domainId, this.correct, this.seen);
  final String domainId;
  final int correct;
  final int seen;
}

/// No fabricated activity/trend/breakdown: every value below comes from
/// [ProgressRepository] queries (optional — see [progressRepository]'s doc
/// comment), never a widget-local literal. See docs/PROTOTYPE_CONTENT_AUDIT.md
/// for the fabricated weekly-activity/streak/mastery numbers this replaced.
class ProgressScreen extends StatefulWidget {
  static const String route = '/progress';
  const ProgressScreen(
      {super.key, this.progressRepository, this.contentPackage});

  /// Null in production today (no real adapter exists yet) — this screen
  /// then always shows its honest "no progress yet" empty state. When
  /// present (only ever `DebugDemoEnvironment.buildProgressRepository()`,
  /// wired from `lib/main_demo.dart`), the trend/breakdown/history below
  /// reflect exactly what the repository reports.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future != null) return;
    _startLoad();
  }

  void _startLoad() {
    final ProgressRepository? repository = widget.progressRepository;
    final ContentPackage? package = widget.contentPackage;
    if (repository == null || package == null) return;
    final Future<_ProgressData> future = _load(repository, package.exam.id);
    // Attaches a listener immediately, before this Future is ever handed to
    // FutureBuilder: a rejection with no listener attached synchronously
    // enough (e.g. this method called from a gesture callback, well after
    // the widget's initial build) is reported by the zone as an unhandled
    // error the moment it rejects, even though FutureBuilder itself will
    // attach its own listener and render `snapshot.hasError` correctly one
    // frame later — that gap is enough to trip it. This listener only
    // silences that spurious report; the real, user-visible handling still
    // happens via FutureBuilder below.
    // `Future.ignore()` exists exactly for this: it attaches a listener
    // immediately so a rejection is never reported as "unhandled", without
    // consuming or transforming the Future — FutureBuilder below still
    // reports the real error to the user via `snapshot.hasError`, reading
    // this same, unmodified `future`.
    future.ignore();
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

  List<_DomainStats> _domainBreakdown(List<QuestionState> states) {
    final ContentPackage? package = widget.contentPackage;
    if (package == null) return const [];
    final Map<String, Question> byId = {
      for (final q in package.questions) q.id: q,
    };
    final Map<String, _DomainStats> byDomain = {};
    for (final state in states) {
      if (!state.hasBeenAnswered) continue;
      final Question? question = byId[state.questionId];
      if (question == null) continue;
      final _DomainStats prior =
          byDomain[question.domainId] ?? _DomainStats(question.domainId, 0, 0);
      byDomain[question.domainId] = _DomainStats(
        question.domainId,
        prior.correct + state.timesCorrect,
        prior.seen + state.timesSeen,
      );
    }
    return byDomain.values.toList(growable: false);
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
            domainBreakdown: _domainBreakdown(data.questionStates),
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
            Text('Your Progress', style: textStyles.h1),
            const SizedBox(height: AppSpacing.xxl + 2),
            body,
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
    final ContentPackage? package = widget.contentPackage ??
        BootstrapSessionScope.maybeControllerOf(context)
            ?.snapshot
            .contentPackage;
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: ExamOverviewScreen.route),
        builder: (_) => ExamOverviewScreen(
          contentPackage: package,
          progressRepository: widget.progressRepository,
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
  final List<_DomainStats> domainBreakdown;
  final String Function(String domainId) domainName;
  final String Function(ReadinessSnapshot snapshot) bandLabel;
  final double threshold;
  final VoidCallback onOpenExamOverview;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final List<ReadinessSnapshot> trend = [...data.readinessHistory]
      ..sort((a, b) => a.calculatedAt.compareTo(b.calculatedAt));
    final List<MockAttempt> history = [...data.mockAttempts]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(snapshot.calculatedAt),
                          style: textStyles.body),
                      Text(
                        '${snapshot.overallScore.round()}% · ${bandLabel(snapshot)}',
                        style: textStyles.body
                            .copyWith(fontWeight: FontWeight.w700),
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
                progress: stats.seen == 0 ? 0 : stats.correct / stats.seen,
                supportingText: '${stats.correct}/${stats.seen} correct',
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (history.isNotEmpty) ...[
          Text('MOCK EXAM HISTORY', style: textStyles.label),
          const SizedBox(height: AppSpacing.sm),
          for (final attempt in history.where((a) => a.correctCount != null))
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(attempt.startedAt),
                          style: textStyles.body),
                      Text(
                        '${attempt.correctCount}/${attempt.questionIds.length}',
                        style: textStyles.body
                            .copyWith(fontWeight: FontWeight.w700),
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
