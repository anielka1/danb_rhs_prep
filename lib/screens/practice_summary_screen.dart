import 'package:flutter/material.dart';
import '../features/questions/domain/question.dart';
import '../practice_session/practice_session_controller.dart';
import '../practice_session/practice_session_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import 'main_shell.dart';

class _TopicScore {
  final String topicId;
  final int correct;
  final int total;
  const _TopicScore(this.topicId, this.correct, this.total);
  int get percent => total == 0 ? 0 : ((correct / total) * 100).round();
}

class PracticeSummaryScreen extends StatelessWidget {
  static const String route = '/practice-summary';
  const PracticeSummaryScreen({super.key});

  /// Not `Navigator.pushNamedAndRemoveUntil(MainShell.route, ...)`: that
  /// re-enters through `main.dart`'s static route table, which has no
  /// `BootstrapSessionScope` ancestor at all (only `SplashScreen`'s and
  /// `ExperienceLevelScreen`'s own `MaterialPageRoute` add one, and
  /// removing every route would discard it) — `HomeScreen` reading
  /// `BootstrapSessionScope.snapshotOf(context)` would then crash. Popping
  /// back to the existing `MainShell` route already in the stack keeps
  /// its original ancestor scope intact.
  void _backToHome(BuildContext context) {
    Navigator.of(context)
        .popUntil((route) => route.settings.name == MainShell.route);
  }

  List<_TopicScore> _breakdown(PracticeSessionController controller) {
    final Map<String, _TopicScore> byTopic = {};
    for (final Question question in controller.questions) {
      final bool? correct = controller.isCorrectFor(question.id);
      if (correct == null) continue;
      final _TopicScore prior =
          byTopic[question.topicId] ?? _TopicScore(question.topicId, 0, 0);
      byTopic[question.topicId] = _TopicScore(
        question.topicId,
        prior.correct + (correct ? 1 : 0),
        prior.total + 1,
      );
    }
    return byTopic.values.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
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
    final List<_TopicScore> breakdown = _breakdown(controller);

    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
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
              'You did an outstanding job reviewing today.',
              textAlign: TextAlign.center,
              style: textStyles.body,
            ),
            const SizedBox(height: 30),
            Row(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(timeSpent, style: textStyles.statNumber),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Time Spent', style: textStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl + 4),
            if (breakdown.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('TOPIC BREAKDOWN', style: textStyles.label),
              ),
              const SizedBox(height: AppSpacing.sm),
              // shrinkWrap + NeverScrollableScrollPhysics: this list no
              // longer owns its own scrolling (the outer
              // SingleChildScrollView does), it just sizes to its content.
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: breakdown.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final t = breakdown[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(t.topicId,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: colors.onSurface)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('${t.percent}%',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: colors.secondary)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // Disabled: reviewing missed practice questions needs its own
            // review screen/flow, not part of this task's scope, even
            // though the incorrect answers themselves are now real data.
            const SecondaryButton(label: 'Review Mistakes', onPressed: null),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Back to Home',
              onPressed: () => _backToHome(context),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
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
        onPrimaryAction: () => Navigator.of(context)
            .popUntil((route) => route.settings.name == MainShell.route),
      ),
    );
  }
}
