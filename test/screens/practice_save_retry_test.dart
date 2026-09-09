import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/answer_explanation_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

class _Repository extends InMemoryProgressRepository {
  bool fail = true;
  bool failBookmark = false;
  bool failSession = false;
  PracticeSession? savedSession;
  @override
  Future<void> recordAnswerAttempt(AnswerAttempt attempt) async {
    if (fail) throw StateError('disk unavailable');
    await super.recordAnswerAttempt(attempt);
  }

  @override
  Future<void> saveQuestionState(QuestionState state) async {
    if (failBookmark) throw StateError('disk unavailable');
    await super.saveQuestionState(state);
  }

  @override
  Future<void> savePracticeSession(PracticeSession session) async {
    if (failSession) throw StateError('disk unavailable');
    await super.savePracticeSession(session);
    savedSession = session;
  }
}

PracticeSessionController _buildController(_Repository repo) =>
    PracticeSessionController(
      session: DebugDemoEnvironment.demoInProgressPracticeSession,
      questions: [
        for (final id
            in DebugDemoEnvironment.demoInProgressPracticeSession.questionIds)
          DebugDemoEnvironment.demoQuestions.firstWhere((q) => q.id == id)
      ],
      progressRepository: repo,
    );

void main() {
  Future<void> retry(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Retry saving'));
    await tester.tap(find.text('Retry saving'));
    await tester.pumpAndSettle();
  }

  Widget wrap(PracticeSessionController controller, Widget screen) =>
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: PracticeSessionScope(controller: controller, child: screen),
      );

  testWidgets(
      'bookmark failure remains visible through retry and warns on Close',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3.12;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repo = _Repository()..failBookmark = true;
    final controller = _buildController(repo);
    await tester.pumpWidget(wrap(controller, const PracticeQuestionScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.bySemanticsLabel('Bookmark question'));
    await tester.tap(find.bySemanticsLabel('Bookmark question'));
    await tester.pumpAndSettle();
    expect(find.text('Retry saving'), findsOneWidget);
    await retry(tester);
    expect(find.text('Retry saving'), findsOneWidget);
    await tester.ensureVisible(find.bySemanticsLabel('Close'));
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tester.tap(find.text('Stay here'));
    await tester.pumpAndSettle();
    repo.failBookmark = false;
    await retry(tester);
    expect(find.text('Retry saving'), findsNothing);
    expect(
        (await repo.questionState(
                controller.session.examId, controller.currentQuestion.id))
            .bookmarked,
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary offers retry for an unsaved completed session',
      (tester) async {
    final repo = _Repository()..failSession = true;
    final controller = _buildController(repo);
    await controller.complete();
    final completed = controller.session;
    await tester.pumpWidget(wrap(controller, const PracticeSummaryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Retry saving'), findsOneWidget);
    repo.failSession = false;
    await retry(tester);
    expect(repo.savedSession, completed);
    expect(find.text('Retry saving'), findsNothing);
  });

  testWidgets(
      'a new session whose initial save fails can be saved from its question',
      (tester) async {
    final repo = _Repository()..failSession = true;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: ExamOverviewScreen(
            contentPackage: DebugDemoEnvironment.demoContentPackage,
            progressRepository: repo)));
    await tester.ensureVisible(find.text('Start Practice Exam'));
    await tester.tap(find.text('Start Practice Exam'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeQuestionScreen), findsOneWidget);
    expect(find.text('Retry saving'), findsOneWidget);
    repo.failSession = false;
    await retry(tester);
    expect(repo.savedSession!.status, SessionStatus.inProgress);
    expect(find.text('Retry saving'), findsNothing);
  });
  testWidgets('failed answer save is visible and retry records it once',
      (tester) async {
    final repo = _Repository();
    final controller = PracticeSessionController(
      session: DebugDemoEnvironment.demoInProgressPracticeSession,
      questions: [
        for (final id
            in DebugDemoEnvironment.demoInProgressPracticeSession.questionIds)
          DebugDemoEnvironment.demoQuestions.firstWhere((q) => q.id == id)
      ],
      progressRepository: repo,
    );
    await controller.submitAnswer(controller.currentQuestion.correctAnswerId);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: PracticeSessionScope(
            controller: controller, child: const AnswerExplanationScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Retry saving'), findsOneWidget);
    repo.fail = false;
    await tester.ensureVisible(find.text('Retry saving'));
    await tester.tap(find.text('Retry saving'));
    await tester.pumpAndSettle();
    expect(find.text('Retry saving'), findsNothing);
    final attempts =
        await repo.answerAttemptsForExam(controller.session.examId);
    expect(attempts, hasLength(1));
    expect(controller.correctCount, 1);
  });
}
