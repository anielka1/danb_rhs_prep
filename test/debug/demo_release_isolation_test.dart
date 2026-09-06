import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production imports and exports cannot reach demo fixtures transitively',
      () {
    final pending = [File('lib/main.dart').absolute.uri];
    final visited = <Uri>{};
    final directives = RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''');
    while (pending.isNotEmpty) {
      final uri = pending.removeLast();
      if (!visited.add(uri)) continue;
      expect(uri.path, isNot(contains('/debug/')));
      expect(uri.path, isNot(endsWith('/main_demo.dart')));
      final source = File.fromUri(uri)
          .readAsStringSync()
          .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
          .replaceAll(RegExp(r'//[^\n]*'), '');
      for (final match in directives.allMatches(source)) {
        final dependency = match.group(1)!;
        if (dependency.startsWith('package:danb_rhs_prep/')) {
          pending.add(Directory('lib').absolute.uri.resolve(
                dependency.substring('package:danb_rhs_prep/'.length),
              ));
        } else if (!dependency.contains(':')) {
          pending.add(uri.resolve(dependency));
        }
      }
    }
    expect(visited.length, greaterThan(1));
  });

  for (final mode in ['product', 'profile']) {
    test('$mode AOT blocks every fixture and strips synthetic content',
        () async {
      final directory = Directory.systemTemp.createTempSync('demo-isolation-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final environment =
          File('lib/debug/debug_demo_environment.dart').absolute.uri;
      final blueprint =
          File('lib/mock_exam/mock_exam_blueprint.dart').absolute.uri;
      final probe = File('${directory.path}/probe.dart')..writeAsStringSync('''
import '$environment';
import '$blueprint';
void main() {
  final accessors = <Object? Function()>[
    () => DebugDemoEnvironment.demoProfile,
    () => DebugDemoEnvironment.demoQuestions,
    () => DebugDemoEnvironment.demoContentPackage,
    () => DebugDemoEnvironment.demoPracticeSession,
    () => DebugDemoEnvironment.demoMockAttempt,
    () => DebugDemoEnvironment.demoMockAttemptEarlier,
    () => DebugDemoEnvironment.demoAnswerAttempts,
    () => DebugDemoEnvironment.demoQuestionStates,
    () => DebugDemoEnvironment.demoReadinessSnapshot,
    () => DebugDemoEnvironment.demoReadinessSnapshotEarlier,
    DebugDemoEnvironment.buildUserSettingsRepository,
    DebugDemoEnvironment.buildProgressRepository,
    DebugDemoEnvironment.buildContentRepository,
  ];
  for (var i = 0; i < accessors.length; i++) {
    try {
      accessors[i]();
    } on UnsupportedError {
      continue;
    }
    throw StateError('Fixture accessor \$i was available');
  }
  try {
    MockExamBlueprint.ensureDemoAllowed();
    throw StateError('Mock demo mode was available');
  } on MockExamUnavailable {
    // Expected in product and profile AOT.
  }
  print('All fixture accessors blocked');
}
''');
      final executable = '${directory.path}/probe';
      final compile = await Process.run('dart', [
        'compile',
        'exe',
        '-Ddart.vm.product=${mode == 'product'}',
        '-Ddart.vm.profile=${mode == 'profile'}',
        probe.path,
        '-o',
        executable,
      ]);
      expect(compile.exitCode, 0,
          reason: '${compile.stdout}\n${compile.stderr}');
      final run = await Process.run(executable, []);
      expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
      expect(run.stdout, contains('All fixture accessors blocked'));
      final binary = latin1.decode(File(executable).readAsBytesSync());
      for (final marker in [
        '[Demo] What is 2 + 2?',
        'demo-fixtures-v1',
        'demo-practice-session-1',
        'demo-mock-attempt-1',
        'demo-readiness-1',
      ]) {
        expect(binary, isNot(contains(marker)),
            reason: '$marker leaked into $mode AOT');
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}
