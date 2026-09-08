import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/experience_level.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/answer_explanation_screen.dart';
import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_results_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/screens/progress_screen.dart';
import 'package:danb_rhs_prep/screens/welcome_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

import '../support/golden_probe.dart';

/// Golden coverage for the 8 screens PREP-658 names — onboarding, Home,
/// Practice, feedback, Summary, Mock result, Progress, Settings — each
/// under light/dark x normal/AX5 text (see `golden_probe.dart` for what
/// "controlled" means on the font/locale/device/motion axes this file
/// doesn't itself vary).
///
/// Screen -> ticket-name mapping, and the one representative, meaningful
/// state golden-tested for each (not every success/empty/error
/// permutation — that matrix already has dedicated, more targeted
/// regression coverage of its own: `test/widgets/*_state_test.dart`,
/// `disabled_controls_test.dart`, and each screen's own widget tests.
/// This file's job is catching an *unintended visual* change — spacing,
/// color, alignment — in the shape those tests can't see, not
/// re-proving business logic they already do):
///   - onboarding    -> WelcomeScreen (the onboarding flow's entry point)
///   - Home          -> HomeScreen, with a resumable session ("Continue")
///   - Practice      -> PracticeQuestionScreen, first question unanswered
///   - feedback      -> AnswerExplanationScreen, after answering correctly
///   - Summary       -> PracticeSummaryScreen, a completed session
///   - Mock result   -> MockExamResultsScreen, a finished attempt
///   - Progress      -> ProgressScreen, with real recorded history
///   - Settings      -> ProfileSettingsScreen
///
/// See `test/golden/README.md` for the golden-update procedure.
void main() {
  late PracticeSessionController unansweredController;
  late PracticeSessionController answeredController;
  late PracticeSessionController completedController;
  late MockExamController finishedMockController;

  setUpAll(() async {
    final List<Question> questions = DebugDemoEnvironment.demoQuestions;

    final PracticeSession unansweredSession = PracticeSession(
      id: 'golden-practice-unanswered',
      examId: DebugDemoEnvironment.demoExamId,
      mode: PracticeMode.quickPractice,
      questionIds: [for (final q in questions) q.id],
      status: SessionStatus.inProgress,
      startedAt: DateTime.utc(2026, 1, 1, 9),
    );
    unansweredController = PracticeSessionController(
      session: unansweredSession,
      questions: DebugDemoEnvironment.demoQuestions,
      now: () => DateTime.utc(2026, 1, 1, 9, 1),
    );

    final PracticeSession answeredSession = PracticeSession(
      id: 'golden-practice-answered',
      examId: DebugDemoEnvironment.demoExamId,
      mode: PracticeMode.quickPractice,
      questionIds: [for (final q in questions) q.id],
      status: SessionStatus.inProgress,
      startedAt: DateTime.utc(2026, 1, 1, 9),
    );
    answeredController = PracticeSessionController(
      session: answeredSession,
      questions: DebugDemoEnvironment.demoQuestions,
      now: () => DateTime.utc(2026, 1, 1, 9, 5),
    );
    await answeredController
        .submitAnswer(DebugDemoEnvironment.demoQuestions.first.correctAnswerId);

    final PracticeSession completedSession = PracticeSession(
      id: 'golden-practice-completed',
      examId: DebugDemoEnvironment.demoExamId,
      mode: PracticeMode.quickPractice,
      questionIds: [for (final q in questions) q.id],
      status: SessionStatus.inProgress,
      startedAt: DateTime.utc(2026, 1, 1, 9),
    );
    completedController = PracticeSessionController(
      session: completedSession,
      questions: DebugDemoEnvironment.demoQuestions,
      now: () => DateTime.utc(2026, 1, 1, 9, 10),
    );
    for (var i = 0; i < DebugDemoEnvironment.demoQuestions.length; i++) {
      completedController.moveTo(i);
      await completedController.submitAnswer(i < 3
          ? DebugDemoEnvironment.demoQuestions[i].correctAnswerId
          : DebugDemoEnvironment.demoQuestions[i].answers.last.id);
    }
    await completedController.complete();

    final ContentPackage package = DebugDemoEnvironment.demoContentPackage;
    finishedMockController = MockExamController(
      blueprint: MockExamBlueprint.fromPackage(package),
      repository: InMemoryProgressRepository(),
      now: () => DateTime.utc(2026, 1, 1, 12),
    );
    await finishedMockController.load();
    await finishedMockController.start();
    for (var i = 0; i < finishedMockController.questions.length; i++) {
      if (i != finishedMockController.currentIndex) {
        await finishedMockController.moveTo(i);
      }
      await finishedMockController
          .answer(finishedMockController.questions[i].correctAnswerId);
    }
    await finishedMockController.finish();
  });

  Widget withBootstrapSession({
    required Widget child,
    bool onboardingComplete = true,
  }) {
    return BootstrapSessionScope(
      controller: BootstrapSessionController(BootstrapReady(
        selectedExamId: DebugDemoEnvironment.demoExamId,
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        profile: null,
        themePreference: ThemePreference.system,
        readinessSnapshot: null,
        entitlement: Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1)),
        onboardingComplete: onboardingComplete,
        examDateSelection: null,
        experienceLevel: null,
      )),
      child: child,
    );
  }

  final Map<String, Widget Function()> screens = {
    'onboarding_welcome': () => withBootstrapSession(
          onboardingComplete: false,
          child: WelcomeScreen(localStore: InMemoryBootstrapLocalStore()),
        ),
    // MainShell always wraps HomeScreen in an ambient BootstrapSessionScope
    // in the real app; HomeScreen reads it directly (for the selected exam
    // id) whenever a progressRepository is present, so this golden needs
    // the same ancestor rather than HomeScreen in isolation.
    'home': () => withBootstrapSession(
          child: HomeScreen(
            progressRepository: DebugDemoEnvironment.buildProgressRepository(),
            now: () => DateTime.utc(2026, 1, 7, 9),
          ),
        ),
    'practice_question': () => PracticeSessionScope(
          controller: unansweredController,
          child: const PracticeQuestionScreen(),
        ),
    'feedback_answer_explanation': () => PracticeSessionScope(
          controller: answeredController,
          child: const AnswerExplanationScreen(),
        ),
    'summary': () => PracticeSessionScope(
          controller: completedController,
          child: const PracticeSummaryScreen(),
        ),
    'mock_result': () =>
        MockExamResultsScreen(result: finishedMockController.result),
    'progress': () => ProgressScreen(
          contentPackage: DebugDemoEnvironment.demoContentPackage,
          progressRepository: InMemoryProgressRepository(
            seedQuestionStates: DebugDemoEnvironment.demoQuestionStates,
            seedMockAttempts: [DebugDemoEnvironment.demoMockAttempt],
            seedReadinessSnapshots: [
              DebugDemoEnvironment.demoReadinessSnapshot
            ],
          ),
        ),
    'settings': () => withBootstrapSession(child: Builder(builder: (context) {
          final session = BootstrapSessionScope.controllerOf(context);
          session.update(session.snapshot.copyWith(
            examDateSelection: ExamDateSelection(
                precision: ExamDatePrecision.oneToThreeMonths),
            experienceLevel: ExperienceLevel.studyingAlready,
          ));
          return ProfileSettingsScreen(
              themeModeController: ThemeModeController(),
              session: session,
              localStore: InMemoryBootstrapLocalStore());
        })),
  };

  for (final entry in screens.entries) {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      for (final textScale in GoldenTextScale.values) {
        testWidgets('${entry.key} ${theme.brightness.name} ${textScale.label}',
            (tester) async {
          await pumpGolden(tester, entry.value(),
              theme: theme, textScale: textScale);

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(goldenPath(
              screen: entry.key,
              brightness: theme.brightness,
              textScale: textScale,
            )),
          );
        });
      }
    }
  }
}
