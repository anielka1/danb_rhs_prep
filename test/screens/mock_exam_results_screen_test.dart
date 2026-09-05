import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/screens/mock_exam_results_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

void main() {
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
