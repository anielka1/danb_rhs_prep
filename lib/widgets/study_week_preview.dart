import 'package:flutter/material.dart';
import '../study_plan/study_plan.dart';
import '../theme/app_theme.dart';

/// Display-only lookup. All task counts come from the planner's projection.
StudyPlanDay? projectedDay(StudyPlanProjection plan, DateTime date) =>
    plan.days.where((d) => d.date == calendarDate(date)).firstOrNull;
int dayQuestionCount(StudyPlanDay? day) =>
    (day?.recordedAnswers ?? 0) + (day?.questionIds.length ?? 0);

class StudyWeekPreview extends StatelessWidget {
  const StudyWeekPreview(
      {super.key, required this.plan, required this.now, required this.onOpen});
  final StudyPlanProjection plan;
  final DateTime now;
  final void Function(DateTime date) onOpen;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
            onPressed: () => onOpen(calendarDate(now)),
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Text('Study calendar')),
        const Text('Next 7 days · future counts are forecasts'),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (var i = 0; i < 7; i++)
                _day(context, calendarDate(now).add(Duration(days: i))),
            ])),
      ]);
  Widget _day(BuildContext context, DateTime date) {
    final day = projectedDay(plan, date);
    final noPlan = plan.availableQuestions == 0 ||
        plan.condition == PlanCondition.needsAvailability;
    final count = dayQuestionCount(day);
    final label = day?.type == StudyDayType.exam
        ? 'Exam'
        : (noPlan && (day?.recordedAnswers ?? 0) == 0) || day == null
            ? '—'
            : '$count Q';
    return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Semantics(
            label:
                '${dateKey(date)}, ${label == '—' ? 'No question plan' : label}',
            child: TextButton(
                key: ValueKey('week-${dateKey(date)}'),
                onPressed: () => onOpen(date),
                child: Column(children: [
                  Text(const [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun'
                  ][date.weekday - 1]),
                  Text('${date.day}', style: context.textStyles.h3),
                  Text(label),
                ]))));
  }
}
