import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The fixture library remains plain Dart, including its VM-constant mode gate.
/// This lets AOT isolation tests compile it without the Flutter engine.
void main() {
  const String environmentPath = 'lib/debug/debug_demo_environment.dart';

  test('debug_demo_environment.dart has no Flutter import', () {
    final String source = File(environmentPath).readAsStringSync();
    final Iterable<String> imports = _importedUris(source);

    expect(imports, isNotEmpty);
    for (final String uri in imports) {
      expect(uri.startsWith('package:flutter/'), isFalse,
          reason: 'DebugDemoEnvironment must not import "$uri" — it must '
              'stay usable identically from any context (debug, test, or '
              'a future consumer), with no Flutter dependency of its own.');
    }
  });

  test(
      'debug_demo_environment.dart does not reference kDebugMode/'
      'kReleaseMode in actual code (doc-comment mentions of the name '
      "explaining main.dart's gate don't count)", () {
    final String code =
        _stripComments(File(environmentPath).readAsStringSync());
    expect(code.contains('kDebugMode'), isFalse,
        reason:
            'The environment uses plain-Dart VM constants for its mode gate, '
            'without depending on Flutter foundation constants.');
    expect(code.contains('kReleaseMode'), isFalse);
  });
}

/// Removes `//` line comments and `///`/`/** */` doc/block comments so
/// textual checks above only ever see real code, not names mentioned in
/// prose explaining the very boundary being verified.
String _stripComments(String source) {
  final String noBlockComments =
      source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return noBlockComments.split('\n').map((line) {
    final int index = line.indexOf('//');
    return index == -1 ? line : line.substring(0, index);
  }).join('\n');
}

/// Extracts every quoted URI from `import '...'`/`import "..."`
/// statements in [source], in appearance order.
Iterable<String> _importedUris(String source) sync* {
  final RegExp importPattern =
      RegExp(r'''^import\s+['"]([^'"]+)['"]''', multiLine: true);
  for (final RegExpMatch match in importPattern.allMatches(source)) {
    yield match.group(1)!;
  }
}
