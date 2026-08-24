import '../analytics_service.dart';

/// A single recorded [FakeAnalyticsService.trackEvent] call.
class RecordedEvent {
  const RecordedEvent(this.name, this.properties);

  final String name;
  final Map<String, Object?> properties;
}

/// In-memory [AnalyticsService] for tests: records every reported screen
/// id and event, in order, so tests can assert on exactly what was (and
/// wasn't) reported.
class FakeAnalyticsService implements AnalyticsService {
  final List<String> screenViews = [];
  final List<RecordedEvent> events = [];

  @override
  void trackScreenView(String screenId) {
    screenViews.add(screenId);
  }

  @override
  void trackEvent(String name, {Map<String, Object?> properties = const {}}) {
    events.add(RecordedEvent(name, properties));
  }
}
