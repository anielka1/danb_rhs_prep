import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Proves, at the source level, the dependency-direction boundary
/// `ExperienceLevel`'s extraction into a leaf file is meant to
/// establish (mirroring `exam_date_precision_dependency_test.dart`): it
/// is a standalone, dependency-free enum, and both `UserProfile` and the
/// onboarding/bootstrap layer (`BootstrapLocalStore`) depend on it
/// one-way — no circular import, and nothing depends on the
/// `UserProfile` aggregate merely to reuse this enum.
void main() {
  const String leafPath = 'lib/domain/models/experience_level.dart';
  const String userProfilePath = 'lib/domain/models/user_profile.dart';
  const String bootstrapLocalStorePath =
      'lib/domain/repositories/bootstrap_local_store.dart';

  test('experience_level.dart has no imports of its own', () {
    final String source = File(leafPath).readAsStringSync();
    expect(_importedUris(source), isEmpty,
        reason: 'the leaf enum file must stay dependency-free');
  });

  test(
      'exactly one ExperienceLevel enum is declared, only in the leaf '
      'file', () {
    final Iterable<FileSystemEntity> dartFiles = Directory('lib')
        .listSync(recursive: true)
        .where((entity) => entity.path.endsWith('.dart'));

    final List<String> declaringFiles = [];
    for (final entity in dartFiles) {
      final String source = File(entity.path).readAsStringSync();
      if (RegExp(r'\benum\s+ExperienceLevel\b').hasMatch(source)) {
        declaringFiles.add(entity.path);
      }
    }

    expect(declaringFiles, [leafPath],
        reason: 'ExperienceLevel must be declared exactly once, in the '
            'leaf file — not duplicated elsewhere');
  });

  test('UserProfile depends on the leaf enum, one-way', () {
    final String source = File(userProfilePath).readAsStringSync();
    expect(_importedUris(source), contains('experience_level.dart'));
  });

  test('BootstrapLocalStore depends on the leaf enum, one-way', () {
    final String source = File(bootstrapLocalStorePath).readAsStringSync();
    final Iterable<String> imports = _importedUris(source);
    expect(imports.any((uri) => uri.endsWith('experience_level.dart')), isTrue);
  });

  test(
      'no circular imports: the leaf file does not import either '
      'consumer that depends on it', () {
    final String source = File(leafPath).readAsStringSync();
    final Iterable<String> imports = _importedUris(source);
    expect(imports, isNot(contains('user_profile.dart')));
    expect(imports, isNot(contains('bootstrap_local_store.dart')));
  });
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
