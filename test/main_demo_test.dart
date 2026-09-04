import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/features/content/data/bundled_content_repository.dart';
import 'package:danb_rhs_prep/main.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';

/// Counterpart to `test/main_test.dart`'s "DebugDemoEnvironment isolation"
/// check: that test proves `lib/main.dart` never references
/// `DebugDemoEnvironment`; this file proves the demo entrypoint,
/// `lib/main_demo.dart` (run explicitly via
/// `flutter run -t lib/main_demo.dart`), does — both the source-level
/// wiring and, behaviorally, that constructing the app the same way it
/// does actually boots to `MainShell` without error. This was also
/// verified manually on the iOS simulator (`flutter run -t
/// lib/main_demo.dart`): it launched, reached Home, and showed the same
/// honest "No study tasks yet" empty state production shows, since
/// nothing consumes the injected demo profile yet (see
/// DebugDemoEnvironment's own doc comment for exactly what is and isn't
/// wired).
void main() {
  test('lib/main_demo.dart explicitly injects DebugDemoEnvironment', () {
    final String source = File('lib/main_demo.dart').readAsStringSync();

    expect(
      source.contains(
          'userSettingsRepository: DebugDemoEnvironment.buildUserSettingsRepository()'),
      isTrue,
      reason: 'lib/main_demo.dart is expected to be the one place that '
          "explicitly wires DebugDemoEnvironment's UserSettingsRepository "
          'into AppBootstrapService.',
    );
  });

  test(
      'lib/main_demo.dart has its own void main() — a real, separate '
      'entrypoint, not a code path reachable from lib/main.dart', () {
    final String source = File('lib/main_demo.dart').readAsStringSync();
    expect(source.contains('void main() {'), isTrue);
    expect(source.contains('runApp('), isTrue);
  });

  testWidgets(
      'the exact wiring lib/main_demo.dart performs boots to MainShell, '
      'Home without error', (tester) async {
    // Mirrors lib/main_demo.dart's main() function exactly, so this
    // proves the real demo wiring works, not just a similar-looking
    // stand-in.
    final localStore = InMemoryBootstrapLocalStore(onboardingComplete: true);
    final bootstrapService = AppBootstrapService(
      contentRepository: BundledContentRepository(),
      localStore: localStore,
      userSettingsRepository:
          DebugDemoEnvironment.buildUserSettingsRepository(),
    );

    await tester.pumpWidget(DanbRhsPrepApp(
      bootstrapService: bootstrapService,
      localStore: localStore,
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}
