import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import '../study_plan/fixtures.dart';

class FlakyProgress extends InMemoryProgressRepository {
  bool fail = false;
  @override
  Future<List<QuestionState>> questionStatesForExam(String id) {
    if (fail) throw StateError('unreadable');
    return super.questionStatesForExam(id);
  }
}

void main() {
  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  for (final count in [4, 40]) {
    testWidgets(
        'mixed practice selects up to ten from $count, no clock or summary time',
        (tester) async {
      final package = fixture(count: count);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExamOverviewScreen(
              contentPackage: package,
              progressRepository: InMemoryProgressRepository(),
              launch: PracticeLaunch.random,
              autoStart: true,
              random: Random(4))));
      await tester.pumpAndSettle();
      final controller = PracticeSessionScope.of(
          tester.element(find.byType(PracticeQuestionScreen)));
      expect(controller.totalQuestions, min(10, count));
      expect(
          controller.questions.map((q) => q.id).toSet().length, min(10, count));
      expect(controller.questions.map((q) => q.domainId).toSet().length, 3);
      expect(controller.session.answerOrder, isNotNull);
      expect(find.byIcon(Icons.access_time_rounded), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('00:05'), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: PracticeSessionScope(
              controller: controller, child: const PracticeSummaryScreen())));
      await tester.pumpAndSettle();
      expect(find.text('Elapsed since start'), findsNothing);
      expect(find.text('<1m'), findsNothing);
      expect(find.textContaining('Elapsed time'), findsNothing);
    });
  }

  testWidgets(
      'groups, persistent completion, empty topics and unfinished selection',
      (tester) async {
    final package = fixture(count: 12);
    final repo = InMemoryProgressRepository();
    final completeId = package.questions.first.topicId;
    final partialTopic = package.questions[4].topicId;
    Future<void> answerQuestion(String id) => repo.saveQuestionState(
        QuestionState.unseen(examId: package.exam.id, questionId: id)
            .withAttempt(isCorrect: false, answeredAt: DateTime.utc(2026)));
    for (final q in package.questions.where((q) => q.topicId == completeId)) {
      await answerQuestion(q.id);
    }
    await answerQuestion(package.questions[4].id);
    Widget app() => MaterialApp(
        theme: AppTheme.lightTheme,
        home: ExamOverviewScreen(
            contentPackage: package,
            progressRepository: repo,
            launch: PracticeLaunch.topic,
            random: Random(7)));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    for (final domain in package.exam.domains) {
      expect(find.text(domain.name), findsOneWidget);
    }
    expect(find.textContaining('2 of 2 completed · Completed'), findsOneWidget);
    expect(
        find.textContaining('1 of 2 completed · In progress'), findsOneWidget);
    expect(find.textContaining('Not started'), findsWidgets);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('No approved questions'), findsWidgets);
    final empty = tester.widgetList<ListTile>(find.byType(ListTile)).where(
        (tile) => (tile.subtitle as Text).data == 'No approved questions');
    expect(empty.every((tile) => tile.onTap == null), true);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.textContaining('2 of 2 completed · Completed'), findsOneWidget);
    await tap(tester, 'Practice unfinished topics');
    final controller = PracticeSessionScope.of(
        tester.element(find.byType(PracticeQuestionScreen)));
    expect(controller.questions.every((q) => q.topicId != completeId), true);
    expect(controller.totalQuestions, lessThanOrEqualTo(10));
    expect(controller.questions.any((q) => q.topicId == partialTopic), true);
  });

  testWidgets('progress failure is not Not started and retry restores progress',
      (tester) async {
    final repo = FlakyProgress()..fail = true;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: ExamOverviewScreen(
            contentPackage: fixture(count: 12),
            progressRepository: repo,
            launch: PracticeLaunch.topic)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Progress unavailable'), findsWidgets);
    expect(find.textContaining('Not started'), findsNothing);
    repo.fail = false;
    await tap(tester, 'Retry progress');
    expect(find.textContaining('Not started'), findsWidgets);
    expect(find.textContaining('Progress unavailable'), findsNothing);
  });

  testWidgets('returning from session reloads topic states', (tester) async {
    final package = fixture(count: 4);
    final repo = InMemoryProgressRepository();
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: ExamOverviewScreen(
            contentPackage: package,
            progressRepository: repo,
            launch: PracticeLaunch.topic)));
    await tester.pumpAndSettle();
    final topic = package.exam.domains.first.topics.first;
    await tap(tester, topic.name);
    await tap(tester, 'Start Practice by topic');
    for (var i = 0; i < 2; i++) {
      await tap(tester, 'Correct fixture answer');
      await tap(tester, 'Submit Answer');
      await tap(tester, i == 1 ? 'Finish' : 'Next Question');
    }
    expect(find.byType(PracticeSummaryScreen), findsOneWidget);
    expect(find.text('Elapsed since start'), findsNothing);
    await tap(tester, 'Back to topics');
    expect(find.textContaining('2 of 2 completed · Completed'), findsOneWidget);
  });
}
