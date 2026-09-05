import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

import '../support/practice_session_test_support.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.lightTheme, home: child);

  group('no active session', () {
    testWidgets('shows an honest empty state, not a fake score',
        (tester) async {
      await tester.pumpWidget(wrap(const PracticeSummaryScreen()));

      expect(find.text('No active practice session'), findsOneWidget);
      expect(find.text('78%'), findsNothing);
      expect(find.text('78/100 Correct'), findsNothing);
    });
  });

  group('reproduces the audited defect', () {
    testWidgets(
        'score, time spent, and topic breakdown reflect the real session, '
        'not the fixed 78% / 42m literals', (tester) async {
      final controller = buildDemoPracticeSessionController();
      // 3 correct, 2 incorrect out of 5 — deliberately not 78/100.
      final questions = DebugDemoEnvironment.demoQuestions;
      for (var i = 0; i < questions.length; i++) {
        controller.moveTo(i);
        final bool answerCorrectly = i < 3;
        await controller.submitAnswer(answerCorrectly
            ? questions[i].correctAnswerId
            : questions[i].answers.last.id);
      }
      await controller.complete();

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const PracticeSummaryScreen(),
      )));

      // Every demo question shares the same topicId, so the single-topic
      // breakdown row coincidentally shows the same "60%" as the overall
      // score — findsWidgets (not findsOneWidget) tolerates that overlap
      // without weakening what this actually proves: the real 60%/3-5
      // score is present and the old fixed 78% is nowhere to be found.
      expect(find.text('60%'), findsWidgets);
      expect(find.text('3/5 Correct'), findsOneWidget);
      expect(find.text('78%'), findsNothing);
      expect(find.text('78/100 Correct'), findsNothing);
    });
  });

  group('Back to Home', () {
    testWidgets(
        'pops back to the existing MainShell instead of re-entering '
        'through the static route table', (tester) async {
      // Mirrors the real app shape: MainShell is reached via an explicit
      // MaterialPageRoute carrying BootstrapSessionScope (as
      // SplashScreen/ExperienceLevelScreen actually do), never via the
      // plain named-route table entry in main.dart (which has no such
      // ancestor) — PracticeSummaryScreen's "Back to Home" must return to
      // *that* instance, not rebuild a new, unwrapped one.
      final BootstrapSessionController sessionController =
          BootstrapSessionController(
        BootstrapReady(
          selectedExamId: DebugDemoEnvironment.demoExamId,
          contentPackage: DebugDemoEnvironment.demoContentPackage,
          profile: null,
          themePreference: ThemePreference.system,
          readinessSnapshot: null,
          entitlement:
              Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1)),
          onboardingComplete: true,
          examDateSelection: null,
          experienceLevel: null,
        ),
      );

      final GlobalKey mainShellKey = GlobalKey();

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        routes: {
          // Matches main.dart's real (bare, unwrapped) table entry.
          MainShell.route: (_) => MainShell(
                progressRepository:
                    DebugDemoEnvironment.buildProgressRepository(),
              ),
        },
        home: const SizedBox.shrink(),
      ));

      final BuildContext splashContext = tester.element(find.byType(SizedBox));
      Navigator.of(splashContext).pushReplacement(MaterialPageRoute(
        settings: const RouteSettings(name: MainShell.route),
        builder: (_) => BootstrapSessionScope(
          controller: sessionController,
          child: MainShell(
            key: mainShellKey,
            progressRepository: DebugDemoEnvironment.buildProgressRepository(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final State originalMainShellState = mainShellKey.currentState!;
      final BuildContext mainShellContext =
          tester.element(find.byType(MainShell));
      Navigator.of(mainShellContext).push(MaterialPageRoute(
        builder: (_) => PracticeSessionScope(
          controller: buildDemoPracticeSessionController(),
          child: const PracticeSummaryScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSummaryScreen), findsOneWidget);

      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PracticeSummaryScreen), findsNothing);
      expect(find.byType(MainShell), findsOneWidget);
      expect(mainShellKey.currentState, same(originalMainShellState),
          reason: 'must return to the same MainShell instance, not a '
              'freshly-built one');
    });
  });
}
