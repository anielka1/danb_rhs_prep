import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

/// Centered error placeholder with an optional retry action.
///
/// Deliberately accepts only caller-prepared, user-safe [title]/[message]
/// strings — there is no way to pass a raw exception or stack trace
/// through this widget, so it cannot leak diagnostic details to the UI.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Semantics(
          liveRegion: true,
          label: message != null ? '$title. $message' : title,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: colors.error),
              const SizedBox(height: AppSpacing.lg),
              ExcludeSemantics(
                child: Text(title,
                    style: textStyles.h3, textAlign: TextAlign.center),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ExcludeSemantics(
                  child: Text(message!,
                      style: textStyles.body, textAlign: TextAlign.center),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(label: retryLabel, onPressed: onRetry),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
