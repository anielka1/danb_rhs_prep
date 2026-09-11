import 'study_plan_preferences.dart';
import 'exam_date_precision.dart';
import 'exam_date_selection.dart';
import 'experience_level.dart';

/// Manual theme override; `system` follows the OS setting.
enum ThemePreference { system, light, dark }

/// Compatibility value for the retained legacy column; not a study target.
/// Neither Home nor practice uses it to allocate questions.
const int kDefaultDailyGoalQuestions = 10;

/// Local onboarding, study, and preference state for a single exam.
///
/// Invariant, enforced by the constructor (throws [ArgumentError] if
/// violated): [examDate] is non-null exactly when [examDatePrecision] is
/// [ExamDatePrecision.exact] or [ExamDatePrecision.approximate]; it is null
/// when the user has not scheduled an exam yet.
class UserProfile {
  UserProfile({
    required this.examId,
    required this.experienceLevel,
    required this.examDatePrecision,
    this.examDate,
    this.studyPlanPreferences,
    required this.dailyGoalQuestions,
    required this.notificationsEnabled,
    required this.themePreference,
    required this.onboardingComplete,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if ((examDate != null) != examDatePrecision.requiresDate) {
      throw ArgumentError(
        'examDate must be set if and only if an exam date has been scheduled.',
      );
    }
  }

  /// Persists the real exam timeframe. New users have no self-assessment;
  /// existing legacy experience and scheduling preferences remain untouched.
  /// Local calendar components are stored as UTC components without shifting dates.
  factory UserProfile.fromOnboarding({
    required String examId,
    ExperienceLevel? experienceLevel,
    required ExamDateSelection examDateSelection,
    required ThemePreference themePreference,
    required DateTime now,
    UserProfile? existing,
  }) {
    final DateTime? localDate = examDateSelection.date;
    return UserProfile(
      examId: examId,
      experienceLevel: experienceLevel ?? existing?.experienceLevel,
      examDatePrecision: examDateSelection.precision,
      examDate: localDate == null
          ? null
          : DateTime.utc(localDate.year, localDate.month, localDate.day),
      studyPlanPreferences: existing?.studyPlanPreferences,
      dailyGoalQuestions:
          existing?.dailyGoalQuestions ?? kDefaultDailyGoalQuestions,
      notificationsEnabled: existing?.notificationsEnabled ?? false,
      themePreference: themePreference,
      onboardingComplete: true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  final String examId;
  final ExperienceLevel? experienceLevel;
  final ExamDatePrecision examDatePrecision;
  final DateTime? examDate;
  final StudyPlanPreferences? studyPlanPreferences;
  final int dailyGoalQuestions;
  final bool notificationsEnabled;
  final ThemePreference themePreference;
  final bool onboardingComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? examId,
    ExperienceLevel? experienceLevel,
    ExamDatePrecision? examDatePrecision,
    DateTime? examDate,
    bool clearExamDate = false,
    StudyPlanPreferences? studyPlanPreferences,
    int? dailyGoalQuestions,
    bool? notificationsEnabled,
    ThemePreference? themePreference,
    bool? onboardingComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      examId: examId ?? this.examId,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      examDatePrecision: examDatePrecision ?? this.examDatePrecision,
      examDate: clearExamDate ? null : (examDate ?? this.examDate),
      studyPlanPreferences: studyPlanPreferences ?? this.studyPlanPreferences,
      dailyGoalQuestions: dailyGoalQuestions ?? this.dailyGoalQuestions,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themePreference: themePreference ?? this.themePreference,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.examId == examId &&
        other.experienceLevel == experienceLevel &&
        other.examDatePrecision == examDatePrecision &&
        other.examDate == examDate &&
        other.studyPlanPreferences == studyPlanPreferences &&
        other.dailyGoalQuestions == dailyGoalQuestions &&
        other.notificationsEnabled == notificationsEnabled &&
        other.themePreference == themePreference &&
        other.onboardingComplete == onboardingComplete &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        examId,
        experienceLevel,
        examDatePrecision,
        examDate,
        studyPlanPreferences,
        dailyGoalQuestions,
        notificationsEnabled,
        themePreference,
        onboardingComplete,
        createdAt,
        updatedAt,
      );
}
