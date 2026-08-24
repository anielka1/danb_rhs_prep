import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Proves, at the source level, the dependency-direction boundary
/// `AppBootstrapService` must maintain: it — and everything it directly
/// imports — must be plain Dart, with Flutter's asset APIs
/// (`package:flutter/services.dart`, `rootBundle`) confined to the
/// data/infrastructure layer (`BundledExamContentLoader`,
/// `BundledContentRepository`) and wired only from the composition root
/// (`main.dart`).
///
/// This is a structural guard, not a behavioral one: it reads source
/// text rather than exercising runtime behavior, matching how the
/// existing "no remote dependency is reachable" test in
/// `app_bootstrap_service_test.dart` already proves the offline
/// boundary the same way.
void main() {
  const String servicePath = 'lib/bootstrap/app_bootstrap_service.dart';

  test('app_bootstrap_service.dart has no Flutter import', () {
    final String source = File(servicePath).readAsStringSync();
    final Iterable<String> imports = _importedUris(source);

    for (final String uri in imports) {
      expect(uri.startsWith('package:flutter/'), isFalse,
          reason: 'AppBootstrapService must not import "$uri" — Flutter '
              'imports belong only in the data/infrastructure layer, '
              'never in the bootstrap service itself.');
    }
  });

  test(
      'app_bootstrap_service.dart\'s direct local dependencies also carry '
      'no Flutter import — the plain-Dart boundary extends one level '
      'deep, not just to this file', () {
    final String source = File(servicePath).readAsStringSync();
    final List<String> relativeImports =
        _importedUris(source).where((uri) => uri.startsWith('../')).toList();

    // Sanity check: this file does import several local dependencies —
    // if this were empty, the loop below would vacuously pass without
    // proving anything.
    expect(relativeImports, isNotEmpty);

    for (final String relative in relativeImports) {
      final String resolved = File(
        'lib/bootstrap/$relative'.split('/').fold<List<String>>([],
            (segments, part) {
          if (part == '..') {
            segments.removeLast();
          } else {
            segments.add(part);
          }
          return segments;
        }).join('/'),
      ).path;
      final String depSource = File(resolved).readAsStringSync();

      expect(depSource.contains("package:flutter/"), isFalse,
          reason: 'AppBootstrapService\'s direct dependency "$resolved" '
              'must not import Flutter — that would make the Flutter '
              'dependency transitive even though this file itself '
              'never imports Flutter directly.');
    }
  });

  test(
      'ExamContentLoader/BundledExamContentLoader (the rootBundle-backed '
      'type) is not imported by app_bootstrap_service.dart\'s actual '
      'code (doc-comment mentions of the name don\'t count)', () {
    final String code = _stripComments(File(servicePath).readAsStringSync());

    expect(code.contains('bundled_exam_content_loader.dart'), isFalse,
        reason: 'AppBootstrapService must depend on the plain-Dart '
            'ContentRepository interface, not on the Flutter-importing '
            'file that declares ExamContentLoader/BundledExamContentLoader.');
    expect(code.contains('rootBundle'), isFalse);
    expect(code.contains("package:flutter"), isFalse);
  });

  test(
      'Flutter-specific content-loading construction (BundledContentRepository/'
      'BundledExamContentLoader) happens only in the composition root '
      '(main.dart), not in the bootstrap service\'s actual code '
      '(doc-comment mentions of the name don\'t count)', () {
    final String mainSource = File('lib/main.dart').readAsStringSync();

    expect(mainSource.contains('BundledContentRepository()'), isTrue,
        reason: 'main.dart is expected to be the one place that '
            'constructs the Flutter-backed production content adapter.');

    final String serviceCode =
        _stripComments(File(servicePath).readAsStringSync());
    expect(serviceCode.contains('BundledContentRepository'), isFalse,
        reason: 'the bootstrap service must depend only on the abstract '
            'ContentRepository interface, never construct or reference '
            'the concrete Flutter-backed adapter itself.');
  });
}

/// Removes `//` line comments and `///`/`/** */` doc/block comments so
/// textual checks below only ever see real code, not names mentioned in
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
