import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/shared_preferences_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/main.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';

/// `production_wiring_test.dart` proves `AppBootstrapService`'s exact
/// production dependency graph, including the real
/// `DriftUserSettingsRepository`. It stops there: `ProgressRepository`
/// isn't part of `AppBootstrapService` at all — it's threaded separately,
/// straight from `_DanbRhsPrepAppState` to `MainShell`/`HomeScreen` — so
/// nothing in that file, or anywhere else, actually proves `main.dart`'s
/// *other* production default (`DriftProgressRepository`, over the same
/// on-device `AppDatabase`) is wired correctly and its row-to-domain
/// mapping works end to end. This file is that missing piece.
///
/// `DanbRhsPrepApp()` here has nothing injected at all — the exact
/// composition `main()` runs — so this exercises every real production
/// repository at once: `BundledContentRepository` (real bundled asset,
/// via `rootBundle`), `DriftUserSettingsRepository`, and
/// `DriftProgressRepository` (both over a real `AppDatabase()`, which
/// `test/flutter_test_config.dart`'s fake `PathProviderPlatform` gives a
/// real, working temp-directory file to open — not a mock of either
/// repository).
///
/// Onboarding is marked complete beforehand (through the real,
/// production `SharedPreferencesBootstrapLocalStore`'s own public
/// `writeOnboardingComplete`, backed by the same global in-memory
/// `SharedPreferencesAsync` platform every test in this suite shares —
/// never by poking a private storage key directly) so this reaches
/// `MainShell`/`HomeScreen`, which is what actually queries
/// `ProgressRepository`; the onboarding-incomplete path never touches it
/// and is already covered by `widget_test.dart`.
///
/// `testWidgets`, not `test`, and the only one in this file: `rootBundle`
/// requires a live `TestWidgetsFlutterBinding`, and a second `testWidgets`
/// here calling `BundledContentRepository` again would risk the same
/// `flutter_test` asset-channel hang documented on
/// `RealFileContentRepository` in `test/support/app_bootstrap_test_support.dart`.
void main() {
  testWidgets(
      'DanbRhsPrepApp(), with nothing injected, boots a returning user all '
      'the way to Home using its real, default-constructed '
      'DriftUserSettingsRepository and DriftProgressRepository — proving '
      'both repositories, and their row-to-domain mapping, work against '
      "main.dart's actual production wiring, not just a repository "
      'test\'s own directly-constructed instance', (tester) async {
    await SharedPreferencesBootstrapLocalStore().writeOnboardingComplete(true);

    await tester.pumpWidget(const DanbRhsPrepApp());
    // Real asset decoding and SQLite I/O need real time, while widget pumps
    // advance fake time. Wait for production startup and visible loading to
    // complete without replacing either repository or its content.
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (find.byType(MainShell).evaluate().isEmpty ||
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
        if (!DateTime.now().isBefore(deadline)) {
          fail('Production startup did not finish within 10 seconds.');
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'a real, empty on-device database queried through both '
            'production repositories must produce an honest empty state, '
            'never an uncaught exception');
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Let’s study'), findsOneWidget);
  });
}
