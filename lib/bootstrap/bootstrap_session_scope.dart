import 'package:flutter/widgets.dart';

import 'app_bootstrap_service.dart';

/// Makes the successful bootstrap snapshot available to descendants
/// (`MainShell` and its screens, the onboarding entry screen) without
/// each of them re-loading content or querying local storage/plugins
/// directly. An `InheritedWidget`, not Riverpod or another
/// state-management package — the snapshot is immutable for the
/// lifetime of the app session (a new one is only ever produced by a
/// fresh bootstrap, i.e. app relaunch), so there is no controller or
/// lifecycle complexity here for a heavier tool to remove.
///
/// No prototype screen reads from this scope yet — wiring them to real
/// bootstrap data (content, entitlement, profile) is deliberately left
/// to later phases; this only makes the data reachable.
class BootstrapSessionScope extends InheritedWidget {
  const BootstrapSessionScope({
    super.key,
    required this.snapshot,
    required super.child,
  });

  final BootstrapReady snapshot;

  static BootstrapReady? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BootstrapSessionScope>()
        ?.snapshot;
  }

  static BootstrapReady of(BuildContext context) {
    final BootstrapReady? snapshot = maybeOf(context);
    assert(snapshot != null, 'No BootstrapSessionScope found in context.');
    return snapshot!;
  }

  @override
  bool updateShouldNotify(BootstrapSessionScope oldWidget) =>
      !identical(snapshot, oldWidget.snapshot);
}
