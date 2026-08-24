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

  /// Records a discrete, named user action — e.g. `'onboarding_started'`
  /// — identified by a stable, snake_case [name]. [properties] must only
  /// ever hold stable, non-user-facing identifiers (e.g. an exam ID
  /// sourced from `ExamConfig`), never translated UI copy,
  /// question/answer text, or personal data (email, profile answers,
  /// etc.). Callers must treat a throwing implementation the same way
  /// [trackScreenView] is already treated elsewhere: analytics failure
  /// must never be allowed to block the action it's reporting on.
  void trackEvent(String name, {Map<String, Object?> properties});
}

/// Default implementation: does nothing. Used whenever no analytics
/// backend has been wired up (which, for this phase, is always — no
/// analytics SDK has been added yet).
class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  void trackScreenView(String screenId) {}

  @override
  void trackEvent(String name, {Map<String, Object?> properties = const {}}) {}
}
