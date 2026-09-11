import '../study_plan/daily_study_overview.dart';
import '../screens/profile_settings_screen.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../screens/mock_exam_screen.dart';
import '../study_plan/study_metrics.dart';
import '../screens/diagnostic_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_controller.dart';
import '../domain/models/practice_session.dart';
import '../domain/repositories/progress_repository.dart';
import '../practice_session/practice_generator.dart';
import '../practice_session/practice_session_scope.dart';
import '../screens/practice_question_screen.dart';
import '../screens/study_availability_screen.dart';
import '../screens/study_calendar_screen.dart';
import '../study_plan/study_plan.dart';
import '../study_plan/planned_session_service.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'primary_button.dart';

class StudyPlanPanel extends StatefulWidget {
  const StudyPlanPanel(
      {super.key,
      required this.session,
      required this.repository,
      required this.now,
      this.onFinished});
  final BootstrapSessionController session;
  final ProgressRepository repository;
  final DateTime Function() now;
  final VoidCallback? onFinished;
  @override
  State<StudyPlanPanel> createState() => _StudyPlanPanelState();
}

class _StudyPlanPanelState extends State<StudyPlanPanel>
    with WidgetsBindingObserver {
  StudyPlanProjection? _plan;
  DailyStudyOverview? _overview;
  StudyMetrics? _metrics;
  PracticeSession? _active;
  Set<String> _reserve = {};
  int? _quota;
  String? _error;
  bool _busy = false;
  Timer? _timer;
  String? _day;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_day != dateKey(widget.now())) _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final overview = await DailyStudyOverview.load(
          widget.session, widget.repository, widget.now);
      final snapshot = widget.session.snapshot;
      final plan = overview.plan;
      final now = widget.now();
      if (mounted) {
        setState(() {
          _overview = overview;
          _reserve = overview.reserve;
          _quota = overview.quota;
          _metrics = StudyMetrics(
              pool: snapshot.contentPackage.questions,
              history: overview.attempts,
              reviews: plan.reviews,
              today: now);
          _plan = plan;
          _active = overview.active;
          _error = null;
          _day = dateKey(now);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Could not load your study plan. Please retry.');
      }
    }
  }

  Future<void> _availability() async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => StudyAvailabilityScreen(session: widget.session)));
    if (mounted) await _load();
  }

  Future<void> _start({bool diagnostic = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final snapshot = widget.session.snapshot;
      final today = _plan!.days
          .where((d) => d.date == calendarDate(widget.now()))
          .firstOrNull;
      final controller = await const PlannedSessionService().start(
          package: snapshot.contentPackage,
          repository: widget.repository,
          entitlement: snapshot.entitlement,
          now: widget.now,
          day: today,
          diagnostic: diagnostic,
          reservedIds: _reserve);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BootstrapSessionScope.carry(
              widget.session,
              PracticeSessionScope(
                  controller: controller,
                  child: const PracticeQuestionScreen()))));
      if (mounted) await _load();
    } on PracticeGenerationUnavailable catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not start safely. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final today = plan?.days
        .where((d) => d.date == calendarDate(widget.now()))
        .firstOrNull;
    final date = widget.session.snapshot.examDateSelection?.date;
    final progress = _overview?.progress(widget.now());
    return AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Today's plan", style: context.textStyles.h2),
      if (date != null)
        Text(
            calendarDate(date).isBefore(calendarDate(widget.now()))
                ? 'Exam date has passed'
                : '${calendarDate(date).difference(calendarDate(widget.now())).inDays} days to your exam',
            style: context.textStyles.body),
      if (date == null && widget.onFinished == null)
        TextButton(
            onPressed: () async {
              await Navigator.of(context, rootNavigator: true).pushNamed(
                  ProfileSettingsScreen.route,
                  arguments: widget.session);
              if (mounted) await _load();
            },
            child: const Text('Set exam date in Settings')),
      const SizedBox(height: AppSpacing.md),
      if (_error != null) ...[
        Text(_error!, style: context.textStyles.body),
        TextButton(onPressed: _load, child: const Text('Retry'))
      ],
      if (plan == null && _error == null) const CircularProgressIndicator(),
      if (plan != null) ...[
        if (_quota == 0)
          Text(
              'Free practice renews at 00:00 UTC. Your calendar follows local dates.',
              style: context.textStyles.bodySmall),
        if (widget.onFinished == null &&
            plan.condition != PlanCondition.needsAvailability &&
            plan.availableQuestions > 0)
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final d in plan.days
                    .where((d) => !d.date.isBefore(calendarDate(widget.now())))
                    .take(7))
                  Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Chip(
                          label: Text('${const [
                        "Mon",
                        "Tue",
                        "Wed",
                        "Thu",
                        "Fri",
                        "Sat",
                        "Sun"
                      ][d.date.weekday - 1]} ${d.date.day} · ${d.type.name}'))),
              ])),
        if (_error == null &&
            today?.type == StudyDayType.mock &&
            _active == null &&
            widget.onFinished == null)
          PrimaryButton(
              label: 'Open scheduled mock',
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BootstrapSessionScope(
                        controller: widget.session,
                        child: MockExamScreen(
                            progressRepository: widget.repository,
                            now: widget.now))));
                if (mounted) await _load();
              }),
        if (plan.availableQuestions > 0 && widget.onFinished == null)
          Text(
              '${plan.uniqueAnswered} / ${plan.availableQuestions} approved questions explored',
              style: context.textStyles.body),
        const SizedBox(height: AppSpacing.md),
        if (plan.availableQuestions > 0 &&
            plan.condition != PlanCondition.needsAvailability &&
            progress != null) ...[
          Text('${progress.done} completed · ${progress.remaining} remaining',
              style: context.textStyles.h3),
          if (!progress.completed)
            Text(
                '${progress.fresh} new · ${progress.reviews} review${progress.reviews == 1 ? '' : 's'} remaining · about ${((progress.fresh * plan.newSeconds + progress.reviews * plan.reviewSeconds) / 60).ceil()} min'),
          if (progress.remaining > 0)
            const Text(
                'Approximate time includes answering and reading explanations.'),
          if (progress.completed)
            const Text(
                'Daily goal complete. Extra practice is optional and does not increase this goal.'),
        ],
        if (_active != null && _error == null) ...[
          Text('Pick up where you left off', style: context.textStyles.h3),
          if (_active!.mode == PracticeMode.planned &&
              _active!.planDate != dateKey(widget.now()))
            const Text('Continuing your saved plan from an earlier day.'),
          PrimaryButton(
              label: _active!.mode == PracticeMode.planned
                  ? 'Continue planned session'
                  : 'Continue',
              isLoading: _busy,
              onPressed: _start),
        ],
        if (plan.availableQuestions == 0) ...[
          const Text(
              'Approved study questions are not available yet. Your preferences are saved.'),
        ] else if (plan.condition == PlanCondition.needsAvailability) ...[
          const Text(
              'Choose study days and minutes to create your plan. Your existing question goal stays unchanged.'),
          if (_active == null)
            PrimaryButton(
                label: 'Set study availability', onPressed: _availability)
          else
            TextButton(
                onPressed: _availability,
                child: const Text('Set study availability')),
        ] else ...[
          if ((today?.recordedAnswers ?? 0) > 0)
            Text('${today!.recordedAnswers} answers recorded today',
                style: context.textStyles.body),
          Text(
              progress?.completed == true
                  ? "Today's plan completed"
                  : switch (plan.condition) {
                      PlanCondition.emptyPool =>
                        'Approved study questions are not available yet. Your preferences are saved.',
                      PlanCondition.examReached =>
                        'Your exam date has arrived. Update it in Settings to plan more study.',
                      PlanCondition.noStudyDays =>
                        'No selected study days before your exam. Adjust your availability.',
                      PlanCondition.shortReview =>
                        'A short review today. There is limited time to cover new material.',
                      PlanCondition.allAnswered =>
                        'You have explored the available pool. Keep revisiting due questions.',
                      _ => today == null
                          ? 'A day off. Your next session is shown in the calendar.'
                          : 'Your saved session stays available until you finish',
                    },
              style: context.textStyles.body),
          if (plan.availableQuestions > 0 && plan.missingDomains.isNotEmpty)
            Text(
                'Coverage gap: no available questions for ${plan.missingDomains.map((id) => widget.session.snapshot.contentPackage.exam.domains.where((d) => d.id == id).firstOrNull?.name ?? id).join(', ')}.'),
          if (plan.reviews.any((r) => r.afterExam))
            const Text(
                'Some review intervals fall after your exam. Final review sessions prioritize them without counting them as retained.'),
          if (plan.days.any((d) =>
              d.date.isBefore(calendarDate(widget.now())) &&
              (d.status == StudyDayStatus.missed ||
                  d.status == StudyDayStatus.inProgress)))
            const Text(
                'Unfinished work remains in your plan across available days, within your study time. A started session stays available to continue.'),
          if (plan.limitedCoverage && date != null)
            Text(
                'Required pace: ${plan.requiredPace} new per study day. Your available time covers ${plan.projectedNewQuestions} of ${plan.remainingQuestions} remaining questions.',
                style: context.textStyles.bodySmall),
          if ((today?.reviewBacklog ?? 0) > 0)
            Text('${today!.reviewBacklog} reviews remain in your queue.'),
          if (_error == null &&
              _active == null &&
              progress?.completed != true &&
              (today?.questionIds.isNotEmpty ?? false))
            PrimaryButton(
                label: "Start today's session",
                isLoading: _busy,
                onPressed: _start),
          if (widget.onFinished == null &&
              _metrics != null &&
              plan.availableQuestions > 0)
            ExpansionTile(title: const Text("Study progress"), children: [
              const Text(
                  "With fewer than five timed answers, estimates start at 2 min per new question and 1 min 15 sec per review, including explanation reading."),
              Text(
                  'First-answer accuracy: ${_metrics!.firstAccuracy == null ? "Not enough data" : "${(_metrics!.firstAccuracy! * 100).round()}%"}',
                  style: context.textStyles.bodySmall),
              Text(
                  'Review accuracy: ${_metrics!.reviewAccuracy == null ? "No reviews yet" : "${(_metrics!.reviewAccuracy! * 100).round()}%"}',
                  style: context.textStyles.bodySmall),
              ExpansionTile(title: const Text('Topic coverage'), children: [
                for (final topic in _metrics!.topics)
                  ListTile(
                      title: Text(widget
                              .session.snapshot.contentPackage.exam.domains
                              .expand((d) => d.topics)
                              .where((t) => t.id == topic.topicId)
                              .firstOrNull
                              ?.name ??
                          topic.topicId),
                      subtitle: Text('${switch (topic.status) {
                        TopicLearningStatus.insufficientData =>
                          "Insufficient data",
                        TopicLearningStatus.needsReview => "Needs review",
                        TopicLearningStatus.learning => "Learning",
                        TopicLearningStatus.retained => "Retained"
                      }} · ${topic.questions} questions on ${topic.days} days'))
              ]),
            ]),
          if (widget.onFinished == null)
            Wrap(spacing: AppSpacing.sm, children: [
              TextButton(
                  onPressed: _availability,
                  child: const Text('Adjust availability')),
              TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => StudyCalendarScreen(
                            plan: plan,
                            session: widget.session,
                            repository: widget.repository,
                            now: widget.now)));
                    if (mounted) await _load();
                  },
                  child: const Text('Open calendar')),
              TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  DiagnosticScreen(session: widget.session)));
                          if (mounted) await _load();
                        },
                  child: const Text('Optional diagnostic')),
            ]),
        ],
        if (widget.onFinished != null &&
            (_active == null && (progress?.remaining ?? 0) == 0 ||
                _error != null ||
                plan.availableQuestions == 0))
          PrimaryButton(label: 'Back to Home', onPressed: widget.onFinished),
      ],
    ]));
  }
}
