import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the semantic-color-token rule: every color used anywhere in the
/// UI must resolve through [AppSemanticColors] / [ColorScheme] / a named
/// `App*Colors` token rather than a raw color value typed directly into a
/// widget. The only file allowed to define raw color values is
/// `lib/theme/app_theme.dart`, where the light/dark palettes are declared
/// once and exposed as named tokens (see `AppThemeContext.colors` /
/// `.semanticColors`, and `AppShadowColors`).
///
/// Without this test, nothing stops a future screen from pasting in a raw
/// `Color(0xFF...)`, `Color.fromARGB(...)`, `Color.fromRGBO(...)`,
/// `Colors.foo` or `CupertinoColors.foo` instead of reading
/// `context.colors.*` / `context.semanticColors.*` — the convention would
/// be enforced only by code review.
///
/// Detects, as raw color *definitions*:
///  - `Color(...)` constructor calls (e.g. `Color(0xFF123456)`)
///  - `Color.fromARGB(...)` / `Color.fromRGBO(...)`
///  - `Colors.<name>` (Flutter's Material color palette)
///  - `CupertinoColors.<name>` (Flutter's Cupertino color palette)
///
/// The regexes require a non-identifier character immediately before the
/// match, so they do not false-positive on identifiers that merely contain
/// "Color(s)" as a substring, e.g. `context.semanticColors.success`,
/// `AppSemanticColors.light`, or `AppShadowColors.base`.
void main() {
  test('no raw color definitions outside the theme definition file', () {
    final libDir = Directory('lib');
    final allowedSuffix =
        '${Platform.pathSeparator}theme${Platform.pathSeparator}app_theme.dart';

    final patterns = <String, RegExp>{
      'Color(...) constructor': RegExp(r'(?<![A-Za-z0-9_])Color\('),
      'Color.fromARGB(...)': RegExp(r'(?<![A-Za-z0-9_])Color\.fromARGB\('),
      'Color.fromRGBO(...)': RegExp(r'(?<![A-Za-z0-9_])Color\.fromRGBO\('),
      'Colors.*': RegExp(r'(?<![A-Za-z0-9_])Colors\.[A-Za-z0-9_]+'),
      'CupertinoColors.*':
          RegExp(r'(?<![A-Za-z0-9_])CupertinoColors\.[A-Za-z0-9_]+'),
    };

    // Minimal, named, value-based allowlist — not a per-file or per-folder
    // exemption. Each entry names the *exact* matched token and the reason
    // it isn't a themed color choice, so it can't be used to smuggle in
    // unrelated raw colors:
    //
    // `Colors.transparent` carries no light/dark variant and paints
    // nothing — it means "no fill", not a color decision, and every call
    // site already pairs it with a real semantic token for the "on" state
    // (e.g. `selected ? colors.primary : Colors.transparent`).
    const allowedTokens = <String>{'Colors.transparent'};

    final offenders = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith(allowedSuffix)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        for (final entry in patterns.entries) {
          for (final match in entry.value.allMatches(line)) {
            if (allowedTokens.contains(match.group(0))) continue;
            offenders.add(
              '${entity.path}:${i + 1}: [${entry.key}] ${line.trim()}',
            );
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Raw color definitions must live only in '
          'lib/theme/app_theme.dart and be exposed as named semantic '
          'tokens. Found:\n${offenders.join('\n')}',
    );
  });
}
