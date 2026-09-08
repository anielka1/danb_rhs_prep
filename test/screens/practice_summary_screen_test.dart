import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

import '../support/practice_session_test_support.dart';

Question _question({
  required String id,
  required String topicId,
  required String correctAnswerId,
}) {
  return Question(
    id: id,
    examId: DebugDemoEnvironment.demoExamId,
    domainId: 'demo_domain',
    topicId: topicId,
    questionText: '[Demo] $id?',
    answers: const [
      Answer(id: 'a', text: 'Right'),
      Answer(id: 'b', text: 'Wrong'),
    ],
    correctAnswerId: correctAnswerId,
    explanation: 'This is a synthetic demo question, not real exam content.',
    references: const [],
    difficulty: 1,
    status: QuestionStatus.draft,
    version: 1,
    updatedAt: DateTime.utc(2026, 1, 1),
    sourceVersion: 'demo-fixtures-v1',
    tags: const ['demo'],
  );
}

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.lightTheme, home: child);

  testWidgets('review shows only mistakes and leaves the score unchanged',
      (tester) async {
    final controller = buildDemoPracticeSessionController();
    for (var i = 0; i < controller.questions.length; i++) {
      controller.moveTo(i);
      final question = controller.questions[i];
      await controller.submitAnswer(i == 0
          ? question.answers
              .firstWhere((a) => a.id != question.correctAnswerId)
              .id
          : question.correctAnswerId);
    }
    await controller.complete();
    final score = controller.correctCount;
    await tester.pumpWidget(wrap(PracticeSessionScope(
      controller: controller,
      child: const PracticeSummaryScreen(),
    )));
    await tester.ensureVisible(find.text('Review Mistakes'));
    await tester.tap(find.text('Review Mistakes'));
    await tester.pumpAndSettle();
    expect(find.text(controller.questions.first.questionText), findsOneWidget);
    expect(find.text(controller.questions[1].questionText), findsNothing);
    expect(
        find.text(
            controller.feedbackFor(controller.questions.first.id)!.explanation),
        findsOneWidget);
    await tester.ensureVisible(find.text('Back to summary'));
    await tester.tap(find.text('Back to summary'));
    await tester.pumpAndSettle();
    expect(find.text('Session Complete!'), findsOneWidget);
    expect(controller.correctCount, score);
  });

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

  group('a session with no answers (PREP-463)', () {
    testWidgets(
        'shows a real 0% / 0 correct instead of dividing by zero, and '
        'hides the topic breakdown and strongest/weakest sections '
        'entirely rather than showing an empty or fabricated one',
        (tester) async {
      final controller = buildDemoPracticeSessionController();
      // Deliberately no submitAnswer calls at all before completing.
      await controller.complete();

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const PracticeSummaryScreen(),
      )));

      expect(tester.takeException(), isNull,
          reason: 'correct/total is 0/0 here — must not throw or NaN');
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0/5 Correct'), findsOneWidget);
      expect(find.text('TOPIC BREAKDOWN'), findsNothing,
          reason: 'no answered question means no real breakdown data to '
              'show — an empty list here would be a placeholder, not a '
              'fact');
      expect(find.textContaining('Strongest area'), findsNothing);
      expect(find.textContaining('Weakest area'), findsNothing);
    });
  });

  group('strongest and weakest area (PREP-463)', () {
    testWidgets(
        'identifies the real best- and worst-scoring topics from the '
        'actual session, across 2+ distinct topics', (tester) async {
      // Two real, distinct topics — the demo fixtures used elsewhere in
      // this file all share one topicId, so they can never exercise this
      // comparison; DebugDemoEnvironment's own "no DateTime.now()"
      // determinism contract doesn't apply here since this is
      // hand-built, not one of its documented fixtures.
      final questions = [
        _question(id: 'q1', topicId: 'topic_strong', correctAnswerId: 'a'),
        _question(id: 'q2', topicId: 'topic_strong', correctAnswerId: 'a'),
        _question(id: 'q3', topicId: 'topic_weak', correctAnswerId: 'a'),
        _question(id: 'q4', topicId: 'topic_weak', correctAnswerId: 'a'),
      ];
      final session = PracticeSession(
        id: 'strongest-weakest-test-session',
        examId: DebugDemoEnvironment.demoExamId,
        mode: PracticeMode.quickPractice,
        questionIds: questions.map((q) => q.id).toList(),
        status: SessionStatus.inProgress,
        startedAt: DateTime.utc(2026, 1, 1),
      );
      final controller = PracticeSessionController(
        session: session,
        questions: questions,
        now: () => DateTime.utc(2026, 1, 1, 0, 10),
      );
      // topic_strong: 2/2 correct (100%); topic_weak: 1/2 correct (50%).
      controller.moveTo(0);
      await controller.submitAnswer('a');
      controller.moveTo(1);
      await controller.submitAnswer('a');
      controller.moveTo(2);
      await controller.submitAnswer('a');
      controller.moveTo(3);
      await controller.submitAnswer('b');
      await controller.complete();

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const PracticeSummaryScreen(),
      )));

      expect(find.textContaining('Strongest area: topic_strong (100%)'),
          findsOneWidget);
      expect(find.textContaining('Weakest area: topic_weak (50%)'),
          findsOneWidget);
    });

    testWidgets(
        'is not shown when the session only covers a single topic — '
        'nothing real to compare it against', (tester) async {
      final controller = buildDemoPracticeSessionController();
      // Every DebugDemoEnvironment.demoQuestions shares one topicId.
      controller.moveTo(0);
      await controller
          .submitAnswer(DebugDemoEnvironment.demoQuestions[0].correctAnswerId);
      await controller.complete();

      await tester.pumpWidget(wrap(PracticeSessionScope(
        controller: controller,
        child: const PracticeSummaryScreen(),
      )));

      expect(find.textContaining('Strongest area'), findsNothing);
      expect(find.textContaining('Weakest area'), findsNothing);
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
