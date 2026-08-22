import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Explicit visual/interaction states for [AnswerOptionTile].
enum AnswerOptionState {
  /// Not the user's current pick; tappable.
  unselected,

  /// The user's current pick, before submission; tappable.
  selected,

  /// Post-submission review: this option was the correct answer.
  correct,

  /// Post-submission review: this option was selected and is wrong.
  incorrect,

  /// Not interactive (e.g. review mode for an option the user did not
  /// pick and that was not correct).
  disabled,
}

/// One answer choice in a practice/mock/review question. Used both while
/// the user is picking an answer (`unselected`/`selected`) and afterward
/// during review (`correct`/`incorrect`/`disabled`).
///
/// This widget only renders a state it is given — it never records an
/// answer, scores a question, or reaches into a repository; the caller
/// owns all of that and passes the resulting [state] back in.
class AnswerOptionTile extends StatelessWidget {
  const AnswerOptionTile({
    super.key,
    required this.letter,
    required this.text,
    required this.state,
    this.onTap,
  });

  final String letter;
  final String text;
  final AnswerOptionState state;

  /// Ignored when [state] is [AnswerOptionState.disabled].
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semanticColors = context.semanticColors;

    late final Color background;
    late final Color border;
    late final Color badgeBackground;
    late final Color badgeForeground;
    Widget? trailingIcon;
    String stateDescription;

    switch (state) {
      case AnswerOptionState.unselected:
        background = colors.surfaceContainer;
        border = Colors.transparent;
        badgeBackground = colors.primaryContainer;
        badgeForeground = colors.onSurfaceVariant;
        stateDescription = 'not selected';
        break;
      case AnswerOptionState.selected:
        background = colors.primaryContainer;
        border = colors.primary;
        badgeBackground = colors.primary;
        badgeForeground = colors.onPrimary;
        stateDescription = 'selected';
        break;
      case AnswerOptionState.correct:
        background = colors.primaryContainer;
        border = semanticColors.success;
        badgeBackground = semanticColors.success;
        badgeForeground = semanticColors.onSuccess;
        trailingIcon = Icon(Icons.check_circle_rounded,
            color: semanticColors.success, size: AppIconSize.medium);
        stateDescription = 'correct answer';
        break;
      case AnswerOptionState.incorrect:
        background = colors.errorContainer;
        border = colors.error;
        badgeBackground = colors.error;
        badgeForeground = colors.onError;
        trailingIcon = Icon(Icons.cancel_rounded,
            color: colors.error, size: AppIconSize.medium);
        stateDescription = 'incorrect, your answer';
        break;
      case AnswerOptionState.disabled:
        background = colors.surfaceContainer;
        border = Colors.transparent;
        badgeBackground = colors.primaryContainer;
        badgeForeground = semanticColors.mutedForeground;
        stateDescription = 'not available';
        break;
    }

    final bool interactive =
        state != AnswerOptionState.disabled && onTap != null;

    return Semantics(
      button: interactive,
      enabled: interactive,
      selected: state == AnswerOptionState.selected ||
          state == AnswerOptionState.correct,
      label: 'Option $letter: $text, $stateDescription',
      child: GestureDetector(
        onTap: interactive ? onTap : null,
        child: Container(
          width: double.infinity,
          constraints:
              const BoxConstraints(minHeight: AppTapTarget.minInteractive),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadii.smallIcon),
            border: Border.all(color: border, width: AppBorderWidth.regular),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: badgeBackground,
                  child: Text(
                    letter,
                    style: TextStyle(
                        color: badgeForeground,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    text,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.onSurface),
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                ExcludeSemantics(child: trailingIcon),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
