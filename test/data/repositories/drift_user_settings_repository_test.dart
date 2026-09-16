import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_user_settings_repository.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/experience_level.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';

void main() {
  late AppDatabase db;
  late DriftUserSettingsRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftUserSettingsRepository(db);
  });

  tearDown(() => db.close());

  test(
      'new profiles persist absence of self-assessment without inventing a level',
      () async {
    final profile = UserProfile(
        examId: 'new-user',
        experienceLevel: null,
        examDatePrecision: ExamDatePrecision.notScheduled,
        dailyGoalQuestions: 10,
        notificationsEnabled: false,
        themePreference: ThemePreference.system,
        onboardingComplete: true,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026));
    await repository.saveProfile(profile);
    final restored = await repository.loadProfile('new-user');
    expect(restored, profile);
    expect(restored!.experienceLevel, isNull);
    expect(db.schemaVersion, 6);
  });

  test('loadProfile is null before onboarding has been saved', () async {
    expect(await repository.loadProfile('danb-rhs'), isNull);
  });

  test(
      'saveProfile is retrievable by exam id, with every field round-'
      'tripping exactly', () async {
    final profile = UserProfile(
      examId: 'danb-rhs',
      experienceLevel: ExperienceLevel.studyingAlready,
      examDatePrecision: ExamDatePrecision.exact,
      examDate: DateTime.utc(2026, 6, 1),
      dailyGoalQuestions: 15,
      notificationsEnabled: false,
      themePreference: ThemePreference.dark,
      onboardingComplete: true,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );

    await repository.saveProfile(profile);

    expect(await repository.loadProfile('danb-rhs'), profile);
  });

  test(
      'saveProfile upserts — a second save for the same exam replaces the '
      'first rather than duplicating it', () async {
    final original = UserProfile(
      examId: 'danb-rhs',
      experienceLevel: ExperienceLevel.justStarting,
      examDatePrecision: ExamDatePrecision.notScheduled,
      dailyGoalQuestions: 5,
      notificationsEnabled: true,
      themePreference: ThemePreference.system,
      onboardingComplete: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    await repository.saveProfile(original);

    final updated = original.copyWith(
      onboardingComplete: true,
      dailyGoalQuestions: 20,
      updatedAt: DateTime.utc(2026, 1, 5),
    );
    await repository.saveProfile(updated);

    expect(await repository.loadProfile('danb-rhs'), updated);
  });

  test(
      'a stored DateTime is read back as UTC regardless of what was '
      'passed in', () async {
    final localish = DateTime(2026, 3, 1, 9); // no explicit UTC marker
    final profile = UserProfile(
      examId: 'danb-rhs',
      experienceLevel: ExperienceLevel.justStarting,
      examDatePrecision: ExamDatePrecision.notScheduled,
      dailyGoalQuestions: 5,
      notificationsEnabled: true,
      themePreference: ThemePreference.system,
      onboardingComplete: false,
      createdAt: localish,
      updatedAt: localish,
    );

    await repository.saveProfile(profile);

    final UserProfile? loaded = await repository.loadProfile('danb-rhs');
    expect(loaded!.createdAt.isUtc, isTrue);
    expect(loaded.updatedAt.isUtc, isTrue);
  });

  test('profiles are scoped by exam id — a different exam id is not found',
      () async {
    await repository.saveProfile(UserProfile(
      examId: 'danb-rhs',
      experienceLevel: ExperienceLevel.justStarting,
      examDatePrecision: ExamDatePrecision.notScheduled,
      dailyGoalQuestions: 5,
      notificationsEnabled: true,
      themePreference: ThemePreference.system,
      onboardingComplete: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ));

    expect(await repository.loadProfile('other-exam'), isNull);
  });
}
