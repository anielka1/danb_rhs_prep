import 'exam_date_precision.dart';
import 'experience_level.dart';

/// Manual theme override; `system` follows the OS setting.
enum ThemePreference { system, light, dark }

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
    required this.dailyGoalQuestions,
    required this.notificationsEnabled,
    required this.themePreference,
    required this.onboardingComplete,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if ((examDate != null) !=
        (examDatePrecision != ExamDatePrecision.notScheduled)) {
      throw ArgumentError(
        'examDate must be set if and only if an exam date has been scheduled.',
      );
    }
  }

  final String examId;
  final ExperienceLevel experienceLevel;
  final ExamDatePrecision examDatePrecision;
  final DateTime? examDate;
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
        dailyGoalQuestions,
        notificationsEnabled,
        themePreference,
        onboardingComplete,
        createdAt,
        updatedAt,
      );
}
