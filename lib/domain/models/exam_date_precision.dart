/// How firmly the user has scheduled their exam.
///
/// A standalone, dependency-free leaf file (matching `readiness_band.dart`'s
/// existing pattern) so that both `UserProfile` and `ExamDateSelection` can
/// depend on this enum without either depending on the other, or on the
/// `UserProfile` aggregate, merely to share it.
enum ExamDatePrecision { exact, approximate, notScheduled }
