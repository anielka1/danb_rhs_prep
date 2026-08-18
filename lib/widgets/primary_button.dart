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
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled
              ? AppColors.primary.withOpacity(0.55)
              : (color ?? AppColors.primary),
          disabledBackgroundColor: AppColors.primary.withOpacity(0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.button.copyWith(color: textColor ?? Colors.white),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: textColor ?? Colors.white, size: 20),
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
  final Color borderColor;
  final Color textColor;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.borderColor = AppColors.primary,
    this.textColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor.withOpacity(0.6), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: textColor,
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
      color: background ?? Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: iconColor ?? AppColors.navy),
        ),
      ),
    );
  }
}
