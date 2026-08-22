import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'progress_bar.dart';

/// One row in a domain/topic mastery list: name, an optional supporting
/// count/text, and a [ProgressBar]. Performs no mastery calculation of its
/// own — [progress] is supplied by the caller.
class DomainProgressRow extends StatelessWidget {
  const DomainProgressRow({
    super.key,
    required this.domainName,
    required this.progress,
    this.supportingText,
  });

  final String domainName;

  /// 0.0-1.0.
  final double progress;

  /// e.g. "12/15 correct".
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final int percent = (progress.clamp(0, 1) * 100).round();

    return Semantics(
      label: '$domainName, $percent percent'
          '${supportingText != null ? ', $supportingText' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    domainName,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ExcludeSemantics(
                child: Text(
                  '$percent%',
                  style: textStyles.body.copyWith(
                      fontWeight: FontWeight.w600, color: colors.secondary),
                ),
              ),
            ],
          ),
          if (supportingText != null) ...[
            const SizedBox(height: 2),
            ExcludeSemantics(
                child: Text(supportingText!, style: textStyles.bodySmall)),
          ],
          const SizedBox(height: AppSpacing.xs),
          ExcludeSemantics(child: ProgressBar(value: progress)),
        ],
      ),
    );
  }
}
