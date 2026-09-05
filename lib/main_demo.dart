import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'bootstrap/app_bootstrap_service.dart';
import 'debug/debug_demo_environment.dart';
import 'domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'main.dart';

/// Offline demo: `flutter run -t lib/main_demo.dart`.
/// Release/profile fail before constructing the app or any fake repositories.
/// All state is in memory and resets on restart; production storage is untouched.
/// Profile, content and readiness use the same synthetic exam namespace.
/// Practice/mock history is available through the environment's injectable
/// ProgressRepository; study-session UI is implemented in separate tasks.
void main() {
  runApp(createDebugDemoApp());
}

/// Shared composition root for the entrypoint and widget tests.
DanbRhsPrepApp createDebugDemoApp() {
  if (!kDebugMode) {
    throw UnsupportedError('The demo entrypoint requires debug mode.');
  }
  final localStore = InMemoryBootstrapLocalStore(
    onboardingComplete: true,
    readinessSnapshot: DebugDemoEnvironment.demoReadinessSnapshot,
    experienceLevel: DebugDemoEnvironment.demoProfile.experienceLevel,
  );
  final bootstrapService = AppBootstrapService(
    contentRepository: DebugDemoEnvironment.buildContentRepository(),
    defaultExamId: DebugDemoEnvironment.demoExamId,
    now: () => DateTime.utc(2026, 1, 1, 12),
    localStore: localStore,
    userSettingsRepository: DebugDemoEnvironment.buildUserSettingsRepository(),
  );

  return DanbRhsPrepApp(
    bootstrapService: bootstrapService,
    localStore: localStore,
  );
}
