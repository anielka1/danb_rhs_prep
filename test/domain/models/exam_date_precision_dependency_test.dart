import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Proves, at the source level, the dependency-direction boundary
/// `ExamDatePrecision`'s extraction into a leaf file is meant to
/// establish: it is a standalone, dependency-free enum, and both
/// `UserProfile` and `ExamDateSelection` depend on it one-way — neither
/// depends on the other merely to share this concept, and there is no
/// circular import.
void main() {
  const String leafPath = 'lib/domain/models/exam_date_precision.dart';
  const String userProfilePath = 'lib/domain/models/user_profile.dart';
  const String examDateSelectionPath =
      'lib/domain/models/exam_date_selection.dart';

  test('exam_date_precision.dart has no imports of its own', () {
    final String source = File(leafPath).readAsStringSync();
    expect(_importedUris(source), isEmpty,
        reason: 'the leaf enum file must stay dependency-free');
  });

  test(
      'exactly one ExamDatePrecision enum is declared, only in the leaf '
      'file', () {
    final Iterable<FileSystemEntity> dartFiles = Directory('lib')
        .listSync(recursive: true)
        .where((entity) => entity.path.endsWith('.dart'));

    final List<String> declaringFiles = [];
    for (final entity in dartFiles) {
      final String source = File(entity.path).readAsStringSync();
      if (RegExp(r'\benum\s+ExamDatePrecision\b').hasMatch(source)) {
        declaringFiles.add(entity.path);
      }
    }

    expect(declaringFiles, [leafPath],
        reason: 'ExamDatePrecision must be declared exactly once, in the '
            'leaf file — not duplicated elsewhere');
  });

  test('UserProfile depends on the leaf enum, one-way', () {
    final String source = File(userProfilePath).readAsStringSync();
    expect(_importedUris(source), contains('exam_date_precision.dart'));
  });

  test(
      'ExamDateSelection depends on the leaf enum, one-way, and does not '
      'depend on the UserProfile aggregate merely for the enum', () {
    final String source = File(examDateSelectionPath).readAsStringSync();
    final Iterable<String> imports = _importedUris(source);
    expect(imports, contains('exam_date_precision.dart'));
    expect(imports, isNot(contains('user_profile.dart')),
        reason: 'ExamDateSelection must not import the UserProfile '
            'aggregate merely to reuse ExamDatePrecision');
  });

  test(
      'no circular imports: the leaf file does not import either model '
      'that depends on it', () {
    final String source = File(leafPath).readAsStringSync();
    final Iterable<String> imports = _importedUris(source);
    expect(imports, isNot(contains('user_profile.dart')));
    expect(imports, isNot(contains('exam_date_selection.dart')));
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
