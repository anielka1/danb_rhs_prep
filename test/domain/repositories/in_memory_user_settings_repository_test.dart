import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_user_settings_repository.dart';

void main() {
  test('loadProfile is null before onboarding has been saved', () async {
    final repository = InMemoryUserSettingsRepository();
    expect(await repository.loadProfile('danb-rhs'), isNull);
  });

  test('saveProfile is retrievable by exam id', () async {
    final repository = InMemoryUserSettingsRepository();
    final profile = UserProfile(
      examId: 'danb-rhs',
      experienceLevel: ExperienceLevel.studyingAlready,
      examDatePrecision: ExamDatePrecision.notScheduled,
      dailyGoalQuestions: 15,
      notificationsEnabled: false,
      themePreference: ThemePreference.dark,
      onboardingComplete: true,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    await repository.saveProfile(profile);

    expect(await repository.loadProfile('danb-rhs'), profile);
  });
}
