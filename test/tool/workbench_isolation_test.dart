import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Proves, at the source/config level, that `content_workbench/` is
/// genuinely unbundled: not registered as a Flutter asset, and never
/// imported or referenced by anything under `lib/` (the production app).
/// A candidate question sitting in the workbench must have zero way to
/// reach a real user until it is explicitly promoted into
/// `assets/content/danb_rhs/content.json` by a human — see
/// docs/DANB_RHS_CONTENT_APPROVAL_WORKFLOW.md.
void main() {
  test(
      'pubspec.yaml does not register content_workbench/ as a Flutter '
      'asset — the workbench cannot be bundled into the app by accident', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('content_workbench'), isFalse,
        reason: 'pubspec.yaml must not reference content_workbench/ under '
            'flutter/assets or anywhere else — the workbench is reviewed, '
            'unbundled content, not production content.');
  });

  test(
      'no file under lib/ (production app code) references '
      'content_workbench/ or reads from it', () {
    final Directory libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final List<File> dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    expect(dartFiles, isNotEmpty);

    for (final file in dartFiles) {
      final String source = file.readAsStringSync();
      expect(source.contains('content_workbench'), isFalse,
          reason: '${file.path} must not reference content_workbench/ — '
              'production code may only load bundled content from '
              'assets/content/danb_rhs/content.json.');
    }
  });

  test(
      'the only bundled content asset registered in pubspec.yaml is the '
      'production content.json — no candidate/workbench JSON is listed', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExp assetLine =
        RegExp(r'^\s*-\s*(assets/\S+)\s*$', multiLine: true);
    final List<String> assets =
        assetLine.allMatches(pubspec).map((m) => m.group(1)!).toList();

    expect(assets, contains('assets/content/danb_rhs/content.json'));
    for (final asset in assets) {
      expect(asset.contains('content_workbench'), isFalse);
      expect(asset.contains('candidate'), isFalse);
    }
  });
}
