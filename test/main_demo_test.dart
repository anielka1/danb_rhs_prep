import 'study_plan/onboarding_helper.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/main_demo.dart' as demo;
import 'package:danb_rhs_prep/screens/exam_date_screen.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/screens/welcome_screen.dart';

/// Exercises the real composition root, including the snapshot consumed
/// by UI. Onboarding starts incomplete (see main_demo.dart's own doc
/// comment) — PREP-647's actual point is that Welcome -> Exam Date ->
/// Experience Level -> Home is genuinely clickable end to end through the
/// demo environment, not that the demo entrypoint skips straight to Home.
Future<void> _clickThroughOnboarding(WidgetTester tester) async {
  expect(find.byType(WelcomeScreen), findsOneWidget);
  expect(find.byType(MainShell), findsNothing);

  await tester.tap(find.text('Start Preparing'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.byType(ExamDateScreen), findsOneWidget);

  // No date is pre-seeded — "I haven't scheduled it yet" is a real tap,
  // not a default already selected for the test.
  await tester.tap(find.text("I haven't scheduled it yet"));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expectOnboardingHome(tester);
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets(
      'real demo entrypoint: onboarding is genuinely clickable end to end '
      'and the resulting session exposes the demo profile/readiness/'
      'content', (tester) async {
    demo.main();
    await tester.pumpAndSettle();

    await _clickThroughOnboarding(tester);

    expect(find.byType(MainShell), findsOneWidget);
    final snapshot = BootstrapSessionScope.snapshotOf(
        tester.element(find.byType(MainShell)));
    expect(snapshot.profile!.examId, DebugDemoEnvironment.demoProfile.examId);
    expect(snapshot.profile!.studyPlanPreferences, isNull);
    expect(snapshot.experienceLevel, isNull);
    expect(snapshot.profile!.dailyGoalQuestions,
        DebugDemoEnvironment.demoProfile.dailyGoalQuestions);
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
          'finaluserSettingsRepository=DebugDemoEnvironment.buildUserSettingsRepository();'),
      isTrue,
      reason: 'lib/main_demo.dart is expected to be the one place that '
          "explicitly wires DebugDemoEnvironment's UserSettingsRepository "
          'into bootstrap and the application.',
    );
    expect(
        RegExp(r'userSettingsRepository:\s*userSettingsRepository')
            .allMatches(source)
            .length,
        2,
        reason:
            'Bootstrap and settings must share the same in-memory demo repository.');
  });

  test(
      'lib/main_demo.dart has its own void main() — a real, separate '
      'entrypoint, not a code path reachable from lib/main.dart', () {
    final String source = File('lib/main_demo.dart').readAsStringSync();
    expect(source.contains('void main() {'), isTrue);
    expect(source.contains('runApp('), isTrue);
  });

  test('lib/main_demo.dart starts onboarding incomplete, not skipped', () {
    final String source = File('lib/main_demo.dart').readAsStringSync();
    expect(source.contains('onboardingComplete: false'), isTrue,
        reason: 'the demo entrypoint must start at Welcome so onboarding '
            'is actually exercised — starting at onboardingComplete: true '
            'would skip the very flow this environment exists to '
            'demonstrate.');
  });

  testWidgets(
      'the exact wiring lib/main_demo.dart performs: Welcome through '
      'Home is clickable end to end, then a fresh instance (a real '
      'restart) honestly starts over rather than faking a persisted '
      'completion', (tester) async {
    await tester.pumpWidget(demo.createDebugDemoApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _clickThroughOnboarding(tester);

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Let’s study'), findsOneWidget);

    await tester.tap(find.text('Continue session'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeQuestionScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // A fresh createDebugDemoApp() call is a new in-memory environment —
    // exactly what happens if the demo process is actually restarted.
    // It must honestly show Welcome again, never a fake "still onboarded"
    // shortcut: nothing here is real persistence.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(demo.createDebugDemoApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
  });
}
