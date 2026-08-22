import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The big pill-shaped periwinkle button used across almost every screen
/// (Get Started, Start Practice Exam, Submit Answer, Retake Exam, etc.)
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final Color? color;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailingIcon,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;
    final Color resolvedTextColor = textColor ?? context.colors.onPrimary;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: color != null || disabled
            ? ElevatedButton.styleFrom(
                backgroundColor: disabled
                    ? context.colors.primary.withValues(alpha: 0.55)
                    : color,
                disabledBackgroundColor: context.colors.primary.withValues(
                  alpha: 0.55,
                ),
              )
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.textStyles.button.copyWith(
                color: resolvedTextColor,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(trailingIcon,
                  color: resolvedTextColor, size: AppIconSize.medium),
            ],
          ],
        ),
      ),
    );
  }
}

/// Outlined pill button variant (e.g. "Review Mistakes", "Review Answers").
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? textColor;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor = textColor ?? context.colors.primary;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: resolvedColor,
          side: BorderSide(
            color: (borderColor ?? context.colors.primary).withValues(
              alpha: 0.6,
            ),
            width: AppBorderWidth.regular,
          ),
        ),
        child: Text(
          label,
          style: context.textStyles.button.copyWith(
            color: resolvedColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Small circular back / close button used in nav bars.
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? iconColor;

  const CircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.background,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? context.colors.surfaceContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: AppTapTarget.minInteractive,
          height: AppTapTarget.minInteractive,
          child: Icon(
            icon,
            size: AppIconSize.medium,
            color: iconColor ?? context.colors.onSurface,
          ),
        ),
      ),
    );
  }
}
