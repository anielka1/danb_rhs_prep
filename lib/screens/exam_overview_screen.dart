import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'practice_question_screen.dart';

class _Topic {
  final String title;
  final int questions;
  final bool unlocked;
  const _Topic(this.title, this.questions, this.unlocked);
}

class ExamOverviewScreen extends StatelessWidget {
  static const String route = '/exam-overview';
  const ExamOverviewScreen({super.key});

  static const List<_Topic> _topics = [
    _Topic('Radiation Physics & Characteristics', 15, true),
    _Topic('Radiation Biology & Safety', 25, true),
    _Topic('Radiation Protection Standards', 30, false),
    _Topic('Equipment Operation & Imaging', 20, false),
    _Topic('Patient Management & Procedures', 10, false),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding, 12, AppSpacing.screenPadding, 0),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('Exam Info', style: textStyles.h3),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                    AppSpacing.xl, AppSpacing.screenPadding, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Practice Exam Prep', style: textStyles.h2),
                          const SizedBox(height: 6),
                          Text(
                            '1.5 Hours · 100 Questions · Intermediate',
                            style: textStyles.body.copyWith(
                              color: colors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text('About Certification', style: textStyles.h3),
                    const SizedBox(height: 10),
                    Text(
                      'This simulator prepares you comprehensively for the official '
                      'Dental Assisting National Board Radiation Health & Safety exam. '
                      'Complete each module with 80% correct score.',
                      style: textStyles.body,
                    ),
                    const SizedBox(height: 26),
                    Text('Topics Covered', style: textStyles.h3),
                    const SizedBox(height: AppSpacing.md + 2),
                    ..._topics.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _TopicRow(topic: t),
                        )),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0,
                  AppSpacing.screenPadding, AppSpacing.xl),
              child: PrimaryButton(
                label: 'Start Practice Exam',
                onPressed: () => Navigator.of(context)
                    .pushNamed(PracticeQuestionScreen.route),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final _Topic topic;
  const _TopicRow({required this.topic});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                topic.unlocked ? colors.primaryContainer : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            topic.unlocked ? Icons.check_rounded : Icons.lock_outline_rounded,
            size: AppIconSize.small + 2,
            color: topic.unlocked
                ? colors.primary
                : context.semanticColors.mutedForeground,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.onSurface),
              ),
              const SizedBox(height: 2),
              Text('${topic.questions} Questions',
                  style: context.textStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
