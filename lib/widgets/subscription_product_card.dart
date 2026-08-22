import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Presentation-only subscription product card. Every price and offer
/// string is supplied by the caller (ultimately from the store) — this
/// widget never imports StoreKit or `in_app_purchase`, never calculates a
/// discount, and never decides which product is "recommended" on its own.
class SubscriptionProductCard extends StatelessWidget {
  const SubscriptionProductCard({
    super.key,
    required this.title,
    required this.priceText,
    required this.billingPeriodText,
    this.introductoryOfferText,
    this.selected = false,
    this.recommended = false,
    this.onSelect,
    this.isLoading = false,
    this.enabled = true,
  });

  final String title;

  /// Store-provided, already-localized price string (e.g. "$9.99").
  final String priceText;

  /// e.g. "per month", "every 3 months".
  final String billingPeriodText;

  /// e.g. "3 days free, then $9.99/month".
  final String? introductoryOfferText;

  final bool selected;

  /// Only ever shown when the caller explicitly sets this — never
  /// inferred by this widget from price comparisons.
  final bool recommended;

  final VoidCallback? onSelect;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semanticColors = context.semanticColors;
    final textStyles = context.textStyles;
    final bool interactive = enabled && !isLoading && onSelect != null;

    return AppCard(
      selected: selected,
      onTap: interactive ? onSelect : null,
      semanticLabel: [
        title,
        priceText,
        billingPeriodText,
        if (recommended) 'recommended',
        if (isLoading) 'loading',
      ].join(', '),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(child: Text(title, style: textStyles.h3)),
                    if (recommended) ...[
                      const SizedBox(width: AppSpacing.sm),
                      ExcludeSemantics(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: textStyles.label
                                .copyWith(color: colors.primary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ExcludeSemantics(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: priceText,
                          style:
                              textStyles.h2.copyWith(color: colors.onSurface),
                        ),
                        TextSpan(
                            text: ' $billingPeriodText',
                            style: textStyles.bodySmall),
                      ],
                    ),
                  ),
                ),
                if (introductoryOfferText != null) ...[
                  const SizedBox(height: 2),
                  ExcludeSemantics(
                    child: Text(
                      introductoryOfferText!,
                      style: textStyles.bodySmall
                          .copyWith(color: semanticColors.success),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ExcludeSemantics(
            child: isLoading
                ? SizedBox(
                    width: AppIconSize.standard,
                    height: AppIconSize.standard,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: colors.primary),
                  )
                : Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? colors.primary : colors.outline,
                    size: AppIconSize.standard,
                  ),
          ),
        ],
      ),
    );
  }
}
