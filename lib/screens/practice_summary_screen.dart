import '../subscription/premium_access.dart';
import '../domain/models/practice_session.dart';
import 'package:flutter/material.dart';
import '../widgets/practice_save_status.dart';
import '../practice_session/practice_session_controller.dart';
import '../practice_session/practice_session_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import 'main_shell.dart';

class PracticeSummaryScreen extends StatelessWidget {
  static const String route = '/practice-summary';
  const PracticeSummaryScreen({super.key});

  /// Not `Navigator.of(context).popUntil(...)`: this screen lives deep
  /// inside whichever tab's own navigation stack it was actually reached
  /// through (see `MainShell`'s doc comment on its per-tab `Navigator`s)
  /// — normally Practice's, but a cross-tab shortcut (Home's "Start
  /// Practicing") pushes the whole flow onto *that* caller's own stack
  /// instead, since it never switches the active tab to do so. A plain
  /// pop can only ever move within that same stack — it can never make
  /// Home the visible tab. `MainShellScope` reaches the shell directly:
  /// switch to Home, and reset `currentTab` (the tab actually being left,
  /// not a hardcoded guess) back to its own root, so a later visit to it
  /// starts fresh rather than resuming on this finished summary. Falls
  /// back to a plain pop-to-root within this tab when no `MainShellScope`
  /// is present (e.g. a test that pumps this screen without a real
  /// `MainShell` ancestor) — still leaves the finished session behind,
  /// just without also switching tabs.
  Future<void> _backToHome(BuildContext context) async {
    final controller = PracticeSessionScope.maybeOf(context);
    if (controller != null &&
        !await confirmLeavingUnsavedPractice(context, controller)) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    final access = PremiumAccessScope.maybeOf(context);
    if (controller != null &&
        access != null &&
        await access.completeTrial(context, controller)) {
      return;
    }
    if (!context.mounted) return;
    final MainShellController? shell = MainShellScope.maybeOf(context);
    if (shell != null) {
      shell.goToTab(AppTab.home, resetTab: shell.currentTab);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = premiumBlock(context, trialFeedback: true);
    if (blocked != null) return blocked;
    final PracticeSessionController? controller =
        PracticeSessionScope.maybeOf(context);
    if (controller == null) return const _NoActiveSessionView();

    final colors = context.colors;
    final textStyles = context.textStyles;
    final int total = controller.totalQuestions;
    final int correct = controller.correctCount;
    final int percent = total == 0 ? 0 : ((correct / total) * 100).round();
    final Duration elapsed = controller.elapsed;
    final String timeSpent =
        elapsed.inMinutes < 1 ? '<1m' : '${elapsed.inMinutes}m';

    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PracticeSaveStatus(controller: controller),
            const SizedBox(height: 28),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded,
                  color: colors.primary, size: AppIconSize.large),
            ),
            const SizedBox(height: 18),
            Text('Session Complete!', style: textStyles.h1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Another step forward. Keep building your understanding.',
              textAlign: TextAlign.start,
              style: textStyles.body,
            ),
            Text(
                '${controller.answeredCount} questions answered · $correct correct'),
            Text(controller.session.mode == PracticeMode.timedQuiz
                ? 'Elapsed time includes pauses. Session results are a small sample, not proof of topic mastery.'
                : 'Session results are a small sample, not proof of topic mastery.'),
            const SizedBox(height: 30),
            AppCard(
              backgroundColor: colors.primaryContainer,
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$percent%', style: textStyles.statNumber),
                        const SizedBox(height: AppSpacing.xs),
                        Text('$correct/$total Correct',
                            style: textStyles.bodySmall),
                      ],
                    ),
                  ),
                  if (controller.session.mode == PracticeMode.timedQuiz)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(timeSpent, style: textStyles.statNumber),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Elapsed since start',
                              style: textStyles.bodySmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl + 4),
            if (controller.questions
                .any((q) => controller.isCorrectFor(q.id) == false))
              SecondaryButton(
                label:
                    'Review mistakes (${controller.questions.where((q) => controller.isCorrectFor(q.id) == false).length})',
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) =>
                            _MistakesReview(controller: controller))),
              )
            else
              const Text('No mistakes in this session'),
            const SizedBox(height: AppSpacing.md),
            if (context
                    .dependOnInheritedWidgetOfExactType<PracticeSessionScope>()
                    ?.returnToTopics !=
                null)
              PrimaryButton(
                  label: 'Back to topics',
                  onPressed: () async {
                    if (!await confirmLeavingUnsavedPractice(
                            context, controller) ||
                        !context.mounted) {
                      return;
                    }
                    context
                        .dependOnInheritedWidgetOfExactType<
                            PracticeSessionScope>()
                        ?.returnToTopics
                        ?.call();
                  }),
            PrimaryButton(
                label: 'Back to Home', onPressed: () => _backToHome(context)),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _MistakesReview extends StatelessWidget {
  const _MistakesReview({required this.controller});

  final PracticeSessionController controller;

  @override
  Widget build(BuildContext context) {
    final blocked = premiumBlock(context);
    if (blocked != null) return blocked;
    final mistakes = controller.questions.where(
      (question) => controller.isCorrectFor(question.id) == false,
    );
    return AppScaffold(
      title: 'Review Mistakes',
      leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      body: ListView(
        children: [
          Text('Learn from each answer.', style: context.textStyles.h1),
          const SizedBox(height: AppSpacing.sm),
          Text('Reviewing does not change your session score.',
              style: context.textStyles.body),
          const SizedBox(height: AppSpacing.xl),
          for (final question in mistakes) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question.questionText, style: context.textStyles.h2),
                  const SizedBox(height: AppSpacing.lg),
                  for (final answer in question.answers)
                    if (answer.id ==
                            controller
                                .feedbackFor(question.id)!
                                .selectedAnswerId ||
                        answer.id ==
                            controller
                                .feedbackFor(question.id)!
                                .correctAnswerId)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          '${answer.id == controller.feedbackFor(question.id)!.correctAnswerId ? 'Correct answer' : 'Your answer'}: ${answer.text}',
                          style: context.textStyles.body,
                        ),
                      ),
                  Text('WHY', style: context.textStyles.label),
                  const SizedBox(height: AppSpacing.sm),
                  Text(controller.feedbackFor(question.id)!.explanation,
                      style: context.textStyles.body),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          PrimaryButton(
            label: 'Back to summary',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Shown when this screen is reached with no active
/// [PracticeSessionController] — see `PracticeQuestionScreen`'s own
/// `_NoActiveSessionView` for why.
class _NoActiveSessionView extends StatelessWidget {
  const _NoActiveSessionView();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: EmptyState(
        icon: Icons.quiz_rounded,
        title: 'No active practice session',
        message: 'Start a session from Exam Info to begin practicing.',
        primaryActionLabel: 'Back to Home',
        onPrimaryAction: () {
          final MainShellController? shell = MainShellScope.maybeOf(context);
          if (shell != null) {
            shell.goToTab(AppTab.home, resetTab: shell.currentTab);
          } else {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
    );
  }
}
