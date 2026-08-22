import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

void main() {
  testWidgets('shows an honest "coming soon" placeholder, not fake exam data',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const MockExamScreen(),
    ));

    expect(find.text('Mock Exam'), findsOneWidget);
    expect(find.textContaining('coming soon'), findsOneWidget);
    expect(find.text('View Exam Info'), findsOneWidget);
  });

  testWidgets('"View Exam Info" opens the existing exam overview screen',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      routes: {
        MockExamScreen.route: (_) => const MockExamScreen(),
        ExamOverviewScreen.route: (_) => const ExamOverviewScreen(),
      },
      initialRoute: MockExamScreen.route,
    ));

    await tester.tap(find.text('View Exam Info'));
    await tester.pumpAndSettle();

    expect(find.text('Exam Info'), findsOneWidget);
  });
}
