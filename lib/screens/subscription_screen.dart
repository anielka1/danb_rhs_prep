import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';
import '../widgets/subscription_product_card.dart';

/// Temporary presentation copy, deliberately disconnected from access/storage.
const _previewPlans = [
  (title: 'Weekly', price: '69,99 zł', period: '/ week'),
  (title: 'Monthly', price: '149,99 zł', period: '/ month'),
];

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, this.onClose});
  static const route = '/subscription';
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final colors = context.colors;
    return AppScaffold(
        body: Column(children: [
      Row(children: [
        Expanded(child: Text('DANB RHS', style: styles.label)),
        CircleIconButton(
            icon: Icons.close_rounded,
            semanticLabel: 'Close subscription',
            onPressed: onClose ?? () => Navigator.of(context).maybePop()),
      ]),
      Expanded(
          child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            const SizedBox(height: AppSpacing.lg),
            Center(
                child: ExcludeSemantics(
                    child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: colors.primaryContainer),
              child: Stack(alignment: Alignment.center, children: [
                Icon(Icons.menu_book_rounded, size: 94, color: colors.primary),
                Positioned(
                    top: 8,
                    right: 4,
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 32, color: colors.primary)),
              ]),
            ))),
            const SizedBox(height: AppSpacing.xl),
            Text('Make room for\nmore learning',
                style: styles.h1, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text('Choose your Premium plan.',
                style: styles.body, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            const AppCard(
                child: Column(children: [
              _Benefit(Icons.schedule_rounded, 'Practice at your pace',
                  'Build confidence with focused practice whenever you have time.'),
              Divider(),
              _Benefit(Icons.menu_book_rounded, 'Focus by subject',
                  'Target the topics you want to strengthen across all exam areas.'),
              Divider(),
              _Benefit(Icons.bar_chart_rounded, 'Review your learning',
                  'Revisit questions and explanations to reinforce key concepts.'),
            ])),
            const SizedBox(height: AppSpacing.xl),
            Text('Choose your plan', style: styles.h3),
            const SizedBox(height: AppSpacing.md),
            for (final plan in _previewPlans) ...[
              SubscriptionProductCard(
                  title: plan.title,
                  priceText: plan.price,
                  billingPeriodText: plan.period,
                  selected: plan.title == 'Monthly',
                  enabled: false),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
                'Preview prices only. Purchases and restores are not available yet. No payment will be taken.',
                style: styles.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            const PrimaryButton(
                label: 'Continue with Monthly', onPressed: null),
            const TextButton(onPressed: null, child: Text('Restore purchases')),
            // No legal URLs are configured in this app. Do not invent destinations.
            const Wrap(alignment: WrapAlignment.center, children: [
              TextButton(onPressed: null, child: Text('Terms of Use')),
              TextButton(onPressed: null, child: Text('Privacy Policy')),
            ]),
            const SizedBox(height: AppSpacing.xl),
          ]))),
    ]));
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.title, this.description);
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) {
    final text =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: context.textStyles.body.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: AppSpacing.xs),
      Text(description, style: context.textStyles.bodySmall),
    ]);
    final glyph = CircleAvatar(
        backgroundColor: context.colors.primaryContainer,
        foregroundColor: context.colors.primary,
        child: Icon(icon));
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: MediaQuery.textScalerOf(context).scale(1) >= 1.8
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [glyph, const SizedBox(height: AppSpacing.sm), text])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                glyph,
                const SizedBox(width: AppSpacing.md),
                Expanded(child: text)
              ]));
  }
}
