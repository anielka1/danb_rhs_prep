import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_option_tile.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';

class _ReviewOption {
  final String letter;
  final String text;
  final AnswerOptionState state;
  const _ReviewOption(this.letter, this.text, this.state);
}

class AnswerExplanationScreen extends StatelessWidget {
  static const String route = '/answer-explanation';
  const AnswerExplanationScreen({super.key});

  static const List<_ReviewOption> _options = [
    _ReviewOption('A', '5 rem (0.05 Sv)', AnswerOptionState.correct),
    _ReviewOption('B', '10 rem (0.10 Sv)', AnswerOptionState.incorrect),
    _ReviewOption('C', '15 rem (0.15 Sv)', AnswerOptionState.disabled),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semanticColors = context.semanticColors;
    final textStyles = context.textStyles;
    return AppScaffold(
      leading: CircleIconButton(
        icon: Icons.chevron_left_rounded,
        onPressed: () => Navigator.of(context).maybePop(),
        semanticLabel: 'Back',
      ),
      title: 'Review Question',
      centerTitle: true,
      actions: [
        // Disabled: `ProgressRepository`/`QuestionState.bookmarked` exist
        // at the repository layer, but this screen's question is entirely
        // hardcoded prototype content with no real examId/questionId to
        // bookmark against — wiring this up would mean either fabricating
        // a fake identity (which would misreport what got saved) or
        // threading a real `Question` through this screen, which is a
        // content-wiring change beyond a control fix. Disabling, not
        // hiding, so the affordance stays visible for when that wiring
        // lands.
        CircleIconButton(
          icon: Icons.bookmark_border_rounded,
          background: colors.surfaceContainer,
          iconColor: context.semanticColors.mutedForeground,
          onPressed: null,
          semanticLabel: 'Bookmark question',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RADIATION PROTECTION STANDARDS',
                    style: textStyles.label.copyWith(color: colors.primary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What is the maximum permissible dose (MPD) of radiation for '
                    'occupational workers per year?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: colors.onSurface,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ..._options.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AnswerOptionTile(
                      letter: o.letter, text: o.text, state: o.state),
                )),
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
                          'Correct Explanation',
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
                    'According to the National Council on Radiation Protection and '
                    'Measurements (NCRP), the annual maximum permissible dose (MPD) for '
                    'occupationally exposed dental personnel is 5 rem (or 50 mSv / 0.05 Sv) '
                    'per year to ensure professional safety.',
                    // onSuccessContainer (same role used by the "Correct
                    // Explanation" header right above), not an
                    // alpha-faded onSurface: fading onSurface to 75%
                    // only reaches ~4.03:1 against successContainer in
                    // light mode, under the 4.5:1 floor for this
                    // normal-size body text.
                    style: textStyles.body
                        .copyWith(color: semanticColors.onSuccessContainer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Next Question',
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
