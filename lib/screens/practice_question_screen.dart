import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'answer_explanation_screen.dart';

class _Option {
  final String letter;
  final String text;
  const _Option(this.letter, this.text);
}

class PracticeQuestionScreen extends StatefulWidget {
  static const String route = '/practice-question';
  const PracticeQuestionScreen({super.key});

  @override
  State<PracticeQuestionScreen> createState() => _PracticeQuestionScreenState();
}

class _PracticeQuestionScreenState extends State<PracticeQuestionScreen> {
  static const int totalQuestions = 100;
  static const int currentQuestion = 12;

  static const List<_Option> _options = [
    _Option('A', '5 rem (0.05 Sv)'),
    _Option('B', '10 rem (0.10 Sv)'),
    _Option('C', '15 rem (0.15 Sv)'),
    _Option('D', '50 rem (0.50 Sv)'),
  ];

  String _selected = 'A';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: currentQuestion / totalQuestions,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.access_time_rounded,
                      size: AppIconSize.medium - 2, color: colors.onSurface),
                  const SizedBox(width: AppSpacing.xs),
                  Text('24:18',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl + 2),
              Text(
                'QUESTION $currentQuestion OF $totalQuestions',
                style: textStyles.label,
              ),
              const SizedBox(height: AppSpacing.md + 2),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: Text(
                  'What is the maximum permissible dose (MPD) of radiation for '
                  'occupational workers per year?',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: colors.onSurface,
                      height: 1.3),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _options
                        .map((o) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _OptionTile(
                                option: o,
                                selected: _selected == o.letter,
                                onTap: () =>
                                    setState(() => _selected = o.letter),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              PrimaryButton(
                label: 'Submit Answer',
                onPressed: () => Navigator.of(context)
                    .pushNamed(AnswerExplanationScreen.route),
              ),
              const SizedBox(height: AppSpacing.md + 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.arrow_back_rounded,
                        size: AppIconSize.small, color: colors.secondary),
                    label: Text('Previous',
                        style: TextStyle(
                            color: colors.secondary,
                            fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      children: [
                        Text('Next',
                            style: TextStyle(
                                color: colors.secondary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(Icons.arrow_forward_rounded,
                            size: AppIconSize.small, color: colors.secondary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final _Option option;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile(
      {required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadii.smallIcon),
          border: Border.all(
            color: selected ? colors.primary : Colors.transparent,
            width: AppBorderWidth.regular,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor:
                  selected ? colors.primary : colors.primaryContainer,
              child: Text(
                option.letter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
