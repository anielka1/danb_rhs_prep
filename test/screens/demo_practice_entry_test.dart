import 'package:danb_rhs_prep/main_demo.dart' as demo;
import 'package:danb_rhs_prep/main_demo_practice.dart' as quick_demo;
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/widgets/answer_option_tile.dart';
import 'package:danb_rhs_prep/widgets/app_bottom_navigation.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tap(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('demo entrypoint opens fresh Practice and allows answering',
      (tester) async {
    quick_demo.main();
    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);
    expect(
        tester
            .widget<AppBottomNavigation>(find.byType(AppBottomNavigation))
            .current,
        AppTab.practice);
    expect(find.text('Start Preparing'), findsNothing);
    await tap(tester, 'Start Practice Exam');
    expect(find.byType(PracticeQuestionScreen), findsOneWidget);
    final controller = PracticeSessionScope.of(
        tester.element(find.byType(PracticeQuestionScreen)));
    expect(controller.currentQuestion.questionText, startsWith('[Demo]'));
    await tester.tap(find.byType(AnswerOptionTile).first);
    await tester.pumpAndSettle();
    await tap(tester, 'Submit Answer');
    expect(find.text('Explanation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new quick demo run has no previous progress', (tester) async {
    await tester.pumpWidget(demo.createDebugDemoApp(startInPractice: true));
    await tester.pumpAndSettle();
    await tap(tester, 'Start Practice Exam');
    final controller = PracticeSessionScope.of(
        tester.element(find.byType(PracticeQuestionScreen)));
    await tester.tap(find.byType(AnswerOptionTile).first);
    await tester.pumpAndSettle();
    await tap(tester, 'Submit Answer');
    final oldId = controller.session.id;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(demo.createDebugDemoApp(startInPractice: true));
    await tester.pumpAndSettle();
    await tap(tester, 'Start Practice Exam');
    final fresh = PracticeSessionScope.of(
        tester.element(find.byType(PracticeQuestionScreen)));
    expect(fresh.session.id, isNot(oldId));
    expect(fresh.answeredCount, 0);
    expect(tester.takeException(), isNull);
  });
}
