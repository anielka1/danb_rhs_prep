import 'study_plan_preferences.dart';
import 'exam_date_precision.dart';
import 'exam_date_selection.dart';
import 'experience_level.dart';

/// Manual theme override; `system` follows the OS setting.
enum ThemePreference { system, light, dark }

/// The study pace a profile gets when nothing has explicitly set one yet
/// — no "set your daily goal" onboarding step or settings control exists
/// yet (tracked as separate, parallel work; see
/// [UserProfile.fromOnboarding]'s own doc comment), so this is a
/// deliberate, documented default, not a fabricated or random value.
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

  /// Builds the profile to persist the moment onboarding's exam-date and
  /// experience-level answers are both known (`ExperienceLevelScreen`'s
  /// completion step, the only caller today).
  ///
  /// [dailyGoalQuestions] and [notificationsEnabled] have no onboarding
  /// step or settings control yet — tracked as separate, parallel work,
  /// not blocked on here (a clickable "set your daily goal"/notifications
  /// UI can land independently of this persistence layer). [existing],
  /// when this exam already has a saved profile (re-running onboarding,
  /// or restoring after local storage was reset without the database
  /// also being cleared), keeps those two fields — and [createdAt] — from
  /// [existing] rather than resetting them to defaults or a fresh
  /// timestamp: onboarding must never silently overwrite answers it
  /// doesn't itself collect.
  ///
  /// [examDateSelection] reuses [ExamDateSelection]'s own identical
  /// null-iff-not-scheduled invariant directly. Its [ExamDateSelection.date]
  /// is a pure *local* calendar date (see that class's doc comment) and is
  /// deliberately reconstructed here as a UTC-flagged [DateTime] for the
  /// *same* calendar date — `DateTime.utc(date.year, date.month, date.day)`
  /// — never `.toUtc()` on the local value, which would perform a real
  /// timezone conversion and could silently shift the stored date to the
  /// day before or after the one the user actually chose.
  factory UserProfile.fromOnboarding({
    required String examId,
    required ExperienceLevel experienceLevel,
    required ExamDateSelection examDateSelection,
    required ThemePreference themePreference,
    required DateTime now,
    UserProfile? existing,
  }) {
    final DateTime? localDate = examDateSelection.date;
    return UserProfile(
      examId: examId,
      experienceLevel: experienceLevel,
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
  final ExperienceLevel experienceLevel;
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
