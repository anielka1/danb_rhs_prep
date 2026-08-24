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
      // The whole screen scrolls (rather than only the section list, with
      // fixed header/footer content around it) so nothing is clipped when
      // the header text and section rows grow at large Dynamic Type
      // sizes on a small device.
      body: SingleChildScrollView(
        child: Column(
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
            // Wrap, not Row: at large Dynamic Type sizes the badge and
            // score text may no longer fit on one line, and should drop
            // to a second line instead of overflowing horizontally.
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 4,
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
                Text('82 / 100', style: textStyles.body),
              ],
            ),
            const SizedBox(height: AppSpacing.xl + 2),
            const Divider(),
            const SizedBox(height: AppSpacing.md + 2),
            // Wrap, not Row: at large Dynamic Type sizes both labels may
            // no longer fit on one line together.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              children: [
                Text('Time taken: 1h 15m', style: textStyles.bodySmall),
                Text('Passing score: 80%', style: textStyles.bodySmall),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('SECTION PERFORMANCE', style: textStyles.label),
            const SizedBox(height: 4),
            // shrinkWrap + NeverScrollableScrollPhysics: this list no longer
            // owns its own scrolling (the outer SingleChildScrollView does),
            // it just sizes to its content.
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                      Expanded(
                        child: Text(s.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: colors.onSurface)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.md),
            // Disabled: reviewing past mock-exam answers requires stored
            // attempt/answer data that doesn't exist yet.
            const SecondaryButton(label: 'Review Answers', onPressed: null),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
                label: 'Retake Exam',
                onPressed: () => Navigator.of(context).maybePop()),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
