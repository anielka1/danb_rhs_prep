import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/navigation/analytics_navigator_observer.dart';
import 'package:danb_rhs_prep/services/analytics_service.dart';
import 'package:danb_rhs_prep/services/fakes/fake_analytics_service.dart';

class _ThrowingAnalyticsService implements AnalyticsService {
  @override
  void trackScreenView(String screenId) {
    throw StateError('backend unavailable');
  }
}

void main() {
  group('AnalyticsNavigatorObserver', () {
    testWidgets('reports a screen view for each named route pushed',
        (tester) async {
      final FakeAnalyticsService analytics = FakeAnalyticsService();
      await tester.pumpWidget(MaterialApp(
        navigatorObservers: [AnalyticsNavigatorObserver(analytics)],
        initialRoute: '/first',
        routes: {
          '/first': (_) => const Scaffold(body: Text('First')),
          '/second': (_) => const Scaffold(body: Text('Second')),
        },
      ));

      expect(analytics.screenViews, ['/first']);

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushNamed('/second');
      await tester.pumpAndSettle();

      expect(analytics.screenViews, ['/first', '/second']);
    });

    testWidgets('reports the revealed route name when popping back',
        (tester) async {
      final FakeAnalyticsService analytics = FakeAnalyticsService();
      await tester.pumpWidget(MaterialApp(
        navigatorObservers: [AnalyticsNavigatorObserver(analytics)],
        initialRoute: '/first',
        routes: {
          '/first': (_) => const Scaffold(body: Text('First')),
          '/second': (_) => const Scaffold(body: Text('Second')),
        },
      ));
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushNamed('/second');
      await tester.pumpAndSettle();
      analytics.screenViews.clear();

      navigator.pop();
      await tester.pumpAndSettle();

      expect(analytics.screenViews, ['/first']);
    });

    testWidgets('does not report routes with no name', (tester) async {
      final FakeAnalyticsService analytics = FakeAnalyticsService();
      await tester.pumpWidget(MaterialApp(
        navigatorObservers: [AnalyticsNavigatorObserver(analytics)],
        home: const Scaffold(body: Text('Home')),
      ));
      analytics.screenViews.clear();

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Unnamed')),
      ));
      await tester.pumpAndSettle();

      expect(analytics.screenViews, isEmpty);
    });

    testWidgets('an analytics failure never breaks navigation', (tester) async {
      await tester.pumpWidget(MaterialApp(
        navigatorObservers: [
          AnalyticsNavigatorObserver(_ThrowingAnalyticsService())
        ],
        initialRoute: '/first',
        routes: {
          '/first': (_) => const Scaffold(body: Text('First')),
          '/second': (_) => const Scaffold(body: Text('Second')),
        },
      ));

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushNamed('/second');
      await tester.pumpAndSettle();

      expect(find.text('Second'), findsOneWidget);
    });
  });
}
