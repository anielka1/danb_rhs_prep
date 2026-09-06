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

    // liveRegion + a merged label, matching ErrorState/LoadingState (the
    // other two members of the shared loading/empty/error trio): without
    // it, a screen transitioning into "nothing here yet" — e.g. Progress
    // once loading finishes, Mock Exam when unavailable — never gets
    // proactively announced to VoiceOver/TalkBack the way the loading and
    // error transitions already are. The icon and text are excluded from
    // the semantics tree so they aren't announced a second time as their
    // own nodes; the actions stay outside that exclusion so they remain
    // independently focusable and actionable.
    final Widget content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Semantics(
        liveRegion: true,
        label: message != null ? '$title. $message' : title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ExcludeSemantics(
                child: Icon(icon,
                    size: 56, color: context.semanticColors.mutedForeground),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            ExcludeSemantics(
              child: Text(title,
                  style: textStyles.h3, textAlign: TextAlign.center),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ExcludeSemantics(
                child: Text(
                  message!,
                  style: textStyles.body,
                  textAlign: TextAlign.center,
                ),
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

    // LayoutBuilder + a minHeight matching the available space: content
    // stays exactly centered when it fits (identical to a plain `Center`
    // at ordinary text sizes), but becomes scrollable instead of
    // overflowing if large Dynamic Type text makes it taller than the
    // available space. Only applies when the incoming height is actually
    // bounded (e.g. AppScaffold's body slot): when EmptyState is nested
    // inside an ancestor that's already scrollable (unbounded height —
    // maxHeight would be infinite), `BoxConstraints(minHeight: infinity)`
    // is itself invalid, and unnecessary besides, since that ancestor
    // already handles "become scrollable instead of overflowing".
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) {
          return Center(child: content);
        }
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}
