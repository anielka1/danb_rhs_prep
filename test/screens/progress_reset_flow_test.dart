import '../study_plan/onboarding_helper.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/main_demo.dart' as demo;
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';

Future<void> tap(WidgetTester tester, String label) async {
  final f = find.text(label);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'reset from settings clears data, disposes old shell and preserves plan',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(demo.createDebugDemoApp());
    await tester.pumpAndSettle();
    for (final label in [
      'Start Preparing',
      "I haven't scheduled it yet",
      'Continue'
    ]) {
      await tap(tester, label);
    }
    await skipStartingCheck(tester);
    final oldShell = tester.state(find.byType(MainShell));
    final oldContext = tester.element(find.byType(MainShell));
    final session = BootstrapSessionScope.maybeControllerOf(oldContext)!;
    final oldRepo = session.progressRepository!;
    final before = session.snapshot;
    await tap(tester, 'Continue session');
    final oldPractice = PracticeSessionScope.of(
        tester.element(find.byType(PracticeQuestionScreen)));
    await tap(tester, 'Home');
    await tester.ensureVisible(find.bySemanticsLabel('Settings'));
    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    await tap(tester, 'Dark');
    await tap(tester, 'Reset study progress');
    await tap(tester, 'Keep my progress');
    expect(await oldRepo.inProgressPracticeSession(before.selectedExamId),
        isNotNull);
    await tap(tester, 'Reset study progress');
    await tap(tester, 'Reset progress');
    expect(find.byType(ProfileSettingsScreen), findsNothing);
    expect(oldShell.mounted, isFalse);
    expect(
        find.byType(PracticeQuestionScreen, skipOffstage: false), findsNothing);
    await oldPractice.saveSession();
    await oldPractice.retrySaving();
    expect(oldPractice.hasUnsavedChanges, isTrue);
    expect(session.snapshot.examDateSelection, before.examDateSelection);
    expect(session.snapshot.experienceLevel, before.experienceLevel);
    expect(session.snapshot.profile, before.profile);
    expect(session.snapshot.readinessSnapshot, isNull);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark);
    final fresh =
        tester.widget<MainShell>(find.byType(MainShell)).progressRepository!;
    expect(await fresh.answerAttemptsForExam(before.selectedExamId), isEmpty);
    expect(
        await fresh.inProgressPracticeSession(before.selectedExamId), isNull);
    expect(await fresh.mockAttemptsForExam(before.selectedExamId), isEmpty);
    await expectLater(
        oldRepo.savePracticeSession(
            DebugDemoEnvironment.demoInProgressPracticeSession),
        throwsStateError);
    expect(
        Navigator.of(tester.element(find.byType(MainShell)),
                rootNavigator: true)
            .canPop(),
        isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'failure remains retryable and reset blocks back while pending at large text',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final theme = ThemeModeController();
    addTearDown(theme.dispose);
    var calls = 0;
    final gate = Completer<void>();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(4)),
          child: child!),
      home: ProfileSettingsScreen(
          themeModeController: theme,
          onResetProgress: () async {
            calls++;
            if (calls == 1) throw StateError('private diagnostic');
            await gate.future;
          }),
    ));
    await tap(tester, 'Reset study progress');
    await tap(tester, 'Reset progress');
    expect(
        find.text(
            'Could not reset progress. Your saved data is unchanged. Try again.'),
        findsOneWidget);
    expect(find.text('private diagnostic'), findsNothing);
    await tap(tester, 'Reset study progress');
    await tap(tester, 'Reset progress');
    expect(calls, 2);
    expect(find.text('Resetting progress…'), findsOneWidget);
    final pop = tester.widget<PopScope>(find.byType(PopScope));
    expect(pop.canPop, isFalse);
    gate.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
