import '../../domain/models/study_plan_preferences.dart';
import 'package:drift/drift.dart';

import '../../domain/models/exam_date_precision.dart';
import '../../domain/models/experience_level.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/user_settings_repository.dart';
import '../local/app_database.dart';

/// The real, Drift/SQLite-backed [UserSettingsRepository] (PREP-661) — the
/// first production implementation; no adapter existed before this.
///
/// Every [DateTime] is normalized to UTC on the way in and out (see
/// [AppDatabase]'s own doc comment on why this discipline lives here
/// rather than in the column type), and every enum is stored by its
/// stable `.name`, never a raw index that would silently shift meaning if
/// the enum's declaration order ever changes.
class DriftUserSettingsRepository implements UserSettingsRepository {
  DriftUserSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<UserProfile?> loadProfile(String examId) async {
    final UserProfileRow? row = await (_db.select(_db.userProfiles)
          ..where((t) => t.examId.equals(examId)))
        .getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _db.into(_db.userProfiles).insertOnConflictUpdate(
          UserProfilesCompanion.insert(
            studyPlanPreferencesJson:
                Value(profile.studyPlanPreferences?.encode()),
            examId: profile.examId,
            experienceLevel: profile.experienceLevel?.name ?? 'notCollected',
            examDatePrecision: profile.examDatePrecision.name,
            examDate: Value(profile.examDate?.toUtc()),
            dailyGoalQuestions: profile.dailyGoalQuestions,
            notificationsEnabled: profile.notificationsEnabled,
            themePreference: profile.themePreference.name,
            onboardingComplete: profile.onboardingComplete,
            createdAt: profile.createdAt.toUtc(),
            updatedAt: profile.updatedAt.toUtc(),
          ),
        );
  }

  UserProfile _toDomain(UserProfileRow row) {
    return UserProfile(
      studyPlanPreferences:
          StudyPlanPreferences.decode(row.studyPlanPreferencesJson),
      examId: row.examId,
      experienceLevel: switch (row.experienceLevel) {
        'justStarting' => ExperienceLevel.justStarting,
        'studyingAlready' => ExperienceLevel.studyingAlready,
        'retakingExam' => ExperienceLevel.retakingExam,
        _ => null,
      },
      examDatePrecision: ExamDatePrecision.values.firstWhere(
        (value) => value.name == row.examDatePrecision,
        orElse: () => ExamDatePrecision.notScheduled,
      ),
      examDate: row.examDate?.toUtc(),
      dailyGoalQuestions: row.dailyGoalQuestions,
      notificationsEnabled: row.notificationsEnabled,
      themePreference: ThemePreference.values.firstWhere(
        (value) => value.name == row.themePreference,
        orElse: () => ThemePreference.system,
      ),
      onboardingComplete: row.onboardingComplete,
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
    );
  }
}
