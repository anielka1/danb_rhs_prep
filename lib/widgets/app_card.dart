import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standard surface container used across the app: token-based padding,
/// consistent radius, and an optional tap target with proper interactive
/// semantics. Every other card-shaped component (`ReadinessCard`,
/// `SubscriptionProductCard`) composes this rather than reimplementing
/// its own container.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.selected,
    this.semanticLabel,
  });

  final Widget child;

  /// When non-null, the card becomes tappable and exposes button
  /// semantics; when null, it renders as plain, non-interactive content.
  final VoidCallback? onTap;

  final EdgeInsetsGeometry? padding;

  /// Overrides the default `surfaceContainer` fill. Used by callers that
  /// need an accent-colored card (e.g. a highlighted primary-colored
  /// promotion) rather than a plain surface.
  final Color? backgroundColor;

  /// Whether this card represents a selectable option, and if so, whether
  /// it's currently chosen. Three states, not two:
  /// * `null` (default) — this card has no selection concept at all (e.g.
  ///   an ordinary informational/navigation card). No selected-state
  ///   semantics are exposed, so VoiceOver never announces "not selected"
  ///   for a card that was never selectable in the first place.
  /// * `false` — part of a selectable set, currently not chosen (e.g. an
  ///   unselected `SubscriptionProductCard`).
  /// * `true` — part of a selectable set, currently chosen; also shows the
  ///   emphasized primary border.
  final bool? selected;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool isSelected = selected == true;
    final borderRadius = BorderRadius.circular(AppRadii.card);
    final Widget paddedChild = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
    // When an explicit semanticLabel is given, it's meant to replace the
    // child's own text/icon semantics with one curated announcement rather
    // than merging with them.
    final Widget content = semanticLabel == null
        ? paddedChild
        : ExcludeSemantics(child: paddedChild);

    final Widget card = Material(
      color: backgroundColor ?? colors.surfaceContainer,
      elevation: AppElevation.card,
      shadowColor: colors.primary.withValues(alpha: 0.10),
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
              width: isSelected ? AppBorderWidth.thick : 0.7),
        ),
        child: onTap == null
            ? content
            : InkWell(borderRadius: borderRadius, onTap: onTap, child: content),
      ),
    );

    if (semanticLabel == null && onTap == null && selected == null) return card;
    return Semantics(
      button: onTap != null,
      // `selected` is passed through as-is: Semantics itself treats a null
      // value as "no selected-state concept" and only sets hasSelectedState
      // when given an explicit true/false.
      selected: selected,
      label: semanticLabel,
      child: card,
    );
  }
}
