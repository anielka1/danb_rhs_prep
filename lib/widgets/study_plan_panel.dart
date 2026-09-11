import '../study_plan/study_schedule_service.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../screens/mock_exam_screen.dart';
import '../study_plan/study_metrics.dart';
import '../screens/diagnostic_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_controller.dart';
import '../domain/models/study_schedule.dart';
import '../domain/repositories/study_schedule_repository.dart';
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
      required this.now});
  final BootstrapSessionController session;
  final ProgressRepository repository;
  final DateTime Function() now;
  @override
  State<StudyPlanPanel> createState() => _StudyPlanPanelState();
}

class _StudyPlanPanelState extends State<StudyPlanPanel>
    with WidgetsBindingObserver {
  StudyPlanProjection? _plan;
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
      final snapshot = widget.session.snapshot;
      final active = await widget.repository
          .inProgressPracticeSession(snapshot.selectedExamId);
      final attempts = await widget.repository
          .answerAttemptsForExam(snapshot.selectedExamId);
      final schedule = widget.repository is StudyScheduleRepository
          ? await (widget.repository as StudyScheduleRepository)
              .studySchedule(snapshot.selectedExamId)
          : <StudyScheduleEntry>[];
      final sessions = widget.repository is StudyScheduleRepository
          ? await (widget.repository as StudyScheduleRepository)
              .practiceSessionsForExam(snapshot.selectedExamId)
          : <PracticeSession>[];
      final mocks =
          await widget.repository.mockAttemptsForExam(snapshot.selectedExamId);
      final now = widget.now();
      final limit = maxFreePracticeQuestionsToday(
          entitlement: snapshot.entitlement,
          now: now,
          answeredToday:
              practiceAttemptsAnsweredToday(attempts: attempts, now: now),
          dailyLimit:
              snapshot.contentPackage.exam.freeTier.dailyPracticeQuestions);
      final reserve = await effectiveMockReserve(
          repository: widget.repository,
          package: snapshot.contentPackage,
          entitlement: snapshot.entitlement,
          now: now,
          examDate: snapshot.examDateSelection?.date);
      final plan = const StudyPlanPolicy().project(
          now: now,
          localToday: now,
          timezone: now.timeZoneName,
          exam: snapshot.contentPackage.exam,
          preferences: snapshot.profile?.studyPlanPreferences,
          pool: snapshot.contentPackage.questions,
          attempts: attempts,
          examDate: snapshot.examDateSelection?.date,
          dailyQuestionLimit: snapshot.entitlement.isActiveAt(now)
              ? null
              : snapshot.contentPackage.exam.freeTier.dailyPracticeQuestions,
          remainingUtcQuota: limit,
          sessions: sessions,
          mockBudgets: {
            for (final e in schedule)
              if (e.minutes != null) e.date: e.minutes!
          },
          reservedIds: reserve,
          additionalSeenIds: mocks.expand((m) => m.answers.keys).toSet(),
          overrides: {
            for (final e in schedule)
              e.date: StudyDayType.values.firstWhere((t) => t.name == e.kind,
                  orElse: () => StudyDayType.study)
          });
      if (mounted) {
        setState(() {
          _reserve = reserve;
          _quota = limit;
          _metrics = StudyMetrics(
              pool: snapshot.contentPackage.questions,
              history: attempts,
              reviews: plan.reviews,
              today: now);
          _plan = plan;
          _active = active;
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
          builder: (_) => PracticeSessionScope(
              controller: controller, child: const PracticeQuestionScreen())));
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
    return AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Today's plan", style: context.textStyles.h2),
      if (date != null)
        Text(
            calendarDate(date).isBefore(calendarDate(widget.now()))
                ? 'Exam date has passed'
                : '${calendarDate(date).difference(calendarDate(widget.now())).inDays} days to your exam',
            style: context.textStyles.body),
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
        if (plan.condition != PlanCondition.needsAvailability &&
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
        if (today?.type == StudyDayType.mock)
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
        Text(
            '${plan.uniqueAnswered} / ${plan.availableQuestions} approved questions explored',
            style: context.textStyles.body),
        const SizedBox(height: AppSpacing.md),
        if (_active != null) ...[
          Text('Pick up where you left off', style: context.textStyles.h3),
          PrimaryButton(
              label: _active!.mode == PracticeMode.planned
                  ? 'Continue planned session'
                  : 'Continue',
              isLoading: _busy,
              onPressed: _start),
        ],
        if (plan.condition == PlanCondition.needsAvailability) ...[
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
              today?.status == StudyDayStatus.completed
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
                          : '${today.newIds.length} new · ${today.reviewIds.length} reviews · about ${(today.estimatedSeconds / 60).ceil()} min',
                    },
              style: context.textStyles.body),
          if (plan.availableQuestions > 0 && plan.missingDomains.isNotEmpty)
            Text(
                'Coverage gap: no available questions for ${plan.missingDomains.map((id) => widget.session.snapshot.contentPackage.exam.domains.where((d) => d.id == id).firstOrNull?.name ?? id).join(', ')}.'),
          if (plan.reviews.any((r) => r.afterExam))
            const Text(
                'Some review intervals fall after your exam. Final review sessions prioritize them without counting them as retained.'),
          if (plan.limitedCoverage)
            Text(
                'Required pace: ${plan.requiredPace} new per study day. Your available time covers ${plan.projectedNewQuestions} of ${plan.remainingQuestions} remaining questions.',
                style: context.textStyles.bodySmall),
          if ((today?.reviewBacklog ?? 0) > 0)
            Text('${today!.reviewBacklog} reviews remain in your queue.'),
          if (_active == null && (today?.questionIds.isNotEmpty ?? false))
            PrimaryButton(
                label: "Start today's session",
                isLoading: _busy,
                onPressed: _start),
          if (_metrics != null && plan.availableQuestions > 0)
            ExpansionTile(title: const Text("Study progress"), children: [
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
      ],
    ]));
  }
}
