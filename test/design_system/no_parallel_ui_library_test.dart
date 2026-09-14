import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the forward-looking half of "[DONE] Zachowaj design system i
/// cztery glowne zakladki": new screens must reuse [lib/theme/app_theme.dart]
/// and the shared widgets in `lib/widgets/`, never introduce a second,
/// competing UI/design-system dependency (a font package, a component-kit
/// package, a second Material-alternative toolkit, ...). That rule exists
/// today only as policy — nothing previously caught a future `pubspec.yaml`
/// edit that quietly added one.
///
/// This is an explicit, named allowlist of the runtime `dependencies:`
/// this app is built on today (Flutter itself, its icon font, and local
/// storage — none of them a UI/design-system library). Adding a real,
/// justified dependency later means updating this list deliberately, not
/// hitting a check that silently stopped checking anything.
void main() {
  test(
      'pubspec.yaml runtime dependencies do not include a second UI/'
      'design-system library', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();

    final RegExp dependenciesBlock = RegExp(
      r'^dependencies:\n((?:^[ \t].*\n?)*)',
      multiLine: true,
    );
    final Match? match = dependenciesBlock.firstMatch(pubspec);
    expect(match, isNotNull,
        reason: 'expected a top-level `dependencies:` block in pubspec.yaml');

    final RegExp packageName = RegExp(r'^  ([A-Za-z0-9_]+):', multiLine: true);
    final Set<String> declaredPackages = packageName
        .allMatches(match!.group(1)!)
        .map((m) => m.group(1)!)
        .toSet();

    const allowedPackages = <String>{
      'flutter', // the SDK itself, not a third-party dependency
      'cupertino_icons', // an icon font, not a UI/component library
      'shared_preferences', // local key-value storage, unrelated to UI
      'drift', // typed SQLite persistence (PREP-661), unrelated to UI
      'sqlite3', // drift's underlying SQLite bindings, unrelated to UI
      'sqlite3_flutter_libs', // bundles the native SQLite library, unrelated to UI
      'path_provider', // locates the app's local database file, unrelated to UI
      'path', // builds the database file path, unrelated to UI
      'supabase_flutter', // requested remote content data adapter
      'crypto', // verifies downloaded release SHA-256, not a UI library
      'purchases_flutter', // explicitly requested store adapter, behind repository
      'purchases_ui_flutter', // requested optional Customer Center SDK, not app UI
    };

    expect(
      declaredPackages,
      allowedPackages,
      reason: 'A runtime dependency was added or removed. If this is a '
          'deliberate, justified addition, update allowedPackages here to '
          "match — but first confirm it isn't a second UI/design-system "
          'library: new screens must be built from lib/theme/app_theme.dart '
          "and lib/widgets/, never a parallel toolkit.",
    );
  });
  test('app screens and widgets never import RevenueCat or its paywall UI', () {
    for (final directory in ['lib/screens', 'lib/widgets', 'lib/domain']) {
      for (final file in Directory(directory)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        expect(file.readAsStringSync(), isNot(contains('package:purchases_')),
            reason: '${file.path} must use the domain subscription boundary');
      }
    }
  });
}
