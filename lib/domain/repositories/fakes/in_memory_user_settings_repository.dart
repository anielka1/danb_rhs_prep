import '../../models/user_profile.dart';
import '../user_settings_repository.dart';

/// An in-memory [UserSettingsRepository] for unit tests and previews.
class InMemoryUserSettingsRepository implements UserSettingsRepository {
  final Map<String, UserProfile> _profiles = {};

  @override
  Future<UserProfile?> loadProfile(String examId) async {
    return _profiles[examId];
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _profiles[profile.examId] = profile;
  }
}
