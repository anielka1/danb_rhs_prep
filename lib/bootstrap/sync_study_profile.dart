import '../domain/models/user_profile.dart';
import '../domain/repositories/user_settings_repository.dart';
import 'bootstrap_session_controller.dart';

/// Preferences are saved first by the editor. Retry can safely repeat this
/// profile projection if its separate storage write fails.
Future<void> syncStudyProfile(
  BootstrapSessionController session,
  UserSettingsRepository? repository,
) async {
  if (repository == null) return;
  final snapshot = session.snapshot;
  final date = snapshot.examDateSelection;
  final experience = snapshot.experienceLevel;
  if (date == null) return;
  final existing = await repository.loadProfile(snapshot.selectedExamId);
  final profile = UserProfile.fromOnboarding(
    examId: snapshot.selectedExamId,
    experienceLevel: experience,
    examDateSelection: date,
    themePreference: existing?.themePreference ?? snapshot.themePreference,
    now: DateTime.now(),
    existing: existing,
  );
  await repository.saveProfile(profile);
  session.update(session.snapshot.copyWith(profile: profile));
}
