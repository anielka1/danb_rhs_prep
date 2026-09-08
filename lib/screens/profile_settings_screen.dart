import 'package:flutter/material.dart';
import '../services/theme_mode_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';

class ProfileSettingsScreen extends StatefulWidget {
  static const String route = 'settings';

  const ProfileSettingsScreen({super.key, required this.themeModeController});

  /// App-level controller (owned by `DanbRhsPrepApp`, not this screen) —
  /// reading/writing it here, rather than holding a local bool, is what
  /// makes the whole app update immediately and the choice survive
  /// navigating away from and back to this screen.
  final ThemeModeController themeModeController;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  // Push Notifications and Sound Effects have no backing feature yet (no
  // notification-permission/scheduling system, no audio system) — the
  // switches are disabled rather than wired to a setState-only bool that
  // would otherwise look like it's toggling a real feature.

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return AppScaffold(
      leading: CircleIconButton(
        icon: Icons.chevron_left_rounded,
        onPressed: () => Navigator.of(context).maybePop(),
        semanticLabel: 'Back',
      ),
      title: 'Settings',
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primaryContainer,
                border: Border.all(color: colors.surfaceContainer, width: 4),
                boxShadow: [
                  BoxShadow(
                      color: AppShadowColors.base.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(Icons.person, size: 44, color: colors.primary),
            ),
            const SizedBox(height: AppSpacing.md + 2),
            // No account/auth system exists yet — an honest "no profile
            // loaded" placeholder, not a fabricated name, stands in until
            // sign-in is real. See docs/PROTOTYPE_CONTENT_AUDIT.md.
            Text('Guest', style: textStyles.h2),
            const SizedBox(height: AppSpacing.xs),
            Text('Not signed in', style: textStyles.bodySmall),
            const SizedBox(height: AppSpacing.xl + 2),
            // Same reasoning: no progress/attempt data exists yet, so the
            // stat values are an honest "not available" placeholder
            // rather than fabricated numbers.
            const Row(
              children: [
                Expanded(child: _ProfileStat(value: '—', label: 'Rank')),
                _VerticalDivider(),
                Expanded(child: _ProfileStat(value: '—', label: 'Study Hours')),
                _VerticalDivider(),
                Expanded(child: _ProfileStat(value: '—', label: 'Exams Taken')),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl + 2),
            const Divider(),
            const SizedBox(height: AppSpacing.xl),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('APP PREFERENCES', style: textStyles.label),
            ),
            const SizedBox(height: AppSpacing.md),
            // Disabled: no notification-permission/scheduling system
            // exists yet to back this preference.
            const _PreferenceRow(
              title: 'Push Notifications',
              subtitle: 'Daily alerts & streak reminders',
              value: true,
              onChanged: null,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Appearance',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colors.onSurface)),
            ),
            const SizedBox(height: 2),
            Text('System, Light, or Dark', style: textStyles.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: widget.themeModeController,
                builder: (context, mode, _) {
                  return SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_rounded)),
                      ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded)),
                    ],
                    selected: {mode},
                    onSelectionChanged: (selection) =>
                        widget.themeModeController.value = selection.first,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Disabled: no audio system exists yet to back this
            // preference.
            const _PreferenceRow(
              title: 'Sound Effects',
              subtitle: 'Play sound on question feedback',
              value: true,
              onChanged: null,
            ),
            // No "ACCOUNT" section (PREP-459): this app is accountless in
            // V1, with no sign-in and no plan to add one — there is no
            // account for a guest to edit or a password to change.
            // PREP-652 had kept "Edit Profile"/"Change Password" visible
            // but disabled, on the premise that a future auth phase might
            // still arrive; PREP-459 deliberately reverses that call
            // (see docs/INTERACTION_CONTROL_AUDIT.md) since "disabled and
            // waiting" is dishonest for a capability this product will
            // never have, not merely one that isn't built yet.
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    // "—" reads clearly on its own visually, but a screen reader hearing
    // just "dash, Rank" wouldn't — one merged, honest announcement
    // instead of two disconnected ones.
    return Semantics(
      label: value == '—' ? '$label: not yet available' : '$label: $value',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.colors.secondary)),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: context.textStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 34, color: context.colors.outlineVariant);
  }
}

class _PreferenceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;

  /// Null renders (and behaves as) a disabled row: no tap/toggle action
  /// reaches assistive services, and the text is visually muted to match
  /// — this is how a not-yet-implemented preference is represented,
  /// rather than a switch that toggles a bool nothing else reads.
  final ValueChanged<bool>? onChanged;

  const _PreferenceRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool enabled = onChanged != null;
    final Color textColor =
        enabled ? colors.onSurface : context.semanticColors.mutedForeground;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: textColor)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: context.textStyles.bodySmall
                        .copyWith(color: enabled ? null : textColor)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
