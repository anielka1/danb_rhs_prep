import 'dart:async';
import 'package:flutter/widgets.dart';
import '../domain/models/entitlement.dart';
import 'subscription_service.dart';

/// Shared across the root and every tab navigator. Bootstrap's legacy
/// preference is never a source of premium access in the production UI.
class SubscriptionController extends ChangeNotifier {
  SubscriptionController(this.service) {
    _subscription = service.entitlementChanges().listen(_update);
  }

  final SubscriptionService service;
  late final StreamSubscription<Entitlement> _subscription;
  Entitlement _entitlement = Entitlement.free(lastVerifiedAt: DateTime.now().toUtc());
  bool _disposed = false;
  Future<Entitlement>? _refreshing;

  Entitlement get entitlement => _entitlement.isActiveAt(DateTime.now())
      ? _entitlement
      : Entitlement.free(lastVerifiedAt: _entitlement.lastVerifiedAt);

  void _update(Entitlement value) {
    if (_disposed) return;
    _entitlement = value;
    notifyListeners();
  }

  Future<Entitlement> refresh() {
    return _refreshing ??= _refresh();
  }

  Future<Entitlement> _refresh() async {
    try {
      _update(await service.currentEntitlement());
      return entitlement;
    } finally {
      _refreshing = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

class SubscriptionScope extends InheritedNotifier<SubscriptionController> {
  const SubscriptionScope({super.key, required SubscriptionController controller,
    required super.child}) : super(notifier: controller);

  static SubscriptionController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SubscriptionScope>()?.notifier;
}
