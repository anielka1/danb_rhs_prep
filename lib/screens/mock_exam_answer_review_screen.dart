import 'package:flutter/material.dart';
import '../mock_exam/mock_exam_blueprint.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';

/// Only a validated completed result can enter this read-only review.
class MockExamAnswerReviewScreen extends StatefulWidget {
  const MockExamAnswerReviewScreen({super.key, required this.result});
  final MockExamResult result;

  @override
  State<MockExamAnswerReviewScreen> createState() =>
      _MockExamAnswerReviewScreenState();
}

class _MockExamAnswerReviewScreenState
    extends State<MockExamAnswerReviewScreen> {
  int _index = 0;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _move(int index) {
    setState(() => _index = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final question = result.questions[_index];
    final selected = result.attempt.answers[question.id];
    final status = selected == null
        ? 'Unanswered'
        : selected == question.correctAnswerId
            ? 'Correct'
            : 'Incorrect';
    final text = context.textStyles;
    return AppScaffold(
      title: 'Review answers',
      leading: CircleIconButton(
        icon: Icons.arrow_back_rounded,
        semanticLabel: 'Back to results',
        onPressed: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (result.isDemo)
              Text('Demo · synthetic questions', style: text.label),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              header: true,
              child: Text(
                  'Question ${_index + 1} of ${result.questions.length}',
                  style: text.h3),
            ),
            Text(status, style: text.label),
            if (result.attempt.flaggedQuestionIds.contains(question.id))
              Text('Flagged for review', style: text.label),
            const SizedBox(height: AppSpacing.lg),
            Text(question.questionText, style: text.h3),
            const SizedBox(height: AppSpacing.lg),
            for (final answer in question.answers) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(answer.text, style: text.body),
                    if (answer.id == selected)
                      Text('Your answer', style: text.label),
                    if (answer.id == question.correctAnswerId)
                      Text('Correct answer', style: text.label),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (selected == null)
              Text('You did not answer this question.', style: text.body),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explanation', style: text.h3),
                  const SizedBox(height: AppSpacing.sm),
                  Text(question.explanation, style: text.body),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_index > 0) ...[
              SecondaryButton(
                  label: 'Previous answer', onPressed: () => _move(_index - 1)),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (_index < result.questions.length - 1)
              PrimaryButton(
                  label: 'Next answer', onPressed: () => _move(_index + 1))
            else
              PrimaryButton(
                  label: 'Back to results',
                  onPressed: () => Navigator.of(context).pop()),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
