import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../links/legal_links.dart';
import '../links/external_link_launcher.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';
import '../widgets/subscription_product_card.dart';
import '../domain/models/subscription_plan.dart';
import '../domain/repositories/subscription_store_repository.dart';
import '../subscription/premium_access.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen(
      {super.key,
      this.onClose,
      this.repository,
      this.linkLauncher = const UrlLauncherExternalLinkLauncher()});
  final ExternalLinkLauncher linkLauncher;
  static const route = '/subscription';
  final VoidCallback? onClose;
  final SubscriptionStoreRepository? repository;
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionStoreRepository? _repository;
  List<SubscriptionPlan> _plans = [];
  String? _selected;
  String? _message;
  bool _loading = true;
  bool _busy = false;
  bool _initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final repository =
        widget.repository ?? PremiumAccessScope.maybeOf(context)?.repository;
    _repository = repository is SubscriptionStoreRepository ? repository : null;
    _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final repository = _repository;
      if (repository == null) {
        throw const SubscriptionException(SubscriptionFailure.configuration);
      }
      final plans = await repository.plans();
      if (!mounted) return;
      if (plans.isEmpty) {
        throw const SubscriptionException(SubscriptionFailure.unavailable);
      }
      setState(() {
        _plans = plans;
        _selected = plans.any((p) => p.id == 'monthly' && p.available)
            ? 'monthly'
            : plans.where((p) => p.available).firstOrNull?.id;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _plans = [];
          _selected = null;
          _message = _error(e);
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _error(Object e) => e is SubscriptionException
      ? e.message
      : 'Could not complete the store request. Please try again.';
  void _close() => widget.onClose != null
      ? widget.onClose!()
      : Navigator.of(context).maybePop();
  Future<void> _request({bool restore = false}) async {
    if (_busy || _repository == null || (!restore && _selected == null)) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = restore
          ? await _repository!.restore()
          : await _repository!.purchase(_selected!);
      if (!mounted) return;
      if (result?.isActiveAt(DateTime.now()) == true) {
        _close();
      } else if (result != null) {
        setState(() => _message = restore
            ? 'No active subscription was found.'
            : 'Your purchase has not activated Premium yet. Try Restore purchases or check again shortly.');
      }
    } catch (e) {
      if (mounted) setState(() => _message = _error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLegalPage(Uri uri) async {
    bool opened;
    try {
      opened = await widget.linkLauncher.open(uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open this page. Please try again.')));
    }
  }

  Widget _legalLink(String label, Uri uri) => Semantics(
      label: label,
      link: true,
      onTap: () => _openLegalPage(uri),
      excludeSemantics: true,
      child: TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => _openLegalPage(uri),
          child: Text(label)));

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
            onPressed: _close),
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
            if (_loading)
              const Center(
                  child: CircularProgressIndicator(
                      semanticsLabel: 'Loading plans')),
            for (final plan in _plans) ...[
              SubscriptionProductCard(
                  title: plan.name,
                  priceText: plan.localizedPrice,
                  billingPeriodText: plan.billingPeriod,
                  introductoryOfferText: plan.trialDescription,
                  selected: plan.id == _selected,
                  enabled: !_busy && plan.available,
                  onSelect: () => setState(() => _selected = plan.id)),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_message != null)
              Semantics(
                  liveRegion: true,
                  child: Text(_message!,
                      style: styles.bodySmall, textAlign: TextAlign.center)),
            if (!_loading && _plans.isEmpty)
              TextButton(
                  onPressed: _busy ? null : _load, child: const Text('Retry')),
            if (_plans.isNotEmpty)
              Text(
                  'Subscriptions renew automatically unless cancelled in your App Store settings.',
                  style: styles.bodySmall,
                  textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            if (_busy)
              const Center(
                  child: CircularProgressIndicator(
                      semanticsLabel: 'Waiting for the store')),
            PrimaryButton(
                label: _selected == null
                    ? 'Continue'
                    : 'Continue with ${_plans.firstWhere((p) => p.id == _selected).name}',
                onPressed: _busy || _loading || _selected == null
                    ? null
                    : () => _request()),
            TextButton(
                onPressed: _busy || _repository == null
                    ? null
                    : () => _request(restore: true),
                child: const Text('Restore purchases')),
            Wrap(alignment: WrapAlignment.center, children: [
              _legalLink('Terms of Use', LegalLinks.termsOfUse),
              _legalLink('Privacy Policy', LegalLinks.privacyPolicy),
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
