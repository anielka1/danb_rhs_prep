/// A human-facing readiness label, shared by the exam configuration
/// (`ExamConfig.readiness.thresholds`, which maps score ranges to a band)
/// and by [ReadinessSnapshot] (which records the band produced for a given
/// calculation). Kept as a standalone, dependency-free file so neither side
/// has to depend on the other's file just to share this enum.
enum ReadinessBand {
  starting,
  developing,
  gettingClose,
  examReady,
  stronglyPrepared,
}
