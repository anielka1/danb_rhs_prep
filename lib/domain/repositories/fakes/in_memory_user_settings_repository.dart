import '../../models/user_profile.dart';
import '../user_settings_repository.dart';

/// An in-memory [UserSettingsRepository] for unit tests and previews.
class InMemoryUserSettingsRepository implements UserSettingsRepository {
  /// [seedProfile], if given, is available immediately via [loadProfile] —
  /// synchronously pre-populated rather than requiring a caller to
  /// `await saveProfile(...)` first, which matters for a caller (e.g.
  /// `DebugDemoEnvironment`) that needs a fully-seeded repository back
  /// from a synchronous factory.
  InMemoryUserSettingsRepository({UserProfile? seedProfile})
      : _profiles =
            seedProfile == null ? {} : {seedProfile.examId: seedProfile};

  final Map<String, UserProfile> _profiles;

  @override
  Future<UserProfile?> loadProfile(String examId) async {
    return _profiles[examId];
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _profiles[profile.examId] = profile;
  }
}
