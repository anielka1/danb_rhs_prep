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
        Navigator.of(context)
            .pushNamedAndRemoveUntil(HomeScreen.route, (r) => false);
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
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primaryContainer,
                  border: Border.all(color: colors.surfaceContainer, width: 4),
                  boxShadow: [
                    // Shadow color is intentionally invariant black across
                    // themes: it represents physical light occlusion, not a
                    // surface/text/icon role.
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(Icons.person, size: 44, color: colors.primary),
              ),
              const SizedBox(height: AppSpacing.md + 2),
              Text('Sarah Jenkins', style: textStyles.h2),
              const SizedBox(height: AppSpacing.xs),
              Text('sarah.j@dentalprep.com', style: textStyles.bodySmall),
              const SizedBox(height: AppSpacing.xl + 2),
              const Row(
                children: [
                  Expanded(child: _ProfileStat(value: '#342', label: 'Rank')),
                  _VerticalDivider(),
                  Expanded(
                      child: _ProfileStat(value: '48h', label: 'Study Hours')),
                  _VerticalDivider(),
                  Expanded(
                      child: _ProfileStat(value: '12', label: 'Exams Taken')),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl + 2),
              const Divider(),
              const SizedBox(height: AppSpacing.xl),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('APP PREFERENCES', style: textStyles.label),
              ),
              const SizedBox(height: AppSpacing.md),
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
              const Divider(),
              const SizedBox(height: AppSpacing.xl - 2),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('ACCOUNT', style: textStyles.label),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AccountRow(title: 'Edit Profile', onTap: () {}),
              _AccountRow(title: 'Change Password', onTap: () {}),
              const SizedBox(height: AppSpacing.xl + 2),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil(LoginScreen.route, (r) => false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(
                        color: colors.error, width: AppBorderWidth.regular),
                  ),
                  child: Text('Sign Out',
                      style: TextStyle(
                          color: colors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          AppBottomNav(current: AppTab.profile, onTap: _onNavTap),
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
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.colors.secondary)),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: context.textStyles.bodySmall),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 34, color: context.colors.outlineVariant);
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
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: context.textStyles.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
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
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colors.onSurface)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.semanticColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
