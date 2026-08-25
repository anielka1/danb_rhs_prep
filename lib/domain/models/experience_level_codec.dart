import 'experience_level.dart';

/// The one place [ExperienceLevel] is converted to/from its persisted
/// string form. Deliberately explicit, not `level.name`/`.byName(...)`/
/// `.index`: those all tie the storage format to the enum's Dart
/// declaration — a later rename of the enum symbol (which doesn't change
/// meaning) would silently change what gets read from or written to
/// existing installs, and an index additionally breaks if a value is
/// ever inserted or reordered. This mapping is the single source of
/// truth for the stored values (matching what `.name` already produced,
/// so existing persisted data keeps working) — nothing else in the
/// codebase may re-derive these strings.
String experienceLevelToStorageValue(ExperienceLevel level) {
  return switch (level) {
    ExperienceLevel.justStarting => 'justStarting',
    ExperienceLevel.studyingAlready => 'studyingAlready',
    ExperienceLevel.retakingExam => 'retakingExam',
  };
}

/// Returns the [ExperienceLevel] for [value], or `null` if it isn't one
/// of the recognized stored strings — an unrecognized value (corrupt
/// data, or a value written by a future app version) is discarded by
/// the caller, never guessed at.
ExperienceLevel? experienceLevelFromStorageValue(String value) {
  return switch (value) {
    'justStarting' => ExperienceLevel.justStarting,
    'studyingAlready' => ExperienceLevel.studyingAlready,
    'retakingExam' => ExperienceLevel.retakingExam,
    _ => null,
  };
}
