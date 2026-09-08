import 'package:flutter/material.dart';
import '../services/theme_mode_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';

/// Accountless settings. Only controls backed by working behavior are shown.
class ProfileSettingsScreen extends StatelessWidget {
  static const String route = 'settings';
  const ProfileSettingsScreen({super.key, required this.themeModeController});
  final ThemeModeController themeModeController;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return AppScaffold(
      leading: CircleIconButton(
        icon: Icons.chevron_left_rounded,
        onPressed: () => Navigator.of(context).maybePop(),
        semanticLabel: 'Back',
      ),
      title: 'Settings',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text('Make it yours.', style: styles.h1),
            const SizedBox(height: AppSpacing.sm),
            Text('Your study plan. Your pace.', style: styles.body),
            const SizedBox(height: AppSpacing.xxxl),
            Text('LOOK & FEEL', style: styles.label),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeading(
                    icon: Icons.contrast_rounded,
                    title: 'Appearance',
                    subtitle: 'Easy on your eyes',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeModeController,
                    builder: (context, mode, _) => Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final entry in const {
                          ThemeMode.system: 'System',
                          ThemeMode.light: 'Light',
                          ThemeMode.dark: 'Dark',
                        }.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: mode == entry.key,
                            onSelected: (_) =>
                                themeModeController.value = entry.key,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Applies throughout the app for this session.',
                      style: styles.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Text('HELP & YOUR DATA', style: styles.label),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const _InformationSection(
                    icon: Icons.help_outline_rounded,
                    title: 'Study help',
                    text: 'Use Practice for questions with explanations. '
                        'Mock Exam saves explanations for the end. '
                        'You can return to an unfinished session from Home.',
                  ),
                  Divider(color: context.colors.outlineVariant),
                  const _InformationSection(
                    icon: Icons.shield_outlined,
                    title: 'Your data',
                    text: 'No account is needed. Study progress is stored '
                        'locally in the standard app. The debug demo uses '
                        'temporary data that resets when it restarts.',
                  ),
                  Divider(color: context.colors.outlineVariant),
                  const _InformationSection(
                    icon: Icons.info_outline_rounded,
                    title: 'About RHS Prep',
                    text: 'An independent study tool, not affiliated with '
                        'or endorsed by DANB. Practice results are educational '
                        'estimates, not official exam results.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Center(child: Text('RHS PREP', style: styles.label)),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.smallIcon),
            ),
            child: Icon(icon, color: context.colors.onPrimaryContainer),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.h3),
                Text(subtitle, style: context.textStyles.bodySmall),
              ],
            ),
          ),
        ],
      );
}

class _InformationSection extends StatelessWidget {
  const _InformationSection(
      {required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        leading: Icon(icon, color: context.colors.secondary),
        title: Text(title,
            style: context.textStyles.body.copyWith(
                fontWeight: FontWeight.w700, color: context.colors.onSurface)),
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [Text(text, style: context.textStyles.body)],
      );
}
