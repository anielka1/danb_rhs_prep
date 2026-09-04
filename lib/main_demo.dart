import 'package:flutter/material.dart';

import 'bootstrap/app_bootstrap_service.dart';
import 'debug/debug_demo_environment.dart';
import 'domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'features/content/data/bundled_content_repository.dart';
import 'main.dart';

/// The demo entrypoint. Run explicitly:
///
/// ```
/// flutter run -t lib/main_demo.dart
/// ```
///
/// Plain `flutter run` and `flutter build ios --release --no-codesign`
/// always build from `lib/main.dart`, which never imports or references
/// `DebugDemoEnvironment` — proven at the source level by
/// `test/main_test.dart`'s isolation check. This file, not a runtime flag
/// inside `lib/main.dart`, is the entire mechanism keeping demo data out
/// of a normal run or a release build: there is no code path in
/// `lib/main.dart` that can reach `DebugDemoEnvironment` at all.
///
/// **What is actually wired here** — [DebugDemoEnvironment]'s
/// [UserSettingsRepository], via [AppBootstrapService.userSettingsRepository]
/// (an existing, real injection point; see that field's own doc comment).
/// The local store is also swapped for an in-memory fake so this
/// entrypoint never reads or writes the real device's persisted app
/// state, and starts already onboarded so it lands on [MainShell].
///
/// **What is prepared but not wired here, and why** —
/// [DebugDemoEnvironment.buildProgressRepository] and
/// [DebugDemoEnvironment.buildContentRepository] are fully built and
/// exercised by `test/debug/debug_demo_environment_test.dart`, but this
/// entrypoint does not inject either into [AppBootstrapService]:
/// * `AppBootstrapService` has no `ProgressRepository` parameter at all
///   yet — progress/readiness wiring is explicitly deferred (see
///   `BootstrapLocalStore`'s own doc comment about later phases), so
///   there is nothing to inject it into without inventing new UI to
///   consume it, which is out of scope here.
/// * The demo `ContentRepository` is deliberately keyed under
///   [DebugDemoEnvironment.demoExamId] (`'demo_exam'`), never the real
///   `'danb_rhs'` — and `AppBootstrapService` always resolves and
///   requests `'danb_rhs'` (see its `_resolveSelectedExamId`). Injecting
///   the demo content repository here would therefore either throw
///   (it has no `'danb_rhs'` entry) or require keying synthetic content
///   under the real exam ID, which would blur "synthetic demo content"
///   with "the real, reviewed content bank" — exactly what keeping this
///   ID distinct is meant to prevent. Practice/Mock content in this demo
///   build is the same real bundled content production uses.
void main() {
  final localStore = InMemoryBootstrapLocalStore(onboardingComplete: true);
  final bootstrapService = AppBootstrapService(
    contentRepository: BundledContentRepository(),
    localStore: localStore,
    userSettingsRepository: DebugDemoEnvironment.buildUserSettingsRepository(),
  );

  runApp(DanbRhsPrepApp(
    bootstrapService: bootstrapService,
    localStore: localStore,
  ));
}
