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
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    background: Colors.white,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  const Text('Exam Info', style: AppTextStyles.h3),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding, 20, AppSpacing.screenPadding, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.lavenderContainer,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Practice Exam Prep', style: AppTextStyles.h2),
                          const SizedBox(height: 6),
                          Text(
                            '1.5 Hours · 100 Questions · Intermediate',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text('About Certification', style: AppTextStyles.h3),
                    const SizedBox(height: 10),
                    Text(
                      'This simulator prepares you comprehensively for the official '
                      'Dental Assisting National Board Radiation Health & Safety exam. '
                      'Complete each module with 80% correct score.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 26),
                    const Text('Topics Covered', style: AppTextStyles.h3),
                    const SizedBox(height: 14),
                    ..._topics.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _TopicRow(topic: t),
                        )),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 20),
              child: PrimaryButton(
                label: 'Start Practice Exam',
                onPressed: () => Navigator.of(context).pushNamed(PracticeQuestionScreen.route),
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
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: topic.unlocked ? AppColors.lavenderContainer : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            topic.unlocked ? Icons.check_rounded : Icons.lock_outline_rounded,
            size: 18,
            color: topic.unlocked ? AppColors.primary : AppColors.lockedGrey,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy),
              ),
              const SizedBox(height: 2),
              Text('${topic.questions} Questions', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
