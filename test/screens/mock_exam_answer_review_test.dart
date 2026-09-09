import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import 'package:danb_rhs_prep/screens/mock_exam_answer_review_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_results_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/mock_exam_test_support.dart';

Future<void> tapText(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'completed review preserves score and covers every answer, dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final blueprint = MockExamBlueprint.fromPackage(mockPackage());
      final questions = blueprint.questions;
      final wrong = questions[1]
          .answers
          .firstWhere((a) => a.id != questions[1].correctAnswerId)
          .id;
      final attempt = MockAttempt(
        id: 'review',
        examId: blueprint.package.exam.id,
        contentVersion: blueprint.package.contentVersion,
        questionIds: questions.map((q) => q.id).toList(),
        answers: {
          questions[0].id: questions[0].correctAnswerId,
          questions[1].id: wrong
        },
        flaggedQuestionIds: {questions[1].id},
        status: MockAttemptStatus.completed,
        startedAt: DateTime.utc(2026),
        completedAt: DateTime.utc(2026, 1, 1, 0, 5),
        correctCount: 1,
        durationMinutes: blueprint.config.durationMinutes,
      );
      final result = blueprint.resultFor(attempt);
      expect(() => result.questions.clear(), throwsUnsupportedError);
      await tester.pumpWidget(MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(4)),
          child: child!,
        ),
        home: Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              MockExamResultsScreen(result: result))),
                  child: const Text('Open result'),
                ))),
      ));
      await tapText(tester, 'Open result');
      await tapText(tester, 'Review answers');
      expect(find.byType(MockExamAnswerReviewScreen), findsOneWidget);
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('Your answer'), findsOneWidget);
      expect(find.text('Correct answer'), findsOneWidget);
      await tapText(tester, 'Next answer');
      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.text('Flagged for review'), findsOneWidget);
      await tapText(tester, 'Next answer');
      expect(find.text('Unanswered'), findsOneWidget);
      expect(find.text('Your answer'), findsNothing);
      expect(find.text('You did not answer this question.'), findsOneWidget);
      await tester.ensureVisible(find.text(questions[2].explanation));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Previous answer');
      expect(find.text('Question 2 of 5'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tapText(tester, 'Next answer');
      }
      expect(find.text('Question 5 of 5'), findsOneWidget);
      expect(find.text('Next answer'), findsNothing);
      await tapText(tester, 'Back to results');
      expect(find.byType(MockExamAnswerReviewScreen), findsNothing);
      expect(find.text('Correct answers: 1 / 5'), findsOneWidget);
      expect(attempt.answers, {
        questions[0].id: questions[0].correctAnswerId,
        questions[1].id: wrong
      });
      expect(attempt.correctCount, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
