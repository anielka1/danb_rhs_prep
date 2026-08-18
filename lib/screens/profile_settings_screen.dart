import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'exam_overview_screen.dart';
import 'progress_screen.dart';
import 'login_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  static const String route = '/profile';
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _pushNotifications = true;
  bool _darkMode = false;
  bool _soundEffects = true;

  void _onNavTap(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        Navigator.of(context).pushNamedAndRemoveUntil(HomeScreen.route, (r) => false);
        break;
      case AppTab.practice:
        Navigator.of(context).pushNamed(ExamOverviewScreen.route);
        break;
      case AppTab.stats:
        Navigator.of(context).pushNamed(ProgressScreen.route);
        break;
      case AppTab.profile:
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
            children: [
              const SizedBox(height: 16),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lavenderContainer,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.person, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              const Text('Sarah Jenkins', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text('sarah.j@dentalprep.com', style: AppTextStyles.bodySmall),
              const SizedBox(height: 22),
              Row(
                children: const [
                  Expanded(child: _ProfileStat(value: '#342', label: 'Rank')),
                  _VerticalDivider(),
                  Expanded(child: _ProfileStat(value: '48h', label: 'Study Hours')),
                  _VerticalDivider(),
                  Expanded(child: _ProfileStat(value: '12', label: 'Exams Taken')),
                ],
              ),
              const SizedBox(height: 26),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('APP PREFERENCES', style: AppTextStyles.label),
              ),
              const SizedBox(height: 12),
              _PreferenceRow(
                title: 'Push Notifications',
                subtitle: 'Daily alerts & streak reminders',
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
              ),
              _PreferenceRow(
                title: 'Dark Mode',
                subtitle: 'Switch to dark appearance',
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
              ),
              _PreferenceRow(
                title: 'Sound Effects',
                subtitle: 'Play sound on question feedback',
                value: _soundEffects,
                onChanged: (v) => setState(() => _soundEffects = v),
              ),
              const SizedBox(height: 10),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('ACCOUNT', style: AppTextStyles.label),
              ),
              const SizedBox(height: 8),
              _AccountRow(title: 'Edit Profile', onTap: () {}),
              _AccountRow(title: 'Change Password', onTap: () {}),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil(LoginScreen.route, (r) => false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error, width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
                  ),
                  child: const Text('Sign Out',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(current: AppTab.profile, onTap: _onNavTap),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: AppColors.divider);
  }
}

class _PreferenceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.lavenderContainer,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _AccountRow({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy)),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
