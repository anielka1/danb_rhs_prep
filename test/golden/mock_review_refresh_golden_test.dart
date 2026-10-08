import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/screens/mock_exam_answer_review_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_question_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import '../support/mock_exam_test_support.dart';
import '../support/golden_probe.dart';

void main() {
  for (final dark in [false, true]) {
    for (final scale in GoldenTextScale.values) {
      testWidgets('mock review colors dark=$dark scale=$scale', (tester) async {
        final controller = await startedMock();
        await controller.answer(controller.currentQuestion.answers
            .firstWhere(
                (a) => a.id != controller.currentQuestion.correctAnswerId)
            .id);
        await controller.finish();
        await pumpGolden(
            tester,
            Builder(
              builder: (context) => MediaQuery(
                data:
                    MediaQuery.of(context).copyWith(size: const Size(375, 667)),
                child: MockExamAnswerReviewScreen(result: controller.result),
              ),
            ),
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            textScale: scale);
        await tester.ensureVisible(find.text('Your answer'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Next answer').hitTestable(), findsOneWidget);
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(goldenPath(
                screen: 'mock_review',
                brightness: dark ? Brightness.dark : Brightness.light,
                textScale: scale)));
      });
    }
    testWidgets('mock navigator mixed order dark=$dark', (tester) async {
      final controller = await startedMock();
      await controller.answer(controller.currentQuestion.correctAnswerId);
      await pumpGolden(tester, MockExamQuestionScreen(controller: controller),
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          textScale: GoldenTextScale.normal);
      await tester.ensureVisible(find.text('Show question navigator'));
      await tester.tap(find.text('Show question navigator'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Finish mock exam'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(goldenPath(
              screen: 'mock_navigator',
              brightness: dark ? Brightness.dark : Brightness.light,
              textScale: GoldenTextScale.normal)));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
