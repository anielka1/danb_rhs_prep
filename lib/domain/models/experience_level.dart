/// Self-reported study experience captured during onboarding.
///
/// A standalone, dependency-free leaf file (matching
/// `exam_date_precision.dart`'s established pattern) so that both
/// `UserProfile` and the onboarding/bootstrap layer can depend on this
/// enum without either depending on the `UserProfile` aggregate merely
/// to share it.
enum ExperienceLevel { justStarting, studyingAlready, retakingExam }
