import 'package:flutter/material.dart';
import '../features/exams/domain/exam_config.dart';
import '../subscriptions/subscription_scope.dart';
import '../subscriptions/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';
import '../widgets/subscription_product_card.dart';

/// UI consumes domain offers only; RevenueCat and platform types stay in data.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, required this.products,
    required this.controller});
  final SubscriptionProductIds products;
  final SubscriptionController controller;

  static Future<bool> show(BuildContext context,
      SubscriptionProductIds products) async {
    final controller = SubscriptionScope.maybeOf(context);
    if (controller == null) return false;
    return await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(builder: (_) => SubscriptionScreen(
        products: products, controller: controller)),
    ) ?? false;
  }

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<SubscriptionOffer> _offers = const [];
  String? _selected;
  String? _message;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onEntitlementChanged);
    _load();
  }

  void _onEntitlementChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onEntitlementChanged);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _message = null; _offers = const []; _selected = null; });
    try {
      final offers = await widget.controller.service.loadOffers(widget.products);
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _selected = offers.first.productId;
      });
    } on SubscriptionFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; });
    try {
      await action();
    } on SubscriptionFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) setState(() => _message = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _purchase() => _action(() async {
    final result = await widget.controller.service.purchase(_selected!);
    if (!mounted) return;
    switch (result) {
      case PurchaseOutcome.purchased:
        final entitlement = await widget.controller.refresh();
        if (mounted && entitlement.isActiveAt(DateTime.now())) {
          Navigator.of(context).pop(true);
        }
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.pending:
        setState(() => _message =
            'Your payment is awaiting approval. Premium unlocks after confirmation.');
    }
  });

  Future<void> _restore() => _action(() async {
    final entitlement = await widget.controller.service.restorePurchases();
    await widget.controller.refresh();
    if (!mounted) return;
    if (entitlement.isActiveAt(DateTime.now())) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _message = 'No active subscription was found for this Apple Account.');
    }
  });

  String _title(SubscriptionPeriod period) => switch (period) {
    SubscriptionPeriod.weekly => 'Weekly',
    SubscriptionPeriod.monthly => 'Monthly',
    SubscriptionPeriod.threeMonths => '3 Months',
  };

  String _period(SubscriptionPeriod period) => switch (period) {
    SubscriptionPeriod.weekly => 'per week',
    SubscriptionPeriod.monthly => 'per month',
    SubscriptionPeriod.threeMonths => 'every 3 months',
  };

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final premium = widget.controller.entitlement.isActiveAt(DateTime.now());
    final selected = _offers.where((offer) => offer.productId == _selected).firstOrNull;
    return PopScope(
      canPop: !_busy,
      child: AppScaffold(
        title: 'Premium',
        leading: CircleIconButton(icon: Icons.close_rounded,
          semanticLabel: 'Close',
          onPressed: _busy ? null : () => Navigator.of(context).pop(false)),
        body: SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(premium ? 'Premium is active' : 'Prepare with confidence', style: styles.h1),
            const SizedBox(height: AppSpacing.lg),
            Text('Unlimited practice and mock exams with the available reviewed question bank. '
              'All three plans include the same Premium access.', style: styles.body),
            const SizedBox(height: AppSpacing.xl),
            if (_loading) const Center(child: CircularProgressIndicator())
            else if (!premium) ...[
              for (final offer in _offers) ...[
                SubscriptionProductCard(title: _title(offer.period),
                  priceText: offer.localizedPrice,
                  billingPeriodText: _period(offer.period),
                  selected: offer.productId == _selected,
                  enabled: !_busy,
                  onSelect: () => setState(() => _selected = offer.productId)),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_offers.isEmpty)
                TextButton(onPressed: _busy ? null : _load,
                  child: const Text('Reload plans')),
              if (selected != null) ...[
                Text('${selected.localizedPrice} ${_period(selected.period)}. '
                  'Automatically renews until cancelled. Payment is charged to your Apple Account. '
                  'Manage or cancel in App Store subscriptions.', style: styles.bodySmall),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(label: _busy ? 'Please wait…' : 'Subscribe',
                  onPressed: _busy ? null : _purchase),
              ],
            ],
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Semantics(liveRegion: true, child: Text(_message!, style: styles.body)),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextButton(onPressed: _busy ? null : _restore,
              child: const Text('Restore Purchases')),
            for (final entry in const {
              SubscriptionLink.manage: 'Manage Subscription',
              SubscriptionLink.terms: 'Terms of Use',
              SubscriptionLink.privacy: 'Privacy Policy',
            }.entries)
              TextButton(onPressed: _busy ? null : () => _action(
                () => widget.controller.service.openLink(entry.key)),
                child: Text(entry.value)),
            const SizedBox(height: AppSpacing.xl),
          ],
        )),
      ),
    );
  }
}
