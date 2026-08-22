import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

enum _OptionState { correct, incorrectSelected, neutral }

class _ReviewOption {
  final String letter;
  final String text;
  final _OptionState state;
  const _ReviewOption(this.letter, this.text, this.state);
}

class AnswerExplanationScreen extends StatelessWidget {
  static const String route = '/answer-explanation';
  const AnswerExplanationScreen({super.key});

  static const List<_ReviewOption> _options = [
    _ReviewOption('A', '5 rem (0.05 Sv)', _OptionState.correct),
    _ReviewOption('B', '10 rem (0.10 Sv)', _OptionState.incorrectSelected),
    _ReviewOption('C', '15 rem (0.15 Sv)', _OptionState.neutral),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semanticColors = context.semanticColors;
    final textStyles = context.textStyles;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('Review Question',
                        textAlign: TextAlign.center, style: textStyles.h3),
                  ),
                  CircleIconButton(
                    icon: Icons.bookmark_border_rounded,
                    background: colors.primaryContainer,
                    iconColor: colors.primary,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: textStyles.label
                                  .copyWith(color: colors.primary),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'What is the maximum permissible dose (MPD) of radiation for '
                              'occupational workers per year?',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: colors.onSurface,
                                  height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ..._options.map((o) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _ReviewOptionTile(option: o),
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
                                Icon(Icons.menu_book_rounded,
                                    size: AppIconSize.medium - 2,
                                    color: semanticColors.onSuccessContainer),
                                const SizedBox(width: AppSpacing.sm),
                                Text('Correct Explanation',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color:
                                            semanticColors.onSuccessContainer)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'According to the National Council on Radiation Protection and '
                              'Measurements (NCRP), the annual maximum permissible dose (MPD) for '
                              'occupationally exposed dental personnel is 5 rem (or 50 mSv / 0.05 Sv) '
                              'per year to ensure professional safety.',
                              style: textStyles.body.copyWith(
                                  color:
                                      colors.onSurface.withValues(alpha: 0.75)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Next Question',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewOptionTile extends StatelessWidget {
  final _ReviewOption option;
  const _ReviewOptionTile({required this.option});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semanticColors = context.semanticColors;

    late final Color bg;
    late final Color border;
    late final Color badgeBg;
    late final Widget badgeChild;

    switch (option.state) {
      case _OptionState.correct:
        bg = colors.primaryContainer;
        border = semanticColors.success;
        badgeBg = semanticColors.success;
        badgeChild = Icon(Icons.check_rounded,
            size: 15, color: semanticColors.onSuccess);
        break;
      case _OptionState.incorrectSelected:
        bg = colors.errorContainer;
        border = colors.error;
        badgeBg = colors.error;
        badgeChild = Text(option.letter,
            style: TextStyle(
                color: colors.onError,
                fontWeight: FontWeight.w700,
                fontSize: 12));
        break;
      case _OptionState.neutral:
        bg = colors.surfaceContainer;
        border = Colors.transparent;
        badgeBg = colors.primaryContainer;
        badgeChild = Text(option.letter,
            style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 12));
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.smallIcon),
        border: Border.all(color: border, width: AppBorderWidth.regular),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 13, backgroundColor: badgeBg, child: badgeChild),
          const SizedBox(width: 14),
          Expanded(
            child: Text(option.text,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colors.onSurface)),
          ),
        ],
      ),
    );
  }
}
