import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

class _Repository extends InMemoryProgressRepository {
  bool failHistory = false;
  @override
  Future<List<QuestionState>> questionStatesForExam(String examId) async {
    if (failHistory) throw StateError('storage unavailable');
    return super.questionStatesForExam(examId);
  }
}

void main() {
  Future<void> open(
      WidgetTester tester, InMemoryProgressRepository repo) async {
    var now = DateTime.utc(2026, 9, 8, 20);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: ExamOverviewScreen(
            contentPackage: DebugDemoEnvironment.demoContentPackage,
            progressRepository: repo,
            now: () => now = now.add(const Duration(seconds: 1)))));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  PracticeSessionController controller(WidgetTester tester) =>
      PracticeSessionScope.of(
          tester.element(find.byType(PracticeQuestionScreen)));

  testWidgets(
      'custom selection offers a choice instead of silently resuming old questions',
      (tester) async {
    final old = DebugDemoEnvironment.demoInProgressPracticeSession;
    final repo = InMemoryProgressRepository(seedPracticeSessions: [old]);
    await open(tester, repo);
    await tap(tester, 'My weak areas');
    await tap(tester, 'Start Practice Exam');
    expect(find.text('You have an unfinished session'), findsOneWidget);
    await tap(tester, 'Cancel');
    expect(find.byType(PracticeQuestionScreen), findsNothing);
    expect(await repo.inProgressPracticeSession(old.examId), old);
    await tap(tester, 'Start Practice Exam');
    await tap(tester, 'Resume session');
    expect(controller(tester).session.id, old.id);
  });

  testWidgets('bookmark in practice is available in a new saved-only session',
      (tester) async {
    final repo = InMemoryProgressRepository();
    await open(tester, repo);
    await tap(tester, 'Start Practice Exam');
    final previous = controller(tester).session;
    final savedId = controller(tester).currentQuestion.id;
    await tester.tap(find.bySemanticsLabel('Bookmark question'));
    await tester.pumpAndSettle();
    expect((await repo.questionState(previous.examId, savedId)).bookmarked,
        isTrue);
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    await tap(tester, 'Saved questions');
    await tap(tester, 'Start Practice Exam');
    await tap(tester, 'Start selected practice');
    final selected = controller(tester);
    expect(selected.questions.map((q) => q.id), [savedId]);
    expect(selected.session.mode, PracticeMode.bookmarked);
    await tester.tap(find.bySemanticsLabel('Remove bookmark'));
    await tester.pumpAndSettle();
    expect((await repo.questionState(previous.examId, savedId)).bookmarked,
        isFalse);
    // Complete the newer session: the older one was preserved for later.
    await repo.savePracticeSession(selected.session.copyWith(
        status: SessionStatus.completed,
        completedAt: DateTime.utc(2026, 9, 8, 21)));
    expect((await repo.inProgressPracticeSession(previous.examId))!.id,
        previous.id);
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    await tap(tester, 'Start Practice Exam');
    await tap(tester, 'Start selected practice');
    expect(find.textContaining('No saved questions match'), findsOneWidget);
    expect((await repo.inProgressPracticeSession(previous.examId))!.id,
        previous.id);
  });

  testWidgets(
      'saved focus and resume dialog work with large accessibility text',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3.12;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final old = DebugDemoEnvironment.demoInProgressPracticeSession;
    final repo = InMemoryProgressRepository(seedPracticeSessions: [old]);
    await open(tester, repo);
    await tap(tester, 'Saved questions');
    await tap(tester, 'Start Practice Exam');
    await tap(tester, 'Start selected practice');
    expect(find.textContaining('No saved questions match'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'empty saved selection explains how to save and clears on changing focus',
      (tester) async {
    final repo = InMemoryProgressRepository();
    await open(tester, repo);
    await tap(tester, 'Saved questions');
    await tap(tester, 'Start Practice Exam');
    expect(find.textContaining('No saved questions match'), findsOneWidget);
    expect(find.byType(PracticeQuestionScreen), findsNothing);
    expect(
        await repo.inProgressPracticeSession(DebugDemoEnvironment.demoExamId),
        isNull);
    await tap(tester, 'All questions');
    expect(find.textContaining('No saved questions match'), findsNothing);
    await tap(tester, 'Start Practice Exam');
    expect(find.byType(PracticeQuestionScreen), findsOneWidget);
  });

  testWidgets(
      'bookmark history failure does not start unfiltered practice and can retry',
      (tester) async {
    final repo = _Repository();
    final question = DebugDemoEnvironment.demoQuestions.first;
    await repo.saveQuestionState(
        QuestionState.unseen(examId: question.examId, questionId: question.id)
            .copyWith(bookmarked: true));
    repo.failHistory = true;
    await open(tester, repo);
    await tap(tester, 'Saved questions');
    await tap(tester, 'Start Practice Exam');
    expect(find.textContaining('Could not load your practice history'),
        findsOneWidget);
    expect(find.byType(PracticeQuestionScreen), findsNothing);
    repo.failHistory = false;
    await tap(tester, 'Start Practice Exam');
    expect(controller(tester).questions.map((q) => q.id), [question.id]);
  });
}
