import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/experience_level.dart';
import 'package:danb_rhs_prep/domain/models/experience_level_codec.dart';

void main() {
  group('experienceLevelToStorageValue / experienceLevelFromStorageValue', () {
    test('each value maps to the exact expected stable string', () {
      expect(experienceLevelToStorageValue(ExperienceLevel.justStarting),
          'justStarting');
      expect(experienceLevelToStorageValue(ExperienceLevel.studyingAlready),
          'studyingAlready');
      expect(experienceLevelToStorageValue(ExperienceLevel.retakingExam),
          'retakingExam');
    });

    test('every value round-trips through the codec', () {
      for (final level in ExperienceLevel.values) {
        final String stored = experienceLevelToStorageValue(level);
        expect(experienceLevelFromStorageValue(stored), level);
      }
    });

    test('an unknown stored value returns null', () {
      expect(experienceLevelFromStorageValue('expertAlready'), isNull);
      expect(experienceLevelFromStorageValue(''), isNull);
      expect(experienceLevelFromStorageValue('JustStarting'), isNull,
          reason: 'matching must be exact, not case-insensitive');
    });

    test(
        'decoding is independent of ExperienceLevel.values\' declaration '
        'order — every value decodes correctly regardless of where it '
        'appears in the enum, since the codec is an explicit mapping, '
        'not an index/position lookup', () {
      // If the codec secretly depended on `ExperienceLevel.values`'
      // position (e.g. `ExperienceLevel.values[int.parse(value)]`), this
      // would only coincidentally work for values whose stored string
      // happens to match their declaration index. Decoding each value's
      // *own* stored string and getting that exact value back, for every
      // value, proves the mapping is keyed by the string itself.
      for (final level in ExperienceLevel.values) {
        expect(
            experienceLevelFromStorageValue(
                experienceLevelToStorageValue(level)),
            level);
      }
    });
  });

  group('source guards', () {
    test(
        'the codec does not use .name, .index, byName, or enum-order '
        'lookup', () {
      final String source =
          File('lib/domain/models/experience_level_codec.dart')
              .readAsStringSync();
      final String code = _stripComments(source);

      expect(code.contains('.name'), isFalse);
      expect(code.contains('.index'), isFalse);
      expect(code.contains('byName'), isFalse);
      expect(code.contains('ExperienceLevel.values['), isFalse);
    });

    test(
        'the persistence adapter delegates to the codec and does not '
        'itself use .name, .index, byName, or enum-order lookup for '
        'ExperienceLevel', () {
      final String source =
          File('lib/bootstrap/shared_preferences_bootstrap_local_store.dart')
              .readAsStringSync();
      final String code = _stripComments(source);

      expect(code.contains('level.name'), isFalse);
      expect(code.contains('.index'), isFalse);
      expect(code.contains('byName'), isFalse);
      expect(code.contains('ExperienceLevel.values['), isFalse);
      expect(code.contains('experienceLevelToStorageValue'), isTrue);
      expect(code.contains('experienceLevelFromStorageValue'), isTrue);
    });

    test(
        'only one codec implementation exists for ExperienceLevel '
        'persistence', () {
      final Iterable<FileSystemEntity> dartFiles = Directory('lib')
          .listSync(recursive: true)
          .where((entity) => entity.path.endsWith('.dart'));

      final List<String> declaringFiles = [];
      for (final entity in dartFiles) {
        final String source = File(entity.path).readAsStringSync();
        if (source.contains('String experienceLevelToStorageValue(')) {
          declaringFiles.add(entity.path);
        }
      }

      expect(declaringFiles, ['lib/domain/models/experience_level_codec.dart']);
    });
  });
}

/// Removes `//` line comments and `/* */` block comments so textual
/// source checks only ever see real code, not names mentioned in doc
/// comments explaining the very thing being verified.
String _stripComments(String source) {
  final String noBlockComments =
      source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return noBlockComments.split('\n').map((line) {
    final int index = line.indexOf('//');
    return index == -1 ? line : line.substring(0, index);
  }).join('\n');
}
