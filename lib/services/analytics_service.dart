/// Minimal, SDK-free analytics abstraction. Implementations must never
/// throw — a broken analytics backend must never be able to break
/// navigation — and must only ever receive stable, non-user-facing
/// identifiers (e.g. `'settings'`, `'mock_exam'`), never translated UI
/// labels, question/answer text, or other personal data.
abstract interface class AnalyticsService {
  /// Records that a screen became visible, identified by a stable
  /// [screenId] (a route name for pushed routes, or a short snake_case id
  /// for something that isn't a route — e.g. a tab that became active
  /// inside an `IndexedStack`, which the `Navigator` never sees).
  void trackScreenView(String screenId);
}

/// Default implementation: does nothing. Used whenever no analytics
/// backend has been wired up (which, for this phase, is always — no
/// analytics SDK has been added yet).
class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  void trackScreenView(String screenId) {}
}
