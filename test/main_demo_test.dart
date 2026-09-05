import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/main_demo.dart' as demo;

/// Exercise the real composition root, including the snapshot consumed by UI.
void main() {
  testWidgets('real demo entrypoint exposes demo profile and content',
      (tester) async {
    demo.main();
    await tester.pumpAndSettle();
    final snapshot = BootstrapSessionScope.snapshotOf(
        tester.element(find.byType(MainShell)));
    expect(snapshot.profile, DebugDemoEnvironment.demoProfile);
    expect(
        snapshot.readinessSnapshot, DebugDemoEnvironment.demoReadinessSnapshot);
    expect(snapshot.selectedExamId, DebugDemoEnvironment.demoExamId);
    expect(
        snapshot.contentPackage.questions.every((q) => q.tags.contains('demo')),
        isTrue);
  });
  test('lib/main_demo.dart explicitly injects DebugDemoEnvironment', () {
    final String source = File('lib/main_demo.dart').readAsStringSync();

    expect(
      source.replaceAll(RegExp(r'\s+'), '').contains(
          'userSettingsRepository:DebugDemoEnvironment.buildUserSettingsRepository()'),
      isTrue,
      reason: 'lib/main_demo.dart is expected to be the one place that '
          "explicitly wires DebugDemoEnvironment's UserSettingsRepository "
          'into AppBootstrapService.',
    );
  });

  test(
      'lib/main_demo.dart has its own void main() — a real, separate '
      'entrypoint, not a code path reachable from lib/main.dart', () {
    final String source = File('lib/main_demo.dart').readAsStringSync();
    expect(source.contains('void main() {'), isTrue);
    expect(source.contains('runApp('), isTrue);
  });

  testWidgets(
      'the exact wiring lib/main_demo.dart performs boots to MainShell, '
      'Home without error', (tester) async {
    await tester.pumpWidget(demo.createDebugDemoApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.text('Exam Info'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(demo.createDebugDemoApp());
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    final snapshot = BootstrapSessionScope.snapshotOf(
      tester.element(find.byType(MainShell)),
    );
    expect(snapshot.profile, DebugDemoEnvironment.demoProfile);
  });
}
