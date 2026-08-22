import '../analytics_service.dart';

/// In-memory [AnalyticsService] for tests: records every reported screen
/// id, in order, so tests can assert on exactly what was (and wasn't)
/// reported.
class FakeAnalyticsService implements AnalyticsService {
  final List<String> screenViews = [];

  @override
  void trackScreenView(String screenId) {
    screenViews.add(screenId);
  }
}
