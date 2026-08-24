import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';

void main() {
  group('construction invariants', () {
    test('unscheduled requires a null date', () {
      expect(
        () => ExamDateSelection(
          precision: ExamDatePrecision.notScheduled,
          date: DateTime(2026, 3, 1),
        ),
        throwsArgumentError,
      );
    });

    test('exact requires a non-null date', () {
      expect(
        () => ExamDateSelection(precision: ExamDatePrecision.exact),
        throwsArgumentError,
      );
    });

    test('approximate requires a non-null date', () {
      expect(
        () => ExamDateSelection(precision: ExamDatePrecision.approximate),
        throwsArgumentError,
      );
    });

    test('unscheduled with a null date is valid', () {
      expect(
        () => ExamDateSelection(precision: ExamDatePrecision.notScheduled),
        returnsNormally,
      );
    });

    test('a date carrying a time-of-day component is rejected', () {
      expect(
        () => ExamDateSelection(
          precision: ExamDatePrecision.exact,
          date: DateTime(2026, 3, 1, 13, 30),
        ),
        throwsArgumentError,
      );
    });

    test('a pure calendar date (no time component) is accepted', () {
      expect(
        () => ExamDateSelection(
          precision: ExamDatePrecision.exact,
          date: DateTime(2026, 3, 1),
        ),
        returnsNormally,
      );
    });
  });

  group('normalizeToLocalDate', () {
    test('strips time-of-day, keeping only year/month/day', () {
      final DateTime normalized =
          normalizeToLocalDate(DateTime(2026, 3, 1, 23, 59, 59, 999));
      expect(normalized, DateTime(2026, 3, 1));
    });
  });

  group('equality', () {
    test('two selections with the same precision and date are equal', () {
      final a = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 1));
      final b = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 1));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different date is not equal', () {
      final a = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 1));
      final b = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 2));
      expect(a, isNot(b));
    });

    test('a different precision is not equal, even with the same date', () {
      final a = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 1));
      final b = ExamDateSelection(
          precision: ExamDatePrecision.approximate, date: DateTime(2026, 3, 1));
      expect(a, isNot(b));
    });

    test('two unscheduled selections are equal', () {
      expect(ExamDateSelection(precision: ExamDatePrecision.notScheduled),
          ExamDateSelection(precision: ExamDatePrecision.notScheduled));
    });
  });

  group('copyWith', () {
    test('clearDate clears the date regardless of the date argument', () {
      final original = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 1));
      final cleared = original.copyWith(
          precision: ExamDatePrecision.notScheduled, clearDate: true);
      expect(cleared.date, isNull);
      expect(cleared.precision, ExamDatePrecision.notScheduled);
    });

    test('omitted fields are preserved', () {
      final original = ExamDateSelection(
          precision: ExamDatePrecision.approximate, date: DateTime(2026, 3, 1));
      final copy = original.copyWith();
      expect(copy, original);
    });
  });

  group('isExamDateSelectionValid', () {
    final DateTime today = DateTime(2026, 3, 15);

    test('exact selection accepts today', () {
      final selection =
          ExamDateSelection(precision: ExamDatePrecision.exact, date: today);
      expect(isExamDateSelectionValid(selection, today), isTrue);
    });

    test('exact selection accepts a future date', () {
      final selection = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 16));
      expect(isExamDateSelectionValid(selection, today), isTrue);
    });

    test('approximate selection accepts today', () {
      final selection = ExamDateSelection(
          precision: ExamDatePrecision.approximate, date: today);
      expect(isExamDateSelectionValid(selection, today), isTrue);
    });

    test('approximate selection accepts a future date', () {
      final selection = ExamDateSelection(
          precision: ExamDatePrecision.approximate,
          date: DateTime(2026, 3, 16));
      expect(isExamDateSelectionValid(selection, today), isTrue);
    });

    test('a past exact date is rejected', () {
      final selection = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 14));
      expect(isExamDateSelectionValid(selection, today), isFalse);
    });

    test('a past approximate date is rejected', () {
      final selection = ExamDateSelection(
          precision: ExamDatePrecision.approximate,
          date: DateTime(2026, 3, 14));
      expect(isExamDateSelectionValid(selection, today), isFalse);
    });

    test('unscheduled is valid regardless of today', () {
      final selection =
          ExamDateSelection(precision: ExamDatePrecision.notScheduled);
      expect(isExamDateSelectionValid(selection, today), isTrue);
    });

    test('a year boundary: yesterday being Dec 31 of the prior year is invalid',
        () {
      final DateTime newYearsDay = DateTime(2026, 1, 1);
      final DateTime lastDayOfPriorYear = DateTime(2025, 12, 31);
      final selection = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: lastDayOfPriorYear);
      expect(isExamDateSelectionValid(selection, newYearsDay), isFalse);
    });

    test('a year boundary: tomorrow being Jan 1 of the next year is valid', () {
      final DateTime newYearsEve = DateTime(2025, 12, 31);
      final DateTime newYearsDay = DateTime(2026, 1, 1);
      final selection = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: newYearsDay);
      expect(isExamDateSelectionValid(selection, newYearsEve), isTrue);
    });

    test(
        'a month boundary: the first of next month is valid from the last '
        'day of this month', () {
      final DateTime lastDayOfFeb = DateTime(2026, 2, 28);
      final DateTime firstOfMarch = DateTime(2026, 3, 1);
      final selection = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: firstOfMarch);
      expect(isExamDateSelectionValid(selection, lastDayOfFeb), isTrue);
    });
  });
}
