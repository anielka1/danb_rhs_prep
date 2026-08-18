import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';

class _TopicScore {
  final String name;
  final int percent;
  const _TopicScore(this.name, this.percent);
}

class PracticeSummaryScreen extends StatelessWidget {
  static const String route = '/practice-summary';
  const PracticeSummaryScreen({super.key});

  static const List<_TopicScore> _breakdown = [
    _TopicScore('Radiation Physics', 85),
    _TopicScore('Radiation Biology', 72),
    _TopicScore('Radiation Protection', 80),
    _TopicScore('Equipment Operation', 75),
    _TopicScore('Patient Management', 70),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.lavenderContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 18),
              const Text('Session Complete!', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'You did an outstanding job reviewing today.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('78%', style: AppTextStyles.statNumber),
                        const SizedBox(height: 4),
                        Text('78/100 Correct', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('42m', style: AppTextStyles.statNumber),
                        const SizedBox(height: 4),
                        Text('Time Spent', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('TOPIC BREAKDOWN', style: AppTextStyles.label),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _breakdown.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, i) {
                    final t = _breakdown[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy)),
                          Text('${t.percent}%',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primaryDark)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SecondaryButton(label: 'Review Mistakes', onPressed: () {}),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Back to Home',
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(HomeScreen.route, (route) => false),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
