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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    background: Colors.white,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Review Question', textAlign: TextAlign.center, style: AppTextStyles.h3),
                  ),
                  CircleIconButton(
                    icon: Icons.bookmark_border_rounded,
                    background: AppColors.lavenderContainer,
                    iconColor: AppColors.primary,
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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RADIATION PROTECTION STANDARDS',
                              style: AppTextStyles.label.copyWith(color: AppColors.primary),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'What is the maximum permissible dose (MPD) of radiation for '
                              'occupational workers per year?',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.navy, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._options.map((o) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReviewOptionTile(option: o),
                          )),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.menu_book_rounded, size: 18, color: AppColors.success),
                                SizedBox(width: 8),
                                Text('Correct Explanation',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'According to the National Council on Radiation Protection and '
                              'Measurements (NCRP), the annual maximum permissible dose (MPD) for '
                              'occupationally exposed dental personnel is 5 rem (or 50 mSv / 0.05 Sv) '
                              'per year to ensure professional safety.',
                              style: AppTextStyles.body.copyWith(color: AppColors.navy.withOpacity(0.75)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Next Question',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 12),
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
    late final Color bg;
    late final Color border;
    late final Color badgeBg;
    late final Widget badgeChild;

    switch (option.state) {
      case _OptionState.correct:
        bg = AppColors.lavenderContainer;
        border = AppColors.success;
        badgeBg = AppColors.success;
        badgeChild = const Icon(Icons.check_rounded, size: 15, color: Colors.white);
        break;
      case _OptionState.incorrectSelected:
        bg = AppColors.errorBg;
        border = AppColors.error;
        badgeBg = AppColors.error;
        badgeChild = Text(option.letter,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12));
        break;
      case _OptionState.neutral:
        bg = Colors.white;
        border = Colors.transparent;
        badgeBg = AppColors.lavenderContainer;
        badgeChild = Text(option.letter,
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12));
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.4),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 13, backgroundColor: badgeBg, child: badgeChild),
          const SizedBox(width: 14),
          Expanded(
            child: Text(option.text,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.navy)),
          ),
        ],
      ),
    );
  }
}
