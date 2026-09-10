import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/screens/saved_questions_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

class FlakyRepository extends InMemoryProgressRepository {
  bool fail = true;
  @override
  Future<List<QuestionState>> questionStatesForExam(String examId) async {
    if (fail) {
      fail = false;
      throw StateError('private database details');
    }
    return super.questionStatesForExam(examId);
  }
}

void main() {
  final package = DebugDemoEnvironment.demoContentPackage;
  final question = package.questions.first;
  for (final dark in [false, true]) {
    for (final scale in [1.0, 4.0]) {
      testWidgets('saved answers are read-only dark=$dark scale=$scale',
          (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final state = QuestionState.unseen(
                examId: package.exam.id, questionId: question.id)
            .copyWith(bookmarked: true);
        final repo = InMemoryProgressRepository(seedQuestionStates: [state]);
        await tester.pumpWidget(MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: SavedQuestionsScreen(
              contentPackage: package, progressRepository: repo),
        ));
        await tester.pumpAndSettle();
        expect(find.text(question.questionText), findsOneWidget);
        for (final text in [
          question.correctAnswer!.text,
          question.explanation
        ]) {
          await tester.ensureVisible(find.text(text));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.text(package.questions.last.questionText), findsNothing);
        expect(await repo.questionState(package.exam.id, question.id), state);
        expect(await repo.answerAttemptsForExam(package.exam.id), isEmpty);
        expect(await repo.inProgressPracticeSession(package.exam.id), isNull);
      });
    }
  }
  testWidgets('empty library explains bookmarking', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: SavedQuestionsScreen(
            contentPackage: package,
            progressRepository: InMemoryProgressRepository())));
    await tester.pumpAndSettle();
    expect(find.text('No saved questions yet'), findsOneWidget);
  });
  testWidgets('missing content is reported without discarding bookmarks',
      (tester) async {
    final repo = InMemoryProgressRepository(seedQuestionStates: [
      QuestionState.unseen(examId: package.exam.id, questionId: 'removed')
          .copyWith(bookmarked: true)
    ]);
    await tester.pumpWidget(MaterialApp(
        home: SavedQuestionsScreen(
            contentPackage: package, progressRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('No saved questions available'), findsOneWidget);
    expect((await repo.questionState(package.exam.id, 'removed')).bookmarked,
        isTrue);
  });
  testWidgets('failed load retries and hides internal details', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: SavedQuestionsScreen(
            contentPackage: package, progressRepository: FlakyRepository())));
    await tester.pumpAndSettle();
    expect(find.text('Could not load saved questions'), findsOneWidget);
    expect(find.textContaining('private database'), findsNothing);
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();
    expect(find.text('No saved questions yet'), findsOneWidget);
  });
}
