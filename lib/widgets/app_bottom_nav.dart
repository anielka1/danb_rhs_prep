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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
            top: BorderSide(color: context.colors.outlineVariant),
          ),
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
    final Color color = selected
        ? context.colors.onSurface
        : context.semanticColors.mutedForeground;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.smallIcon),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppTapTarget.minInteractive,
          minHeight: AppTapTarget.minInteractive,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: AppIconSize.standard),
              const SizedBox(height: AppSpacing.xs),
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
      ),
    );
  }
}
