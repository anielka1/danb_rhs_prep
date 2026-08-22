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
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: colors.primary, size: AppIconSize.large),
              ),
              const SizedBox(height: 18),
              Text('Session Complete!', style: textStyles.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You did an outstanding job reviewing today.',
                textAlign: TextAlign.center,
                style: textStyles.body,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('78%', style: textStyles.statNumber),
                        const SizedBox(height: AppSpacing.xs),
                        Text('78/100 Correct', style: textStyles.bodySmall),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('42m', style: textStyles.statNumber),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Time Spent', style: textStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl + 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('TOPIC BREAKDOWN', style: textStyles.label),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.separated(
                  itemCount: _breakdown.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = _breakdown[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: colors.onSurface)),
                          Text('${t.percent}%',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: colors.secondary)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SecondaryButton(label: 'Review Mistakes', onPressed: () {}),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Back to Home',
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    HomeScreen.route, (route) => false),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
