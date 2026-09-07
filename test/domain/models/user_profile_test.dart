import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/experience_level.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';

void main() {
  UserProfile buildProfile({DateTime? examDate}) {
    return UserProfile(
      examId: 'danb-rhs',
      experienceLevel: ExperienceLevel.justStarting,
      examDatePrecision: examDate == null
          ? ExamDatePrecision.notScheduled
          : ExamDatePrecision.exact,
      examDate: examDate,
      dailyGoalQuestions: 10,
      notificationsEnabled: true,
      themePreference: ThemePreference.system,
      onboardingComplete: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  test('equal field values produce equal instances and hash codes', () {
    final a = buildProfile();
    final b = buildProfile();
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('differing fields are not equal', () {
    final a = buildProfile();
    final b = buildProfile().copyWith(dailyGoalQuestions: 20);
    expect(a, isNot(equals(b)));
  });

  test('copyWith overrides only the requested fields', () {
    final original = buildProfile();
    final updated = original.copyWith(onboardingComplete: true);

    expect(updated.onboardingComplete, isTrue);
    expect(updated.examId, original.examId);
    expect(updated.dailyGoalQuestions, original.dailyGoalQuestions);
  });

  test('copyWith can clear a scheduled exam date', () {
    final scheduled = buildProfile(examDate: DateTime.utc(2026, 6, 1));
    final cleared = scheduled.copyWith(
      examDatePrecision: ExamDatePrecision.notScheduled,
      clearExamDate: true,
    );

    expect(cleared.examDate, isNull);
    expect(cleared.examDatePrecision, ExamDatePrecision.notScheduled);
  });

  test('an exam date without a scheduled precision violates the invariant', () {
    expect(
      () => UserProfile(
        examId: 'danb-rhs',
        experienceLevel: ExperienceLevel.justStarting,
        examDatePrecision: ExamDatePrecision.notScheduled,
        examDate: DateTime.utc(2026, 6, 1),
        dailyGoalQuestions: 10,
        notificationsEnabled: true,
        themePreference: ThemePreference.system,
        onboardingComplete: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
      throwsArgumentError,
    );
  });

  test('a scheduled precision without an exam date violates the invariant', () {
    expect(
      () => UserProfile(
        examId: 'danb-rhs',
        experienceLevel: ExperienceLevel.justStarting,
        examDatePrecision: ExamDatePrecision.approximate,
        dailyGoalQuestions: 10,
        notificationsEnabled: true,
        themePreference: ThemePreference.system,
        onboardingComplete: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
      throwsArgumentError,
    );
  });

  group('fromOnboarding (PREP-663)', () {
    test(
        'a fresh install (no existing profile) gets the documented '
        'defaults for fields onboarding never collects', () {
      final profile = UserProfile.fromOnboarding(
        examId: 'danb-rhs',
        experienceLevel: ExperienceLevel.justStarting,
        examDateSelection: ExamDateSelection(
          precision: ExamDatePrecision.notScheduled,
        ),
        themePreference: ThemePreference.dark,
        now: DateTime.utc(2026, 3, 1),
      );

      expect(profile.dailyGoalQuestions, kDefaultDailyGoalQuestions);
      expect(profile.notificationsEnabled, isFalse);
      expect(profile.onboardingComplete, isTrue);
      expect(profile.createdAt, DateTime.utc(2026, 3, 1));
      expect(profile.updatedAt, DateTime.utc(2026, 3, 1));
      expect(profile.themePreference, ThemePreference.dark);
      expect(profile.experienceLevel, ExperienceLevel.justStarting);
      expect(profile.examDatePrecision, ExamDatePrecision.notScheduled);
      expect(profile.examDate, isNull);
    });

    test(
        'a local calendar date is reconstructed as the *same* UTC-flagged '
        'calendar date, never `.toUtc()`-converted — that would risk '
        'shifting the stored date to the day before/after the one chosen', () {
      final DateTime localDate = DateTime(2026, 6, 15);
      final profile = UserProfile.fromOnboarding(
        examId: 'danb-rhs',
        experienceLevel: ExperienceLevel.retakingExam,
        examDateSelection: ExamDateSelection(
          precision: ExamDatePrecision.exact,
          date: localDate,
        ),
        themePreference: ThemePreference.system,
        now: DateTime.utc(2026, 3, 1),
      );

      expect(profile.examDate, DateTime.utc(2026, 6, 15));
      expect(profile.examDate!.isUtc, isTrue);
      expect(profile.examDatePrecision, ExamDatePrecision.exact);
    });

    test(
        're-running onboarding for an exam that already has a saved '
        'profile (re-onboarding, or local storage reset without the '
        'database also being cleared) keeps the original createdAt and '
        'the fields onboarding does not collect, updating everything '
        'else', () {
      final existing = UserProfile(
        examId: 'danb-rhs',
        experienceLevel: ExperienceLevel.justStarting,
        examDatePrecision: ExamDatePrecision.notScheduled,
        dailyGoalQuestions: 25,
        notificationsEnabled: true,
        themePreference: ThemePreference.light,
        onboardingComplete: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      final updated = UserProfile.fromOnboarding(
        examId: 'danb-rhs',
        experienceLevel: ExperienceLevel.retakingExam,
        examDateSelection: ExamDateSelection(
          precision: ExamDatePrecision.approximate,
          date: DateTime(2026, 9, 1),
        ),
        themePreference: ThemePreference.dark,
        now: DateTime.utc(2026, 4, 1),
        existing: existing,
      );

      expect(updated.createdAt, DateTime.utc(2026, 1, 1),
          reason: 'the original creation time must never be reset by a '
              'later re-save');
      expect(updated.dailyGoalQuestions, 25,
          reason: 'onboarding does not collect a daily goal — a prior '
              'answer must survive a re-save, not reset to the default');
      expect(updated.notificationsEnabled, isTrue,
          reason: 'onboarding does not collect a notifications choice — '
              'a prior answer must survive a re-save');
      expect(updated.experienceLevel, ExperienceLevel.retakingExam);
      expect(updated.examDatePrecision, ExamDatePrecision.approximate);
      expect(updated.examDate, DateTime.utc(2026, 9, 1));
      expect(updated.themePreference, ThemePreference.dark);
      expect(updated.updatedAt, DateTime.utc(2026, 4, 1));
    });
  });
}
