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
      required this.session,
      required this.repository,
      required this.now});
  final StudyPlanProjection plan;
  final BootstrapSessionController session;
  final ProgressRepository repository;
  final DateTime Function() now;
  @override
  State<StudyCalendarScreen> createState() => _StudyCalendarScreenState();
}

class _StudyCalendarScreenState extends State<StudyCalendarScreen> {
  bool _saving = false;
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
            Text('Your study calendar', style: context.textStyles.h1),
            Text(
                'Future sessions are estimates. Completed answers stay in your history.',
                style: context.textStyles.body),
            if (_message != null)
              Text(_message!, style: context.textStyles.body),
            const SizedBox(height: AppSpacing.lg),
            for (final day in widget.plan.days)
              Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('${dateKey(day.date)} · ${day.type.name}',
                            style: context.textStyles.h3),
                        Text(
                            '${day.status.name} · ${day.newIds.length} new · ${day.reviewIds.length} reviews',
                            style: context.textStyles.body),
                        Text(
                            'About ${(day.estimatedSeconds / 60).ceil()} min / ${day.budgetSeconds ~/ 60} min available',
                            style: context.textStyles.bodySmall),
                        if (day.date.isAfter(calendarDate(widget.now())) &&
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
                                  onPressed:
                                      _saving ? null : () => _change(day, type),
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
}
