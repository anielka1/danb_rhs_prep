import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The big pill-shaped periwinkle button used across almost every screen
/// (Get Started, Start Practice Exam, Submit Answer, Retake Exam, etc.)
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? color;
  final Color? textColor;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.color,
    this.textColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final Color resolvedTextColor = textColor ?? context.colors.onPrimary;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Semantics(
        button: true,
        enabled: !disabled,
        label: isLoading ? '$label, loading' : label,
        child: ElevatedButton(
          // Loading prevents duplicate activation by clearing onPressed,
          // same as the disabled case, without changing the button's size.
          onPressed: disabled ? null : onPressed,
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
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: AppIconSize.medium,
                    height: AppIconSize.medium,
                    // Progress state is announced by the outer Semantics
                    // label above; exclude this indicator's own semantics
                    // to avoid a duplicate announcement.
                    child: ExcludeSemantics(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(resolvedTextColor),
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon,
                          color: resolvedTextColor, size: AppIconSize.medium),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: context.textStyles.button
                            .copyWith(color: resolvedTextColor),
                        overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

/// Outlined pill button variant (e.g. "Review Mistakes", "Review Answers").
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? borderColor;
  final Color? textColor;
  final bool isLoading;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.borderColor,
    this.textColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final Color resolvedColor = textColor ?? context.colors.primary;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Semantics(
        button: true,
        enabled: !disabled,
        label: isLoading ? '$label, loading' : label,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: resolvedColor,
            side: BorderSide(
              color: (borderColor ?? context.colors.primary)
                  .withValues(alpha: 0.6),
              width: AppBorderWidth.regular,
            ),
          ),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: AppIconSize.medium,
                    height: AppIconSize.medium,
                    child: ExcludeSemantics(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(resolvedColor),
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon,
                          color: resolvedColor, size: AppIconSize.medium),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: context.textStyles.button.copyWith(
                          color: resolvedColor,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(trailingIcon,
                          color: resolvedColor, size: AppIconSize.medium),
                    ],
                  ],
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
  final String? semanticLabel;

  const CircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.background,
    this.iconColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: onPressed != null,
      child: Material(
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
      ),
    );
  }
}
