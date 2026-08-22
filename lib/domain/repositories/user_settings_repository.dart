import '../models/user_profile.dart';

/// Persists the user's onboarding answers and study preferences for one
/// exam.
abstract interface class UserSettingsRepository {
  /// Null when the user has not started onboarding for this exam yet.
  Future<UserProfile?> loadProfile(String examId);

  Future<void> saveProfile(UserProfile profile);
}
