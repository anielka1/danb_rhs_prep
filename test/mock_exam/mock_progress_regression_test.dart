import 'dart:math';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_controller.dart';
import 'package:danb_rhs_prep/progress/learning_progress.dart';
import 'package:danb_rhs_prep/progress/topic_completion.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import '../study_plan/fixtures.dart';

void main() {
  for (final checkTopics in [false, true]) {
    test(
        'new completed mock feeds ${checkTopics ? 'topic completion' : 'latest grades and review mistakes'}',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftProgressRepository(db);
      final package = fixture(count: 500);
      final controller = MockExamController(
          blueprint: MockExamBlueprint.fromPackage(package),
          repository: repo,
          now: () => DateTime.utc(2026, 10, 7),
          random: Random(1));
      await controller.load();
      await controller.start();
      await controller.answer('a');
      await controller.moveTo(1);
      final wrongId = controller.currentQuestion.id;
      await controller.answer('b');
      await controller.finish();
      final states = await repo.questionStatesForExam(package.exam.id);
      final attempts = await repo.answerAttemptsForExam(package.exam.id);
      final progress = LearningProgress.fromHistory(
          package: package,
          attempts: attempts,
          mocks: await repo.mockAttemptsForExam(package.exam.id));
      final completion = TopicCompletion(package, states);
      if (checkTopics) {
        expect(completion.completed.values.fold(0, (a, b) => a + b), 2);
      } else {
        expect(progress.incorrectIds, contains(wrongId));
        expect(progress.total.correct, 1);
        expect(progress.total.needsReview, 1);
        expect(progress.total.gradeUnavailable, 0);
        expect(attempts.length, 2);
        expect(states.every((s) => s.timesSeen == 1), isTrue);
      }
    });
  }
  testWidgets('X ends a topic session both directly and after Continue',
      (tester) async {
    final package = fixture(count: 40);
    final repo = InMemoryProgressRepository();
    Future<void> tap(String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    Future<String> startTopic() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExamOverviewScreen(
              contentPackage: package,
              progressRepository: repo,
              launch: PracticeLaunch.topic)));
      await tester.pumpAndSettle();
      await tap(package.exam.domains.first.topics.first.name);
      await tap('Start Practice by topic');
      return PracticeSessionScope.of(
              tester.element(find.byType(PracticeQuestionScreen)))
          .session
          .id;
    }

    final first = await startTopic();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(
        (await repo.practiceSessionsForExam(package.exam.id))
            .firstWhere((s) => s.id == first)
            .status
            .name,
        'completed');
    final second = await startTopic();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: ExamOverviewScreen(
            contentPackage: package,
            progressRepository: repo,
            autoStart: true)));
    await tester.pumpAndSettle();
    expect(
        PracticeSessionScope.of(
                tester.element(find.byType(PracticeQuestionScreen)))
            .session
            .id,
        second);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(
        (await repo.practiceSessionsForExam(package.exam.id))
            .firstWhere((s) => s.id == second)
            .status
            .name,
        'completed');
    expect(await repo.answerAttemptsForExam(package.exam.id), isEmpty);
    expect(await repo.questionStatesForExam(package.exam.id), isEmpty);
  });
}
