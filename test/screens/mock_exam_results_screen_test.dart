import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import '../support/mock_exam_test_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/screens/mock_exam_results_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('completed result supports large text, dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final blueprint = MockExamBlueprint.fromPackage(mockPackage());
      final questions = blueprint.questions;
      final result = blueprint.resultFor(MockAttempt(
        id: 'result-layout',
        examId: blueprint.package.exam.id,
        contentVersion: blueprint.package.contentVersion,
        questionIds: questions.map((q) => q.id).toList(),
        answers: {questions.first.id: questions.first.correctAnswerId},
        flaggedQuestionIds: {},
        status: MockAttemptStatus.completed,
        startedAt: DateTime.utc(2026),
        completedAt: DateTime.utc(2026, 1, 1, 0, 5),
        correctCount: 1,
        durationMinutes: blueprint.config.durationMinutes,
      ));
      await tester.pumpWidget(MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(3.12)),
          child: child!,
        ),
        home: MockExamResultsScreen(result: result),
      ));
      await tester.pumpAndSettle();
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('Correct answers: 1 / 5'), findsOneWidget);
      expect(find.text('Below practice threshold'), findsOneWidget);
      expect(find.text('1 questions answered. 4 unanswered.'), findsOneWidget);
      await tester.ensureVisible(find.text(MockExamResult.disclaimer));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('audit: no attempt must never show an invented official result',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const MockExamResultsScreen(),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('PASSED'), findsNothing);
    expect(find.text('82%'), findsNothing);
    expect(find.text('No completed mock exam'), findsOneWidget);
    expect(find.text('Review Answers'), findsNothing);
    expect(find.text('Retake Exam'), findsNothing);
  });
}
