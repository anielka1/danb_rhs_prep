import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Centered progress indicator with an optional message. Intended to fill
/// the same region the loaded content will eventually occupy, so callers
/// should place it inside the same sized/`Expanded` area as the content
/// it stands in for — that alone avoids layout jumps on load completion.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Center(
      child: Semantics(
        liveRegion: true,
        label: message ?? 'Loading',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: CircularProgressIndicator(color: colors.primary),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ExcludeSemantics(
                child: Text(message!,
                    style: textStyles.body, textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
