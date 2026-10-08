import '../subscription/premium_access.dart';
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
  bool _mistakesOnly = false;
  final _scroll = ScrollController();
  final _top = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _move(int index) {
    setState(() => _index = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _top.currentContext != null) {
        Scrollable.ensureVisible(_top.currentContext!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final blocked = premiumBlock(context);
    if (blocked != null) return blocked;
    final result = widget.result;
    final mistakes = result.questions
        .where((q) =>
            result.attempt.answers.containsKey(q.id) &&
            result.attempt.answers[q.id] != q.correctAnswerId)
        .toList();
    final questions = _mistakesOnly ? mistakes : result.questions;
    final question = questions[_index];
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
          key: _top,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('Mistakes only (${mistakes.length})'),
              subtitle: mistakes.isEmpty
                  ? const Text('No mistakes in this session')
                  : null,
              value: _mistakesOnly,
              onChanged: mistakes.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        _mistakesOnly = value;
                        _index = 0;
                      });
                      if (_scroll.hasClients) _scroll.jumpTo(0);
                    },
            ),
            if (result.isDemo)
              Text('Demo · synthetic questions', style: text.label),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              header: true,
              child: Text('Question ${_index + 1} of ${questions.length}',
                  style: text.h3),
            ),
            Text(status,
                style: text.label.copyWith(
                    color: selected == null
                        ? context.colors.onSurfaceVariant
                        : selected == question.correctAnswerId
                            ? context.semanticColors.success
                            : context.colors.error)),
            const SizedBox(height: AppSpacing.lg),
            Text(question.questionText, style: text.h3),
            const SizedBox(height: AppSpacing.lg),
            for (final answer in question.answers) ...[
              AppCard(
                backgroundColor: answer.id == question.correctAnswerId
                    ? context.semanticColors.success.withValues(alpha: 0.12)
                    : answer.id == selected
                        ? context.colors.errorContainer
                        : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (answer.id == question.correctAnswerId)
                      Icon(Icons.check_circle_rounded,
                          color: context.semanticColors.success)
                    else if (answer.id == selected)
                      Icon(Icons.cancel_rounded, color: context.colors.error),
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
          child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.32),
          child: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_index < questions.length - 1)
                    PrimaryButton(
                        label: 'Next answer',
                        onPressed: () => _move(_index + 1))
                  else
                    PrimaryButton(
                        label: 'Back to results',
                        onPressed: () => Navigator.of(context).pop()),
                  if (_index > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SecondaryButton(
                        label: 'Previous answer',
                        onPressed: () => _move(_index - 1)),
                  ],
                ]),
          )),
        ),
      )),
    );
  }
}
