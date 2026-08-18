import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class _SectionScore {
  final String name;
  final int percent;
  const _SectionScore(this.name, this.percent);
}

class MockExamResultsScreen extends StatelessWidget {
  static const String route = '/mock-exam-results';
  const MockExamResultsScreen({super.key});

  static const List<_SectionScore> _sections = [
    _SectionScore('Radiation Physics', 88),
    _SectionScore('Radiation Biology', 78),
    _SectionScore('Radiation Protection', 85),
    _SectionScore('Equipment Operation', 80),
    _SectionScore('Patient Management', 76),
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
                  const Text('Exam Results', style: AppTextStyles.h3),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Text('DANB RHS MOCK EXAM', style: AppTextStyles.label),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  '82%',
                  style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: const Text('PASSED',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Text('82 / 100', style: AppTextStyles.body),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Time taken: 1h 15m', style: AppTextStyles.bodySmall),
                  Text('Passing score: 80%', style: AppTextStyles.bodySmall),
                ],
              ),
              const SizedBox(height: 20),
              Text('SECTION PERFORMANCE', style: AppTextStyles.label),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.separated(
                  itemCount: _sections.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, i) {
                    final s = _sections[i];
                    final bool strong = s.percent >= 80;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy)),
                          Text(
                            '${s.percent}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: strong ? AppColors.success : AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SecondaryButton(label: 'Review Answers', onPressed: () {}),
              const SizedBox(height: 12),
              PrimaryButton(label: 'Retake Exam', onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
