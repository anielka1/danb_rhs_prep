import 'exam_date_precision.dart';

/// The onboarding exam-date screen's selection: how firmly the user has
/// scheduled their exam, plus — for a scheduled exam — a normalized,
/// date-only local calendar date. Reuses [ExamDatePrecision] (the same
/// concept [UserProfile] uses for its own exam date) rather than
/// declaring a second enum for it.
///
/// [date] is a pure calendar date: always constructed as
/// `DateTime(year, month, day)`, never carrying a time-of-day or UTC
/// timestamp. Two invariants are enforced by the constructor (throwing
/// [ArgumentError], not `assert`, so they hold in release builds and for
/// data restored from storage, not just during development):
///
/// * [date] is non-null exactly when [precision] is
///   [ExamDatePrecision.exact] or [ExamDatePrecision.approximate] — null
///   when [precision] is [ExamDatePrecision.notScheduled].
/// * When non-null, [date] carries no time-of-day component.
///
/// Deliberately does **not** validate that [date] isn't in the past —
/// that depends on "today," which changes over time (a value valid when
/// saved can become invalid days later, entirely without user action),
/// so it cannot be a permanent constructor invariant. Use
/// [isExamDateSelectionValid] with a freshly-read "today" wherever that
/// time-dependent check is actually needed (screen validation, restoring
/// a possibly-stale saved value, etc).
class ExamDateSelection {
  ExamDateSelection({required this.precision, this.date}) {
    final bool requiresDate = precision.requiresDate;
    if (requiresDate != (date != null)) {
      throw ArgumentError(
        'date must be non-null exactly when precision is exact or '
        'approximate (was $precision with date $date).',
      );
    }
    final DateTime? d = date;
    if (d != null && normalizeToLocalDate(d) != d) {
      throw ArgumentError(
        'date must be a pure calendar date (DateTime(year, month, day)) '
        'with no time-of-day component, was $d.',
      );
    }
  }

  final ExamDatePrecision precision;
  final DateTime? date;

  ExamDateSelection copyWith({
    ExamDatePrecision? precision,
    DateTime? date,
    bool clearDate = false,
  }) {
    return ExamDateSelection(
      precision: precision ?? this.precision,
      date: clearDate ? null : (date ?? this.date),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExamDateSelection &&
        other.precision == precision &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(precision, date);

  @override
  String toString() => 'ExamDateSelection(precision: $precision, date: $date)';
}

/// Strips any time-of-day component, returning a pure local calendar
/// date. The one place this normalization logic lives — callers (the
/// exam-date screen, the local store) use this instead of constructing
/// `DateTime(year, month, day)` inline themselves.
DateTime normalizeToLocalDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

/// Whether [selection] is currently valid to submit, given [today] (a
/// caller-supplied, already-normalized "current local calendar date" —
/// from an injected clock, never a direct `DateTime.now()` call here):
///
/// * [ExamDatePrecision.notScheduled] requires a null date.
/// * [ExamDatePrecision.exact]/[ExamDatePrecision.approximate] require a
///   non-null date that is not before [today] — today itself is valid,
///   yesterday is not.
///
/// This exists independently of any date picker: a value restored from
/// local storage (or otherwise never passed through picker UI
/// constraints) must be checked the same way, since time passing since
/// it was saved can make a once-valid date invalid.
bool isExamDateSelectionValid(ExamDateSelection selection, DateTime today) {
  switch (selection.precision) {
    case ExamDatePrecision.withinMonth:
    case ExamDatePrecision.oneToThreeMonths:
    case ExamDatePrecision.later:
    case ExamDatePrecision.notScheduled:
      return selection.date == null;
    case ExamDatePrecision.exact:
    case ExamDatePrecision.approximate:
      final DateTime? date = selection.date;
      if (date == null) return false;
      return !date.isBefore(today);
  }
}
