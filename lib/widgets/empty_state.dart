import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

/// Centered "nothing here yet" placeholder: icon, title, supporting
/// message, and up to two actions. Used wherever a list/screen has no
/// content to show (e.g. no bookmarks yet, no mock attempts yet).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 56, color: context.semanticColors.mutedForeground),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(title, style: textStyles.h3, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: textStyles.body,
                textAlign: TextAlign.center,
              ),
            ],
            if (primaryActionLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                  label: primaryActionLabel!, onPressed: onPrimaryAction),
            ],
            if (secondaryActionLabel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                  label: secondaryActionLabel!, onPressed: onSecondaryAction),
            ],
          ],
        ),
      ),
    );
  }
}
