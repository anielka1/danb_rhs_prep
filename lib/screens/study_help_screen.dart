import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';

/// Help describes available behavior without promising a diagnostic or score
/// algorithm that has not been implemented.
class StudyHelpScreen extends StatelessWidget {
  const StudyHelpScreen({super.key});

  static const topics = <String, String>{
    'Where should I start?':
        'Open Practice and start a short session. Read the explanation after each answer, then review your mistakes. A separate starting diagnostic is not available yet.',
    'Practice or Mock Exam?':
        'Practice gives feedback after each answer. Mock Exam lets you answer and flag questions before seeing explanations at the end. Neither is an official DANB exam.',
    'What does my progress mean?':
        'Accuracy describes your recorded answers. It is not your chance of passing. A personalized exam-readiness calculation is not available yet. Any readiness history included in the demo is sample data, not an assessment of you.',
    'How do I continue a session?':
        'Use Continue on Home, or return to Practice. When you change your practice filters, you can choose to resume your unfinished session or start the selected practice.',
    'How do saved questions work?':
        'Save a question while practicing, then choose Saved in Practice to revisit it. Review mistakes after a session to revisit incorrect answers and their explanations.',
    'What if an answer does not save?':
        'Use the retry action shown with the save error. Keep the session open until saving succeeds. Closing the app can lose changes that have not been saved.',
    'What happens when I reset?':
        'Reset study progress removes answers, saved questions and session history for this exam. Your study plan and appearance stay unchanged. You can cancel before confirming.',
    'Does the demo keep my progress?':
        'Demo questions and starting history are examples. Your changes last while the demo is running and reset when it restarts. The standard app stores study progress on the device.',
  };

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Study help',
        leading: CircleIconButton(
          icon: Icons.chevron_left_rounded,
          semanticLabel: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        body: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: AppSpacing.lg),
          Text('A little guidance.', style: context.textStyles.h1),
          const SizedBox(height: AppSpacing.sm),
          Text('Make your next study session easier.',
              style: context.textStyles.body),
          const SizedBox(height: AppSpacing.xxl),
          for (final entry in topics.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  title: Text(entry.key, style: context.textStyles.h3),
                  tilePadding: const EdgeInsets.all(AppSpacing.lg),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  children: [Text(entry.value, style: context.textStyles.body)],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
        ])),
      );
}
