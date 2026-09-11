import '../study_plan/onboarding_helper.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/main_demo.dart' as demo;
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/mock_exam_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_question_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_results_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/answer_option_tile.dart';
import 'package:danb_rhs_prep/widgets/loading_state.dart';
import '../support/mock_exam_test_support.dart';

Future<void> tapText(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget app(ControlledMockRepository repo,
        {ThemeData? theme, double scale = 1}) =>
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale), disableAnimations: true),
          child: child!),
      home: MockExamScreen(
          contentPackage: mockPackage(),
          progressRepository: repo,
          now: () => DateTime.utc(2026, 1, 1, 12)),
    );

Future<void> begin(WidgetTester tester, ControlledMockRepository repo) async {
  await tester.pumpWidget(app(repo));
  await tester.pumpAndSettle();
  await tapText(tester, 'Start Mock Exam');
  expect(find.text('Mock Exam Instructions'), findsOneWidget);
  expect(find.text('Untimed exam.'), findsOneWidget);
  expect(find.text(MockExamResult.disclaimer), findsOneWidget);
  await tapText(tester, 'Begin exam');
  expect(find.byType(MockExamQuestionScreen), findsOneWidget);
}

void main() {
  testWidgets(
      'E2E: instructions, answers, flags, navigator, cancel/confirm finish, result, retake',
      (tester) async {
    final semantics = tester.ensureSemantics();

    final repo = ControlledMockRepository();
    await begin(tester, repo);
    final controller = tester
        .widget<MockExamQuestionScreen>(find.byType(MockExamQuestionScreen))
        .controller;
    expect(find.text('Question 1 of 5'), findsOneWidget);
    expect(find.textContaining('correct answer'), findsNothing);
    await tester.tap(find.byType(AnswerOptionTile).at(
        controller.currentQuestion.answers.indexWhere(
            (a) => a.id == controller.currentQuestion.correctAnswerId)));
    await tester.pumpAndSettle();
    await tapText(tester, 'Flag question');
    expect(controller.attempt!.flaggedQuestionIds,
        {controller.questions.first.id});
    expect(find.bySemanticsLabel('Question 3, unanswered'), findsNothing);
    await tapText(tester, 'Show question navigator');
    final jump = find.bySemanticsLabel('Question 3, unanswered');
    await tester.ensureVisible(jump);
    await tester.tap(jump);
    await tester.pumpAndSettle();
    expect(find.text('Question 3 of 5'), findsOneWidget);
    expect(find.text('Show question navigator'), findsOneWidget);
    expect(
        find.bySemanticsLabel('Question 3, current, unanswered'), findsNothing);
    await tapText(tester, 'Previous question');
    expect(find.text('Question 2 of 5'), findsOneWidget);
    for (var i = 1; i < 5; i++) {
      final choice = find.byType(AnswerOptionTile).at(
          controller.currentQuestion.answers.indexWhere((a) => i == 4
              ? a.id != controller.currentQuestion.correctAnswerId
              : a.id == controller.currentQuestion.correctAnswerId));
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      if (i < 4) await tapText(tester, 'Next question');
    }
    await tapText(tester, 'Finish mock exam');
    expect(find.textContaining('0 unanswered questions'), findsOneWidget);
    await tapText(tester, 'Keep answering');
    expect(controller.inProgress, isTrue);
    await tapText(tester, 'Finish mock exam');
    await tapText(tester, 'Finish exam');
    expect(find.text('Above practice threshold'), findsOneWidget);
    expect(find.text('Correct answers: 4 / 5'), findsOneWidget);
    expect(find.text('PASSED'), findsNothing);
    expect(find.text(MockExamResult.disclaimer), findsOneWidget);
    expect((await repo.mockAttempt(controller.attempt!.id))!.status,
        MockAttemptStatus.completed);
    await tapText(tester, 'Back to Mock Exam');
    expect(find.text('Start Mock Exam'), findsOneWidget);
    await tapText(tester, 'Start Mock Exam');
    await tapText(tester, 'Begin exam');
    expect(find.text('0 answered · 0 flagged'), findsOneWidget);
    expect(await repo.mockAttemptsForExam('demo_exam'), hasLength(2));
    semantics.dispose();
  });

  testWidgets('unfinished questions warn before a below-threshold result',
      (tester) async {
    final repo = ControlledMockRepository();
    await begin(tester, repo);
    await tapText(tester, 'Finish mock exam');
    expect(find.textContaining('5 unanswered questions'), findsOneWidget);
    await tapText(tester, 'Finish exam');
    expect(find.text('Below practice threshold'), findsOneWidget);
    expect(find.text('Correct answers: 0 / 5'), findsOneWidget);
  });

  testWidgets(
      'save failure is visible and retry persists the originally selected answer',
      (tester) async {
    final repo = ControlledMockRepository();
    await begin(tester, repo);
    repo.failSave = true;
    await tester.tap(find.byType(AnswerOptionTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Could not save this change'), findsOneWidget);
    expect(find.textContaining('private storage diagnostic'), findsNothing);
    final controller = tester
        .widget<MockExamQuestionScreen>(find.byType(MockExamQuestionScreen))
        .controller;
    expect(controller.attempt!.answers, isEmpty);
    repo.failSave = false;
    await tapText(tester, 'Try Again');
    expect(controller.attempt!.answeredCount, 1);
  });

  testWidgets(
      'failed completion cannot display a result; retry finishes exactly once',
      (tester) async {
    final repo = ControlledMockRepository();
    await begin(tester, repo);
    repo.failSave = true;
    await tapText(tester, 'Finish mock exam');
    await tapText(tester, 'Finish exam');
    expect(find.byType(MockExamResultsScreen), findsNothing);
    repo.failSave = false;
    await tapText(tester, 'Try Again');
    expect(find.text('Below practice threshold'), findsOneWidget);
    expect(await repo.mockAttemptsForExam('demo_exam'), hasLength(1));
  });

  testWidgets('loading, load error and retry keep private errors out of the UI',
      (tester) async {
    final repo = ControlledMockRepository()..loadGate = Completer<void>();
    await tester.pumpWidget(app(repo));
    await tester.pump();
    expect(find.byType(LoadingState), findsOneWidget);
    expect(find.text('Start Mock Exam'), findsNothing);
    repo.failLoad = true;
    repo.loadGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Could not load your mock exam'), findsOneWidget);
    expect(find.textContaining('private storage diagnostic'), findsNothing);
    repo.failLoad = false;
    await tapText(tester, 'Try Again');
    expect(find.text('Start Mock Exam'), findsOneWidget);
  });

  testWidgets('pending answer save blocks exit and additional actions',
      (tester) async {
    final repo = ControlledMockRepository();
    await begin(tester, repo);
    repo.saveGate = Completer<void>();
    await tester.tap(find.byType(AnswerOptionTile).first);
    await tester.pump();
    expect(find.text('Saving exam'), findsOneWidget);
    expect(find.byType(AnswerOptionTile), findsNothing);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pump();
    expect(find.byType(MockExamQuestionScreen), findsOneWidget);
    repo.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('1 answered · 0 flagged'), findsOneWidget);
  });

  testWidgets(
      'exit and recreated UI resume saved position and flags with no network',
      (tester) async {
    final semantics = tester.ensureSemantics();

    final repo = ControlledMockRepository();
    await begin(tester, repo);
    await tapText(tester, 'Flag question');
    await tapText(tester, 'Next question');
    await tester.tap(find.bySemanticsLabel('Exit exam'));
    await tester.pumpAndSettle();
    expect(find.text('Resume Mock Exam'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tapText(tester, 'Resume Mock Exam');
    await tapText(tester, 'Resume exam');
    expect(find.text('Question 2 of 5'), findsOneWidget);
    expect(find.text('0 answered · 1 flagged'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('real demo composition reaches mock after accountless onboarding',
      (tester) async {
    await tester.pumpWidget(demo.createDebugDemoApp());
    await tester.pumpAndSettle();
    await tapText(tester, 'Start Preparing');
    await tapText(tester, "I haven't scheduled it yet");
    await tapText(tester, 'Continue');
    await tapText(tester, 'Just starting');
    await tapText(tester, 'Continue');
    await selectAvailability(tester);
    expect(find.byType(MainShell), findsOneWidget);
    await tapText(tester, 'Mock Exam');
    await tapText(tester, 'Start Mock Exam');
    await tapText(tester, 'Begin exam');
    await tapText(tester, 'Finish mock exam');
    await tapText(tester, 'Finish exam');
    expect(find.text('Below practice threshold'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 4.0]) {
      testWidgets(
          'semantics, 44pt targets and scrollable flow: dark=$dark scale=$scale',
          (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();

        final repo = ControlledMockRepository();
        await tester.pumpWidget(app(repo,
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            scale: scale));
        await tester.pumpAndSettle();
        await tapText(tester, 'Start Mock Exam');
        await tapText(tester, 'Begin exam');
        final answer = find.byType(AnswerOptionTile).first;
        await tester.ensureVisible(answer);
        expect(tester.getSize(answer).height, greaterThanOrEqualTo(44));
        await tester.tap(answer);
        await tester.pumpAndSettle();
        final text = tester.widget<AnswerOptionTile>(answer).text;
        expect(
            find.bySemanticsLabel('Option A: $text, selected'), findsOneWidget);
        await tapText(tester, 'Flag question');
        expect(find.text('Remove flag'), findsOneWidget);
        await tapText(tester, 'Finish mock exam');
        await tapText(tester, 'Finish exam');
        await tester.ensureVisible(find.text(MockExamResult.disclaimer));
        expect(find.text(MockExamResult.disclaimer), findsOneWidget);
        semantics.dispose();
      });
    }
  }
}
