import 'package:flutter/material.dart';
import '../domain/models/answer_feedback.dart';
import '../features/questions/domain/question.dart';
import '../practice_session/practice_session_controller.dart';
import '../practice_session/practice_session_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_option_tile.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/progress_bar.dart';
import 'answer_explanation_screen.dart';

class PracticeQuestionScreen extends StatefulWidget {
  static const String route = '/practice-question';
  const PracticeQuestionScreen({super.key});

  @override
  State<PracticeQuestionScreen> createState() => _PracticeQuestionScreenState();
}

class _PracticeQuestionScreenState extends State<PracticeQuestionScreen> {
  /// The tap not yet submitted for the current (unanswered) question —
  /// local UI-only state; a submitted answer lives on
  /// [PracticeSessionController] instead, keyed by question id, so it
  /// survives navigating away and back via Previous/Next.
  String? _pendingSelection;
  bool _submitting = false;

  Future<void> _submit(PracticeSessionController controller) async {
    final String? answerId = _pendingSelection;
    if (answerId == null || _submitting) return;
    setState(() => _submitting = true);
    await controller.submitAnswer(answerId);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _pendingSelection = null;
    });
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: AnswerExplanationScreen.route),
        builder: (_) => PracticeSessionScope(
          controller: controller,
          child: const AnswerExplanationScreen(),
        ),
      ),
    );
  }

  void _viewExplanation(PracticeSessionController controller) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: AnswerExplanationScreen.route),
        builder: (_) => PracticeSessionScope(
          controller: controller,
          child: const AnswerExplanationScreen(),
        ),
      ),
    );
  }

  void _goToPrevious(PracticeSessionController controller) {
    if (!controller.canGoToPrevious) return;
    setState(() {
      controller.moveTo(controller.currentIndex - 1);
      _pendingSelection = null;
    });
  }

  void _goToNext(PracticeSessionController controller) {
    if (!controller.canGoToNext) return;
    setState(() {
      controller.moveTo(controller.currentIndex + 1);
      _pendingSelection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final PracticeSessionController? controller =
        PracticeSessionScope.maybeOf(context);
    if (controller == null) return const _NoActiveSessionView();

    final colors = context.colors;
    final textStyles = context.textStyles;
    final Question question = controller.currentQuestion;
    final AnswerFeedback? feedback = controller.feedbackFor(question.id);
    final bool alreadyAnswered = feedback != null;

    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                CircleIconButton(
                  icon: Icons.close_rounded,
                  onPressed: () => Navigator.of(context).maybePop(),
                  semanticLabel: 'Close',
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ProgressBar(
                    value: (controller.currentIndex + 1) /
                        controller.totalQuestions,
                    semanticLabel: 'Question progress',
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.access_time_rounded,
                    size: AppIconSize.medium - 2, color: colors.onSurface),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(_formatElapsed(controller.elapsed),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl + 2),
            Text(
                'QUESTION ${controller.currentIndex + 1} OF '
                '${controller.totalQuestions}',
                style: textStyles.label),
            const SizedBox(height: AppSpacing.md + 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Text(
                question.questionText,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: colors.onSurface,
                    height: 1.3),
              ),
            ),
            const SizedBox(height: 18),
            Column(
              children: [
                for (var i = 0; i < question.answers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AnswerOptionTile(
                      letter: String.fromCharCode(65 + i),
                      text: question.answers[i].text,
                      state: _optionState(
                        answerId: question.answers[i].id,
                        feedback: feedback,
                      ),
                      onTap: alreadyAnswered
                          ? null
                          : () => setState(
                              () => _pendingSelection = question.answers[i].id),
                    ),
                  ),
              ],
            ),
            PrimaryButton(
              label: alreadyAnswered ? 'View Explanation' : 'Submit Answer',
              isLoading: _submitting,
              onPressed: alreadyAnswered
                  ? () => _viewExplanation(controller)
                  : (_pendingSelection != null
                      ? () => _submit(controller)
                      : null),
            ),
            const SizedBox(height: AppSpacing.md + 2),
            Row(
              children: [
                Flexible(
                  child: TextButton.icon(
                    onPressed: controller.canGoToPrevious
                        ? () => _goToPrevious(controller)
                        : null,
                    icon: Icon(Icons.arrow_back_rounded,
                        size: AppIconSize.small,
                        color: controller.canGoToPrevious
                            ? colors.onSurface
                            : context.semanticColors.mutedForeground),
                    label: Text('Previous',
                        style: TextStyle(
                            color: controller.canGoToPrevious
                                ? colors.onSurface
                                : context.semanticColors.mutedForeground,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: TextButton(
                    onPressed: controller.canGoToNext
                        ? () => _goToNext(controller)
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text('Next',
                              style: TextStyle(
                                  color: controller.canGoToNext
                                      ? colors.onSurface
                                      : context.semanticColors.mutedForeground,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(Icons.arrow_forward_rounded,
                            size: AppIconSize.small,
                            color: controller.canGoToNext
                                ? colors.onSurface
                                : context.semanticColors.mutedForeground),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  AnswerOptionState _optionState({
    required String answerId,
    required AnswerFeedback? feedback,
  }) {
    if (feedback == null) {
      return answerId == _pendingSelection
          ? AnswerOptionState.selected
          : AnswerOptionState.unselected;
    }
    if (answerId == feedback.correctAnswerId) {
      return AnswerOptionState.correct;
    }
    if (answerId == feedback.selectedAnswerId) {
      return AnswerOptionState.incorrect;
    }
    return AnswerOptionState.disabled;
  }
}

String _formatElapsed(Duration elapsed) {
  final int totalSeconds = elapsed.inSeconds.clamp(0, 999 * 60 + 59);
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// Shown when this screen is reached with no active
/// [PracticeSessionController] (e.g. the static named-route fallback) —
/// an honest empty state rather than the fake single hardcoded question
/// and no-op Previous/Next controls this screen used to always show.
class _NoActiveSessionView extends StatelessWidget {
  const _NoActiveSessionView();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      actions: [
        CircleIconButton(
          icon: Icons.close_rounded,
          onPressed: () => Navigator.of(context).maybePop(),
          semanticLabel: 'Close',
        ),
      ],
      body: const EmptyState(
        icon: Icons.quiz_rounded,
        title: 'No active practice session',
        message: 'Start a session from Exam Info to begin practicing.',
      ),
    );
  }
}
