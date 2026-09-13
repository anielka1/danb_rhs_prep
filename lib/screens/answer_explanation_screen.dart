import '../subscription/premium_access.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import 'package:flutter/material.dart';
import '../widgets/practice_save_status.dart';
import '../domain/models/answer_feedback.dart';
import '../features/questions/domain/question.dart';
import '../practice_session/practice_session_controller.dart';
import '../practice_session/practice_session_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_option_tile.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import 'practice_summary_screen.dart';

class AnswerExplanationScreen extends StatefulWidget {
  static const String route = '/answer-explanation';
  const AnswerExplanationScreen({super.key});

  @override
  State<AnswerExplanationScreen> createState() =>
      _AnswerExplanationScreenState();
}

class _AnswerExplanationScreenState extends State<AnswerExplanationScreen> {
  /// Guards a single [PracticeSessionController.loadBookmark] call per
  /// screen instance — `didChangeDependencies` can otherwise run more
  /// than once (e.g. a theme/locale change), and re-issuing the read
  /// every time would be wasteful, not incorrect (PREP-460).
  bool _bookmarkLoadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookmarkLoadStarted) return;
    _bookmarkLoadStarted = true;
    final PracticeSessionController? controller =
        PracticeSessionScope.maybeOf(context);
    if (controller == null) return;
    controller.loadBookmark(controller.currentQuestion.id).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _toggleBookmark(
      PracticeSessionController controller, String questionId) async {
    if (PremiumAccessScope.maybeOf(context)?.active == false) return;
    // Optimistic: the local cache (and this rebuild) update immediately,
    // before persistence — a failing/missing repository never undoes
    // the interactive toggle. See PracticeSessionController.persistBookmark's
    // own doc comment.
    final bool newValue = controller.toggleBookmarkLocally(questionId);
    setState(() {});
    await controller.persistBookmark(questionId, newValue);
    if (mounted) setState(() {});
  }

  Future<void> _next(
      BuildContext context, PracticeSessionController controller) async {
    if (PremiumAccessScope.maybeOf(context)?.active == false) return;
    if (controller.isLastQuestion) {
      await controller.complete();
      if (!context.mounted) return;
      final bootstrap = BootstrapSessionScope.maybeControllerOf(context);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          settings: const RouteSettings(name: PracticeSummaryScreen.route),
          builder: (_) => BootstrapSessionScope.carry(
              bootstrap,
              PracticeSessionScope(
                controller: controller,
                child: const PracticeSummaryScreen(),
              )),
        ),
      );
      return;
    }
    controller.moveTo(controller.currentIndex + 1);
    // Not pushReplacement with a new PracticeQuestionScreen: that only
    // ever replaces *this* explanation route, leaving the real,
    // originally-pushed PracticeQuestionScreen route (from
    // PracticeQuestionScreen._submit's own push, further down the
    // stack) orphaned underneath it — one extra dead layer per question
    // answered. That original screen is still live and already reads
    // `controller.currentQuestion`/`currentIndex` on every rebuild
    // (exactly how its own Previous/Next buttons update it with no
    // navigation at all), so simply popping back to it here shows the
    // question `moveTo` above just selected — no new instance needed.
    // Before this fix, closing out with the top-left X after answering
    // even one question popped only this dead layer, landing back on
    // what looked like an unresponsive question screen instead of
    // exiting practice.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final blocked = premiumBlock(context);
    if (blocked != null) return blocked;
    final PracticeSessionController? controller =
        PracticeSessionScope.maybeOf(context);
    if (controller == null) return const _NoActiveSessionView();

    final colors = context.colors;
    final semanticColors = context.semanticColors;
    final textStyles = context.textStyles;
    final Question question = controller.currentQuestion;
    final bool isBookmarked = controller.isBookmarked(question.id);
    final AnswerFeedback? feedback = controller.feedbackFor(question.id);
    if (feedback == null) {
      // Structurally should never happen — this screen is only reached
      // for a question `PracticeSessionController` has already recorded
      // feedback for, via `PracticeQuestionScreen`'s Submit/View
      // Explanation wiring. An honest "can't show this" beats crashing,
      // or silently re-deriving the correct answer/explanation from a
      // possibly-different read of `question` — exactly the ambiguity
      // AnswerFeedback exists to remove.
      return const _FeedbackUnavailableView();
    }

    return AppScaffold(
      leading: CircleIconButton(
        icon: Icons.chevron_left_rounded,
        onPressed: () => Navigator.of(context).maybePop(),
        semanticLabel: 'Back',
      ),
      title: 'Review Question',
      centerTitle: true,
      actions: [
        // Real bookmark toggle (PREP-460), backed by
        // QuestionState.bookmarked via ProgressRepository — filled icon
        // + a distinct color *and* a distinct semantic label distinguish
        // the bookmarked state, never color alone.
        CircleIconButton(
          icon: isBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          background: colors.surfaceContainer,
          iconColor: isBookmarked
              ? colors.primary
              : context.semanticColors.mutedForeground,
          onPressed: () => _toggleBookmark(controller, question.id),
          semanticLabel: isBookmarked ? 'Remove bookmark' : 'Bookmark question',
        ),
      ],
      // The whole screen scrolls (rather than only the review content, with
      // a fixed "Next Question" button pinned below it) so the button is
      // never clipped or forced into an impossible layout when its label
      // needs multiple lines at large Dynamic Type sizes on a small,
      // narrow device — the same real overflow shape found and fixed on
      // `ExamOverviewScreen`.
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PracticeSaveStatus(controller: controller),
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
                  fontSize: 16,
                  color: colors.onSurface,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < question.answers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AnswerOptionTile(
                  letter: String.fromCharCode(65 + i),
                  text: question.answers[i].text,
                  state: question.answers[i].id == feedback.correctAnswerId
                      ? AnswerOptionState.correct
                      : question.answers[i].id == feedback.selectedAnswerId
                          ? AnswerOptionState.incorrect
                          : AnswerOptionState.disabled,
                ),
              ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: semanticColors.successContainer,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: AppIconSize.medium - 2,
                        color: semanticColors.onSuccessContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Explanation',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: semanticColors.onSuccessContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    feedback.explanation,
                    // onSuccessContainer (same role used by the header right
                    // above), not an alpha-faded onSurface: fading onSurface
                    // to 75% only reaches ~4.03:1 against successContainer in
                    // light mode, under the 4.5:1 floor for this normal-size
                    // body text.
                    style: textStyles.body
                        .copyWith(color: semanticColors.onSuccessContainer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: controller.isLastQuestion ? 'Finish' : 'Next Question',
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () => _next(context, controller),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

/// Shown when this screen is reached for a question
/// [PracticeSessionController.feedbackFor] has no result for — see the
/// call site's own comment for why this should be structurally
/// unreachable in practice.
class _FeedbackUnavailableView extends StatelessWidget {
  const _FeedbackUnavailableView();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      leading: CircleIconButton(
        icon: Icons.chevron_left_rounded,
        onPressed: () => Navigator.of(context).maybePop(),
        semanticLabel: 'Back',
      ),
      title: 'Review Question',
      centerTitle: true,
      body: const EmptyState(
        icon: Icons.error_outline_rounded,
        title: "This result isn't available",
        message: 'Go back and try answering again.',
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
      leading: CircleIconButton(
        icon: Icons.chevron_left_rounded,
        onPressed: () => Navigator.of(context).maybePop(),
        semanticLabel: 'Back',
      ),
      title: 'Review Question',
      centerTitle: true,
      body: const EmptyState(
        icon: Icons.quiz_rounded,
        title: 'No active practice session',
        message: 'Start a session from Exam Info to begin practicing.',
      ),
    );
  }
}
