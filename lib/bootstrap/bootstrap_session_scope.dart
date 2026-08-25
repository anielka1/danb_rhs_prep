import 'package:flutter/widgets.dart';

import 'bootstrap_session_controller.dart';
import 'app_bootstrap_service.dart';

/// Makes the shared [BootstrapSessionController] for the current app
/// session available to descendants (`MainShell` and its screens, every
/// onboarding screen) without each of them re-loading content or
/// querying local storage/plugins directly. An `InheritedWidget`, not
/// Riverpod or another state-management package.
///
/// Every route in the chain — Welcome, Exam Date, Experience Level, and
/// Main — wraps its child with the *same* [controller] instance it was
/// itself given; none of them ever constructs a new one. That single
/// shared instance is what lets an onboarding answer saved on one screen
/// be visible to a screen created fresh later in the same session (e.g.
/// navigating back to Welcome and starting over reaches a brand new Exam
/// Date screen that still prefills the previously-saved date) — a
/// concern a forward-only chain of copied, per-route snapshots cannot
/// address, since routes already underneath a given point in the stack
/// would keep whatever snapshot they were built with.
class BootstrapSessionScope extends InheritedWidget {
  const BootstrapSessionScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final BootstrapSessionController controller;

  static BootstrapSessionController? maybeControllerOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BootstrapSessionScope>()
        ?.controller;
  }

  static BootstrapSessionController controllerOf(BuildContext context) {
    final BootstrapSessionController? controller = maybeControllerOf(context);
    assert(controller != null, 'No BootstrapSessionScope found in context.');
    return controller!;
  }

  /// Convenience for the common case of just reading the current
  /// snapshot — equivalent to `controllerOf(context).snapshot`.
  static BootstrapReady snapshotOf(BuildContext context) {
    return controllerOf(context).snapshot;
  }

  @override
  bool updateShouldNotify(BootstrapSessionScope oldWidget) =>
      !identical(controller, oldWidget.controller);
}
