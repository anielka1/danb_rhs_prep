import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/services/analytics_service.dart';
import 'package:danb_rhs_prep/services/fakes/fake_analytics_service.dart';

void main() {
  group('NoOpAnalyticsService', () {
    test('never throws for any screenId', () {
      const NoOpAnalyticsService analytics = NoOpAnalyticsService();
      expect(() => analytics.trackScreenView('home'), returnsNormally);
      expect(() => analytics.trackScreenView(''), returnsNormally);
    });
  });

  group('FakeAnalyticsService', () {
    test('records every reported screenId in order', () {
      final FakeAnalyticsService analytics = FakeAnalyticsService();
      analytics.trackScreenView('home');
      analytics.trackScreenView('practice');
      expect(analytics.screenViews, ['home', 'practice']);
    });
  });
}
