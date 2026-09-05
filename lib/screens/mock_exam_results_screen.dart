import 'package:flutter/material.dart';
import '../mock_exam/mock_exam_blueprint.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';

/// No default score: only a structurally validated, completed attempt can
/// produce a result. Deep links without that data show an honest empty state.
class MockExamResultsScreen extends StatelessWidget {
  static const String route = '/mock-exam-results';
  const MockExamResultsScreen({super.key, this.result});
  final MockExamResult? result;

  @override
  Widget build(BuildContext context) {
    final value = result;
    final canPop = Navigator.of(context).canPop();
    final text = context.textStyles;
    return AppScaffold(
      title: 'Exam Results',
      leading: canPop
          ? CircleIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Back to Mock Exam',
              onPressed: () => Navigator.of(context).pop())
          : null,
      body: value == null
          ? const EmptyState(
              title: 'No completed mock exam',
              message: MockExamResult.disclaimer)
          : SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const SizedBox(height: AppSpacing.lg),
                  if (value.isDemo)
                    Text('Demo result · synthetic questions',
                        style: text.label),
                  Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(value.outcome, style: text.h1)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                      'Correct answers: ${value.attempt.correctCount} / ${value.attempt.questionIds.length}',
                      style: text.h3),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                      '${value.attempt.answeredCount} questions answered. '
                      '${value.attempt.questionIds.length - value.attempt.answeredCount} unanswered.',
                      style: text.body),
                  const SizedBox(height: AppSpacing.lg),
                  Text(MockExamResult.disclaimer, style: text.body),
                  const SizedBox(height: AppSpacing.xl),
                  if (canPop)
                    PrimaryButton(
                        label: 'Back to Mock Exam',
                        onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(height: AppSpacing.lg),
                ])),
    );
  }
}
