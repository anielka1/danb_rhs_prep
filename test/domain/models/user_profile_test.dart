import 'package:flutter_test/flutter_test.dart';

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
}
