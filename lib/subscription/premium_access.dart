import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/models/entitlement.dart';
import '../domain/repositories/subscription_repository.dart';
import '../domain/repositories/bootstrap_local_store.dart';
import '../screens/subscription_screen.dart';
import '../widgets/app_scaffold.dart';

/// Offline access only. Never writes an entitlement or simulates a purchase.
class CachedSubscriptionRepository implements SubscriptionRepository {
  CachedSubscriptionRepository(this.store);
  final BootstrapLocalStore store;
  @override
  Future<Entitlement> currentEntitlement() async =>
      await store.readEntitlementSnapshot() ??
      Entitlement.free(lastVerifiedAt: DateTime.now().toUtc());
  @override
  Stream<Entitlement> entitlementChanges() => const Stream.empty();
}

/// One app-owned subscription state, above both the root and tab navigators.
/// Refresh and failures fail closed; expiry is enforced even without an event.
class PremiumAccessController extends ChangeNotifier
    with WidgetsBindingObserver {
  PremiumAccessController(this.repository, {this.now = DateTime.now}) {
    WidgetsBinding.instance.addObserver(this);
    _subscription = repository.entitlementChanges().listen((value) {
      _revision++;
      _accept(value);
    }, onError: (Object _) {
      _revision++;
      _fail();
    });
    refresh();
  }
  final SubscriptionRepository repository;
  final DateTime Function() now;
  Entitlement? entitlement;
  bool loading = true;
  bool failed = false;
  bool _disposed = false;
  int _revision = 0;
  Timer? _expiry;
  StreamSubscription<Entitlement>? _subscription;
  bool get active =>
      !loading && !failed && (entitlement?.isActiveAt(now()) ?? false);
  Future<void> refresh() async {
    final revision = ++_revision;
    loading = true;
    failed = false;
    notifyListeners();
    try {
      final value = await repository.currentEntitlement();
      if (!_disposed && revision == _revision) _accept(value);
    } catch (_) {
      if (!_disposed && revision == _revision) _fail();
    }
  }

  void _accept(Entitlement value) {
    entitlement = value;
    loading = false;
    failed = false;
    _expiry?.cancel();
    final expiry = value.expiresAt;
    if (expiry != null && expiry.isAfter(now())) {
      _expiry = Timer(expiry.difference(now()), () {
        if (!_disposed) notifyListeners();
      });
    }
    notifyListeners();
  }

  void _fail() {
    loading = false;
    failed = true;
    _expiry?.cancel();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _expiry?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

class PremiumAccessScope extends InheritedNotifier<PremiumAccessController> {
  const PremiumAccessScope(
      {super.key,
      required PremiumAccessController controller,
      required super.child})
      : super(notifier: controller);
  static PremiumAccessController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PremiumAccessScope>()
      ?.notifier;
}

/// Installed by the production composition root. Standalone presentation tests
/// may omit the app scope; all application navigators are beneath it.
Widget? premiumBlock(BuildContext context) {
  final access = PremiumAccessScope.maybeOf(context);
  if (access == null || access.active) return null;
  if (access.loading || access.failed) {
    return AppScaffold(
        body: Column(children: [
      Align(
          alignment: Alignment.centerRight,
          child: IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close))),
      Expanded(
          child: SingleChildScrollView(
              child: Column(children: [
        if (access.loading)
          const CircularProgressIndicator(semanticsLabel: 'Checking access')
        else ...[
          const Text('Could not check your access. Your data is preserved.'),
          TextButton(onPressed: access.refresh, child: const Text('Retry'))
        ],
      ]))),
    ]));
  }
  return const SubscriptionScreen();
}
