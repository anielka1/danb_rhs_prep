import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/domain_progress_row.dart';
import '../widgets/progress_bar.dart';

class ProgressScreen extends StatelessWidget {
  static const String route = '/progress';
  const ProgressScreen({super.key});

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  // Relative bar heights (0-1) matching the weekly activity chart.
  static const List<double> _activity = [
    0.18,
    0.55,
    0.10,
    0.60,
    0.15,
    1.0,
    0.40
  ];
  static const int _peakIndex = 5; // Saturday, the tallest / darkest bar

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semanticColors = context.semanticColors;
    final textStyles = context.textStyles;
    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text('Your Progress', style: textStyles.h1),
            const SizedBox(height: 6),
            Text('Track your study stats & milestones', style: textStyles.body),
            const SizedBox(height: AppSpacing.xxl + 2),
            Text('WEEKLY ACTIVITY (MINS)', style: textStyles.label),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              label: 'Weekly activity chart',
              child: SizedBox(
                height: 100,
                child: ExcludeSemantics(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_dayLabels.length, (i) {
                      final bool peak = i == _peakIndex;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 70 * _activity[i],
                            decoration: BoxDecoration(
                              color: peak
                                  ? colors.onSurface
                                  : colors.primary.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(_dayLabels[i], style: textStyles.bodySmall),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Divider(),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _StatBlock(
                      value: '1,247',
                      label: 'Qs Answered',
                      color: colors.onSurface),
                ),
                Expanded(
                  child: _StatBlock(
                      value: '78%',
                      label: 'Avg Accuracy',
                      color: semanticColors.success),
                ),
                Expanded(
                  child: _StatBlock(
                    value: '12',
                    label: 'Day Streak',
                    color: semanticColors.accent,
                    leadingIcon: Icons.local_fire_department_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Divider(),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weekly Goal',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.onSurface)),
                Text('75 / 100 Qs', style: textStyles.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            const ProgressBar(
                value: 0.75, height: 10, semanticLabel: 'Weekly goal progress'),
            const SizedBox(height: AppSpacing.xxl + 2),
            Text('SUBJECT MASTERY', style: textStyles.label),
            const SizedBox(height: AppSpacing.md),
            const DomainProgressRow(
                domainName: 'Radiation Physics', progress: 0.85),
            const SizedBox(height: 14),
            const DomainProgressRow(
                domainName: 'Radiation Biology', progress: 0.72),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? leadingIcon;

  const _StatBlock(
      {required this.value,
      required this.label,
      required this.color,
      this.leadingIcon});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: AppIconSize.medium, color: color),
                  const SizedBox(width: 2),
                ],
                Text(value,
                    style: context.textStyles.statNumber
                        .copyWith(color: color, fontSize: 24)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: context.textStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
