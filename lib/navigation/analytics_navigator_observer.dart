import 'package:flutter/widgets.dart';

import '../services/analytics_service.dart';

/// Reports a screen view for every named route the [Navigator] pushes,
/// replaces, or reveals by popping back to it. This only ever sees actual
/// `Navigator` transitions — it deliberately does not know about tab
/// changes inside an `IndexedStack`, since those aren't route changes;
/// tab views are reported explicitly by the main shell instead.
class AnalyticsNavigatorObserver extends NavigatorObserver {
  AnalyticsNavigatorObserver(this._analytics);

  final AnalyticsService _analytics;

  void _report(Route<dynamic>? route) {
    final String? name = route?.settings.name;
    if (name == null || name.isEmpty) return;
    // Analytics must never be able to break navigation.
    try {
      _analytics.trackScreenView(name);
    } catch (_) {
      // Intentionally swallowed.
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _report(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _report(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _report(previousRoute);
  }
}
