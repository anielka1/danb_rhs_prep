import '../widgets/study_week_preview.dart';
import 'profile_settings_screen.dart';
import 'study_availability_screen.dart';
import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_controller.dart';
import '../domain/repositories/progress_repository.dart';
import '../study_plan/study_plan.dart';
import '../study_plan/study_schedule_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';

class StudyCalendarScreen extends StatefulWidget {
  const StudyCalendarScreen(
      {super.key,
      required this.plan,
      this.initialDate,
      required this.session,
      required this.repository,
      required this.now});
  final StudyPlanProjection plan;
  final DateTime? initialDate;
  final BootstrapSessionController session;
  final ProgressRepository repository;
  final DateTime Function() now;
  @override
  State<StudyCalendarScreen> createState() => _StudyCalendarScreenState();
}

class _StudyCalendarScreenState extends State<StudyCalendarScreen> {
  bool _saving = false;
  final _detailsKey = GlobalKey();
  void _select(DateTime date) {
    setState(() => _selectedDate = date);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final details = _detailsKey.currentContext;
      if (mounted && details != null) {
        Scrollable.ensureVisible(details,
            duration: const Duration(milliseconds: 200), alignment: 0.1);
      }
    });
  }

  late DateTime _month;
  @override
  void initState() {
    super.initState();
    _selectedDate = calendarDate(widget.initialDate ?? widget.now());
    _month = DateTime.utc(_selectedDate!.year, _selectedDate!.month);
  }

  DateTime? _selectedDate;
  String? _message;
  Future<void> _change(StudyPlanDay day, StudyDayType type,
      {bool move = false}) async {
    DateTime? destination;
    if (move) {
      destination = await showDatePicker(
          context: context,
          initialDate: day.date.add(const Duration(days: 1)),
          firstDate: calendarDate(widget.now()).add(const Duration(days: 1)),
          lastDate: calendarDate(widget.now()).add(const Duration(days: 730)));
      if (destination == null) return;
    }
    if (!mounted) return;
    if (type == StudyDayType.mock) {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Set aside time for a mock'),
                  content: Text(
                      'Reserve a separate ${widget.session.snapshot.contentPackage.exam.mockExam.durationMinutes}-minute slot. Reviewing answers happens afterwards. Reserve unseen questions only if topic coverage can be preserved.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Schedule mock'))
                  ]));
      if (confirmed != true) return;
    }
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final snap = widget.session.snapshot;
      final notice = await const StudyScheduleService().change(
          repository: widget.repository,
          package: snap.contentPackage,
          entitlement: snap.entitlement,
          now: widget.now(),
          date: day.date,
          type: type,
          moveTo: destination,
          mockMinutes: type == StudyDayType.mock
              ? snap.contentPackage.exam.mockExam.durationMinutes
              : null,
          reserveUnseen: type == StudyDayType.mock,
          examDate: snap.examDateSelection?.date);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                notice ?? 'Calendar saved. Your plan has been recalculated.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = e is StateError
            ? e.message
            : 'Could not change this day. Check available content and try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
          body: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            const BackButton(),
            Text('Your study calendar', style: context.textStyles.h2),
            Text('Tap a date for details. Future counts are forecasts.',
                style: context.textStyles.body),
            if (widget.plan.limitedCoverage &&
                widget.session.snapshot.examDateSelection?.date != null) ...[
              const Text(
                  'Your current study time cannot cover all remaining material before the exam. Your exam date has not changed.'),
              TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            StudyAvailabilityScreen(session: widget.session)));
                    // The caller reloads the projection when this calendar closes,
                    // just as it does after a day change above.
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Adjust availability')),
            ],
            if (widget.plan.days.any((d) =>
                d.date.isBefore(calendarDate(widget.now())) &&
                (d.status == StudyDayStatus.missed ||
                    d.status == StudyDayStatus.inProgress)))
              const Text(
                  'Missed work stays in the remaining plan, spread across available days within your time budget. You can still continue a started session.'),
            if (_message != null)
              Text(_message!, style: context.textStyles.body),
            const SizedBox(height: AppSpacing.lg),
            if (widget.plan.availableQuestions == 0)
              const Text(
                  'No question plan yet. Approved study questions are not available. Your calendar dates are still available.'),
            if (widget.session.snapshot.examDateSelection?.date == null)
              TextButton(
                  onPressed: () async {
                    await Navigator.of(context, rootNavigator: true).pushNamed(
                        ProfileSettingsScreen.route,
                        arguments: widget.session);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Set exam date in Settings')),
            if (widget.plan.condition == PlanCondition.needsAvailability)
              TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            StudyAvailabilityScreen(session: widget.session)));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Set study availability')),
            _monthGrid(context),
            const Text('Today · Day off · Completed ✓ · Exam ⚑'),
            const SizedBox(height: AppSpacing.md),
            SizedBox(key: _detailsKey),
            if (projectedDay(widget.plan, _selectedDate!) == null)
              Text(
                  '${dateKey(_selectedDate!)} · No recorded tasks or question plan'),
            for (final day
                in widget.plan.days.where((d) => d.date == _selectedDate))
              Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                      selected: day.date ==
                          (_selectedDate ?? calendarDate(widget.now())),
                      onTap: () => setState(() => _selectedDate = day.date),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('${dateKey(day.date)} · ${day.type.name}',
                                style: context.textStyles.h3),
                            Text(
                                switch (day.status) {
                                  StudyDayStatus.projected =>
                                    day.date.isAfter(calendarDate(widget.now()))
                                        ? 'Forecast · may change'
                                        : 'Scheduled',
                                  StudyDayStatus.inProgress =>
                                    day.recordedAnswers > 0
                                        ? 'Partially completed'
                                        : 'In progress',
                                  StudyDayStatus.completed => 'Completed',
                                  StudyDayStatus.missed => 'Not completed'
                                },
                                style: context.textStyles.body),
                            Text(
                                '${dayQuestionCount(day)} questions · ${day.recordedAnswers} completed · ${day.questionIds.length} remaining'),
                            if (day.recordedAnswers > 0)
                              Text(
                                  day.spentSeconds > 0
                                      ? '${day.recordedAnswers} answer${day.recordedAnswers == 1 ? '' : 's'} recorded · ${(day.spentSeconds / 60).ceil()} min answer time'
                                      : '${day.recordedAnswers} answer${day.recordedAnswers == 1 ? '' : 's'} recorded · timing unavailable',
                                  style: context.textStyles.body),
                            if (day.type == StudyDayType.exam)
                              const Text(
                                  'Exam day · change the exam date in Settings')
                            else if (day.type == StudyDayType.rest)
                              const Text('Day off · no study scheduled')
                            else ...[
                              Text(
                                  '${day.newIds.length} new · ${day.reviewIds.length} review${day.reviewIds.length == 1 ? '' : 's'} remaining',
                                  style: context.textStyles.body),
                              Text(
                                  day.date.isBefore(calendarDate(widget.now()))
                                      ? 'Saved unfinished tasks · your history is preserved'
                                      : 'About ${(day.estimatedSeconds / 60).ceil()} min / ${day.budgetSeconds ~/ 60} min available',
                                  style: context.textStyles.bodySmall),
                            ],
                            if (day.date == _selectedDate &&
                                day.type != StudyDayType.exam &&
                                day.date.isAfter(calendarDate(widget.now())) &&
                                day.status == StudyDayStatus.projected)
                              Wrap(spacing: AppSpacing.sm, children: [
                                for (final type in [
                                  StudyDayType.study,
                                  StudyDayType.rest,
                                  StudyDayType.buffer,
                                  StudyDayType.review,
                                  StudyDayType.mock
                                ])
                                  TextButton(
                                      onPressed: _saving
                                          ? null
                                          : () => _change(day, type),
                                      child: Text(type == StudyDayType.rest
                                          ? 'Day off / cancel mock'
                                          : type.name)),
                                TextButton(
                                    onPressed: _saving
                                        ? null
                                        : () => _change(day, StudyDayType.study,
                                            move: true),
                                    child: const Text('Move session')),
                              ]),
                          ]))),
          ])));
  Widget _monthGrid(BuildContext context) {
    final today = calendarDate(widget.now());
    final exam = widget.session.snapshot.examDateSelection?.date;
    final end = calendarDate(exam ?? today.add(const Duration(days: 365)));
    final lastMonth = DateTime.utc(end.year, end.month);
    final earliest =
        widget.plan.days.isEmpty ? today : widget.plan.days.first.date;
    final firstMonth = DateTime.utc(earliest.year, earliest.month);
    final length = DateTime.utc(_month.year, _month.month + 1, 0).day;
    final offset = _month.weekday - 1;
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return Column(children: [
      Row(children: [
        IconButton(
            tooltip: 'Previous month',
            onPressed: _month.isAfter(firstMonth)
                ? () => setState(
                    () => _month = DateTime.utc(_month.year, _month.month - 1))
                : null,
            icon: const Icon(Icons.chevron_left)),
        Expanded(
            child: Text('${months[_month.month - 1]} ${_month.year}',
                style: context.textStyles.h3)),
        IconButton(
            tooltip: 'Next month',
            onPressed: _month.isBefore(lastMonth)
                ? () => setState(
                    () => _month = DateTime.utc(_month.year, _month.month + 1))
                : null,
            icon: const Icon(Icons.chevron_right)),
      ]),
      LayoutBuilder(builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final width =
            (constraints.maxWidth < 336 ? 336.0 : constraints.maxWidth) *
                (scale > 1.4 ? scale / 1.4 : 1);
        return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
                width: width,
                child: Column(children: [
                  Row(children: [
                    for (final name in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                      Expanded(child: Center(child: Text(name)))
                  ]),
                  for (var row = 0; row < ((length + offset) / 7).ceil(); row++)
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var col = 0; col < 7; col++)
                            SizedBox(
                                width: width / 7,
                                child: row * 7 + col - offset + 1 < 1 ||
                                        row * 7 + col - offset + 1 > length
                                    ? const SizedBox.shrink()
                                    : _cell(DateTime.utc(
                                        _month.year,
                                        _month.month,
                                        row * 7 + col - offset + 1))),
                        ]),
                ])));
      }),
    ]);
  }

  Widget _cell(DateTime date) {
    final day = projectedDay(widget.plan, date);
    final today = date == calendarDate(widget.now());
    final noPlan = widget.plan.availableQuestions == 0 ||
        widget.plan.condition == PlanCondition.needsAvailability;
    final marker = day?.type == StudyDayType.exam
        ? 'Exam'
        : day?.status == StudyDayStatus.completed
            ? '✓'
            : day?.type == StudyDayType.rest && !noPlan
                ? 'Off'
                : day?.status == StudyDayStatus.inProgress
                    ? 'Part'
                    : '';
    final label = (noPlan && (day?.recordedAnswers ?? 0) == 0) || day == null
        ? '—'
        : '${dayQuestionCount(day)} Q';
    return Semantics(
        label: '${dateKey(date)}, ${today ? 'Today, ' : ''}$marker, $label',
        selected: date == _selectedDate,
        child: InkWell(
            key: ValueKey('calendar-${dateKey(date)}'),
            onTap: () => _select(date),
            child: Container(
                margin: const EdgeInsets.all(1),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: date == _selectedDate
                        ? context.colors.primaryContainer
                        : null,
                    border: today
                        ? Border.all(color: context.colors.primary, width: 2)
                        : null),
                child: Column(children: [
                  Text('${date.day}', style: context.textStyles.label),
                  Text(label, style: context.textStyles.bodySmall),
                  if (marker.isNotEmpty)
                    Text(marker, style: context.textStyles.bodySmall),
                ]))));
  }
}
