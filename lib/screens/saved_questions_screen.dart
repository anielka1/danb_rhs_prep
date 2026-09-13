import '../subscription/premium_access.dart';
import 'package:flutter/material.dart';
import '../domain/repositories/progress_repository.dart';
import '../features/content/domain/content_package.dart';
import '../features/questions/domain/question.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/primary_button.dart';

/// Read-only library: opening saved answers never records a study attempt.
class SavedQuestionsScreen extends StatefulWidget {
  const SavedQuestionsScreen(
      {super.key, this.contentPackage, this.progressRepository});
  final ContentPackage? contentPackage;
  final ProgressRepository? progressRepository;

  @override
  State<SavedQuestionsScreen> createState() => _SavedQuestionsScreenState();
}

class _SavedQuestionsScreenState extends State<SavedQuestionsScreen> {
  Future<({List<Question> questions, int missing})>? _saved;

  Future<({List<Question> questions, int missing})> _load() async {
    final package = widget.contentPackage;
    final repository = widget.progressRepository;
    if (package == null || repository == null) {
      throw StateError('Saved question source unavailable');
    }
    final states = await repository.questionStatesForExam(package.exam.id);
    final ids = states
        .where((s) => s.bookmarked && s.examId == package.exam.id)
        .map((s) => s.questionId)
        .toSet();
    final questions = package.questions
        .where((q) => q.examId == package.exam.id && ids.contains(q.id))
        .toList();
    return (
      questions: questions,
      missing: ids.difference(questions.map((q) => q.id).toSet()).length
    );
  }

  @override
  Widget build(BuildContext context) =>
      premiumBlock(context) ??
      AppScaffold(
        title: 'Saved questions',
        leading: CircleIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back',
            onPressed: () => Navigator.of(context).pop()),
        body: SingleChildScrollView(
          child: FutureBuilder<({List<Question> questions, int missing})>(
            future: _saved ??= _load(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingState(message: 'Loading saved questions…');
              }
              if (snapshot.hasError) {
                return ErrorState(
                    title: 'Could not load saved questions',
                    message:
                        'Your saved questions are unchanged. Please try again.',
                    onRetry: () {
                      final next = _load();
                      setState(() {
                        _saved = next;
                      });
                    });
              }
              final data = snapshot.requireData;
              final styles = context.textStyles;
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Text('Your saved collection.', style: styles.h1),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                        'Read the correct answers and explanations at your own pace.',
                        style: styles.body),
                    const SizedBox(height: AppSpacing.xl),
                    if (data.missing > 0) ...[
                      Text(
                          'Some saved questions are no longer available in this content version.',
                          style: styles.body),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (data.questions.isEmpty)
                      AppCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Icon(Icons.bookmark_border_rounded,
                                color: context.colors.primary, size: 32),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                                data.missing > 0
                                    ? 'No saved questions available'
                                    : 'No saved questions yet',
                                style: styles.h3),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                                'Tap the bookmark on a practice question or its explanation to find it here.',
                                style: styles.body),
                          ])),
                    for (final question in data.questions) ...[
                      AppCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(question.questionText, style: styles.h3),
                            const SizedBox(height: AppSpacing.lg),
                            Text('Correct answer',
                                style: styles.label
                                    .copyWith(color: context.colors.primary)),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                                question.correctAnswer?.text ??
                                    'Answer unavailable in this content version.',
                                style: styles.body),
                            const SizedBox(height: AppSpacing.lg),
                            Text('Explanation', style: styles.label),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                                question.explanation.isEmpty
                                    ? 'Explanation unavailable in this content version.'
                                    : question.explanation,
                                style: styles.body),
                          ])),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ]);
            },
          ),
        ),
      );
}
