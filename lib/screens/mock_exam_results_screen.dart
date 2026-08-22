import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';

class _SectionScore {
  final String name;
  final int percent;
  const _SectionScore(this.name, this.percent);
}

class MockExamResultsScreen extends StatelessWidget {
  static const String route = '/mock-exam-results';
  const MockExamResultsScreen({super.key});

  static const List<_SectionScore> _sections = [
    _SectionScore('Radiation Physics', 88),
    _SectionScore('Radiation Biology', 78),
    _SectionScore('Radiation Protection', 85),
    _SectionScore('Equipment Operation', 80),
    _SectionScore('Patient Management', 76),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semanticColors = context.semanticColors;
    final textStyles = context.textStyles;
    return AppScaffold(
      leading: CircleIconButton(
        icon: Icons.chevron_left_rounded,
        onPressed: () => Navigator.of(context).maybePop(),
        semanticLabel: 'Back',
      ),
      title: 'Exam Results',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text('DANB RHS MOCK EXAM', style: textStyles.label),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '82%',
              style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: semanticColors.successContainer,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text('PASSED',
                      style: TextStyle(
                          color: semanticColors.onSuccessContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Text('82 / 100', style: textStyles.body),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl + 2),
          const Divider(),
          const SizedBox(height: AppSpacing.md + 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Time taken: 1h 15m', style: textStyles.bodySmall),
              Text('Passing score: 80%', style: textStyles.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('SECTION PERFORMANCE', style: textStyles.label),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.separated(
              itemCount: _sections.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = _sections[i];
                final bool strong = s.percent >= 80;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colors.onSurface)),
                      Text(
                        '${s.percent}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: strong
                              ? semanticColors.success
                              : colors.secondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SecondaryButton(label: 'Review Answers', onPressed: () {}),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
              label: 'Retake Exam',
              onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
