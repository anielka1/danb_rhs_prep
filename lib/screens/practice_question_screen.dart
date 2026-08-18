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
                    icon: Icons.close_rounded,
                    background: Colors.white,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: currentQuestion / totalQuestions,
                        minHeight: 8,
                        backgroundColor: AppColors.lavenderContainer,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.access_time_rounded, size: 18, color: AppColors.navy),
                  const SizedBox(width: 4),
                  const Text('24:18',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'QUESTION $currentQuestion OF $totalQuestions',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: const Text(
                  'What is the maximum permissible dose (MPD) of radiation for '
                  'occupational workers per year?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.navy, height: 1.3),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _options
                        .map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _OptionTile(
                                option: o,
                                selected: _selected == o.letter,
                                onTap: () => setState(() => _selected = o.letter),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              PrimaryButton(
                label: 'Submit Answer',
                onPressed: () => Navigator.of(context).pushNamed(AnswerExplanationScreen.route),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primaryDark),
                    label: const Text('Previous',
                        style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      children: const [
                        Text('Next',
                            style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryDark),
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

  const _OptionTile({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.lavenderContainer : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: selected ? AppColors.primary : AppColors.lavenderContainer,
              child: Text(
                option.letter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option.text,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.navy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
