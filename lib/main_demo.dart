import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'bootstrap/app_bootstrap_service.dart';
import 'debug/debug_demo_environment.dart';
import 'domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'main.dart';
import 'widgets/app_bottom_navigation.dart';
import 'domain/repositories/fakes/in_memory_progress_repository.dart';

/// Offline demo: `flutter run -t lib/main_demo.dart`.
/// Release/profile fail before constructing the app or any fake repositories.
/// All state is in memory and resets on restart; production storage is untouched.
/// Profile, content and readiness use the same synthetic exam namespace.
/// Practice/mock history is available through the environment's injectable
/// ProgressRepository (PREP-648 wires it into HomeScreen's "Continue"
/// card — see [DebugDemoEnvironment.demoInProgressPracticeSession]);
/// study-session UI beyond that card is implemented in separate tasks.
///
/// This entrypoint retains the full onboarding walkthrough.
/// Use main_demo_practice.dart to open fresh demo Practice directly.
void main() {
  runApp(createDebugDemoApp());
}

/// Shared composition root for the entrypoint and widget tests.
DanbRhsPrepApp createDebugDemoApp({bool startInPractice = false}) {
  if (!kDebugMode) {
    throw UnsupportedError('The demo entrypoint requires debug mode.');
  }
  final localStore = startInPractice
      ? InMemoryBootstrapLocalStore(onboardingComplete: true)
      : InMemoryBootstrapLocalStore(
          onboardingComplete: false,
          readinessSnapshot: DebugDemoEnvironment.demoReadinessSnapshot,
        );
  final userSettingsRepository =
      DebugDemoEnvironment.buildUserSettingsRepository();
  final bootstrapService = AppBootstrapService(
    contentRepository: DebugDemoEnvironment.buildContentRepository(),
    defaultExamId: DebugDemoEnvironment.demoExamId,
    now: () => DateTime.utc(2026, 1, 1, 12),
    localStore: localStore,
    userSettingsRepository: userSettingsRepository,
  );

  return DanbRhsPrepApp(
    initialTab: startInPractice ? AppTab.practice : AppTab.home,
    bootstrapService: bootstrapService,
    localStore: localStore,
    userSettingsRepository: userSettingsRepository,
    // Real device clock, not the fixed bootstrap `now` above — matches
    // HomeScreen's own "Today" header, which is deliberately real too
    // (see docs/PROTOTYPE_CONTENT_AUDIT.md's HomeScreen row), so the
    // seeded in-progress session's elapsed time always looks like a
    // normal, just-started practice session, however long after
    // 2026-01-01 this demo is actually launched.
    progressRepository: startInPractice
        ? InMemoryProgressRepository()
        : DebugDemoEnvironment.buildProgressRepository(now: DateTime.now),
  );
}
