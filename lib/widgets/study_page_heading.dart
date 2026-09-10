import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A small decorative study badge echoes the welcome illustration without
/// adding a second navigation control or hiding text at accessibility sizes.
class StudyPageHeading extends StatelessWidget {
  const StudyPageHeading(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      this.trailing});
  final String title, subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: context.textStyles.h1),
      const SizedBox(height: AppSpacing.sm),
      Text(subtitle, style: context.textStyles.body),
    ]);
    final badge = trailing ??
        ExcludeSemantics(
            child: Container(
          width: 64,
          height: 72,
          decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(12))),
          child: Icon(icon, color: context.colors.primary, size: 30),
        ));
    return LayoutBuilder(builder: (context, constraints) {
      if (MediaQuery.textScalerOf(context).scale(16) > 22 ||
          constraints.maxWidth < 300) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [badge, const SizedBox(height: AppSpacing.lg), text]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: text),
        const SizedBox(width: AppSpacing.lg),
        badge,
      ]);
    });
  }
}
