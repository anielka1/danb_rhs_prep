import 'dart:math';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_controller.dart';
import 'package:danb_rhs_prep/progress/learning_progress.dart';
import 'package:danb_rhs_prep/progress/topic_completion.dart';
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
}
