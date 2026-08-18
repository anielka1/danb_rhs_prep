import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppTab { home, practice, stats, profile }

/// Bottom tab bar shown on Home, Progress (Stats) and Profile screens.
class AppBottomNav extends StatelessWidget {
  final AppTab current;
  final ValueChanged<AppTab>? onTap;

  const AppBottomNav({super.key, required this.current, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: current == AppTab.home,
              onTap: () => onTap?.call(AppTab.home),
            ),
            _NavItem(
              icon: Icons.menu_book_rounded,
              label: 'Practice',
              selected: current == AppTab.practice,
              onTap: () => onTap?.call(AppTab.practice),
            ),
            _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Stats',
              selected: current == AppTab.stats,
              onTap: () => onTap?.call(AppTab.stats),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              selected: current == AppTab.profile,
              onTap: () => onTap?.call(AppTab.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.navy : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
