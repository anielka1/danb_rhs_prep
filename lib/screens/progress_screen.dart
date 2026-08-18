import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'exam_overview_screen.dart';
import 'profile_settings_screen.dart';

class ProgressScreen extends StatelessWidget {
  static const String route = '/progress';
  const ProgressScreen({super.key});

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  // Relative bar heights (0-1) matching the weekly activity chart.
  static const List<double> _activity = [0.18, 0.55, 0.10, 0.60, 0.15, 1.0, 0.40];
  static const int _peakIndex = 5; // Saturday, the tallest / darkest bar

  void _onNavTap(BuildContext context, AppTab tab) {
    switch (tab) {
      case AppTab.home:
        Navigator.of(context).pushNamedAndRemoveUntil(HomeScreen.route, (r) => false);
        break;
      case AppTab.practice:
        Navigator.of(context).pushNamed(ExamOverviewScreen.route);
        break;
      case AppTab.stats:
        break;
      case AppTab.profile:
        Navigator.of(context).pushNamed(ProfileSettingsScreen.route);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text('Your Progress', style: AppTextStyles.h1),
              const SizedBox(height: 6),
              Text('Track your study stats & milestones', style: AppTextStyles.body),
              const SizedBox(height: 26),
              Text('WEEKLY ACTIVITY (MINS)', style: AppTextStyles.label),
              const SizedBox(height: 16),
              SizedBox(
                height: 90,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_dayLabels.length, (i) {
                    final bool peak = i == _peakIndex;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 70 * _activity[i],
                          decoration: BoxDecoration(
                            color: peak ? AppColors.navy : AppColors.primary.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_dayLabels[i], style: AppTextStyles.bodySmall),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatBlock(value: '1,247', label: 'Qs Answered', color: AppColors.navy),
                  ),
                  Expanded(
                    child: _StatBlock(value: '78%', label: 'Avg Accuracy', color: AppColors.success),
                  ),
                  Expanded(
                    child: _StatBlock(
                      value: '12',
                      label: 'Day Streak',
                      color: AppColors.streakOrange,
                      leadingIcon: Icons.local_fire_department_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Weekly Goal',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy)),
                  Text('75 / 100 Qs', style: AppTextStyles.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.75,
                  minHeight: 10,
                  backgroundColor: AppColors.lavenderContainer,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 26),
              Text('SUBJECT MASTERY', style: AppTextStyles.label),
              const SizedBox(height: 12),
              const _MasteryRow(name: 'Radiation Physics', percent: 85),
              const SizedBox(height: 14),
              const _MasteryRow(name: 'Radiation Biology', percent: 72),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppTab.stats,
        onTap: (t) => _onNavTap(context, t),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? leadingIcon;

  const _StatBlock({required this.value, required this.label, required this.color, this.leadingIcon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 20, color: color),
              const SizedBox(width: 2),
            ],
            Text(value, style: AppTextStyles.statNumber.copyWith(color: color, fontSize: 24)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _MasteryRow extends StatelessWidget {
  final String name;
  final int percent;

  const _MasteryRow({required this.name, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy)),
        ),
        Text('$percent%', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
      ],
    );
  }
}
