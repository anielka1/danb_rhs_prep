import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_controller.dart';
import '../study_plan/fixtures.dart';

class FailingCompletionRepository extends DriftProgressRepository {
  FailingCompletionRepository(super.db);
  bool failFinalSave = false;
  bool failAfterCommit = false;

  @override
  Future<void> saveMockAttempt(MockAttempt attempt) async {
    if (failFinalSave && attempt.status == MockAttemptStatus.completed) {
      throw StateError('write failure');
    }
    await super.saveMockAttempt(attempt);
  }

  @override
  Future<void> completeMockAttempt(
      MockAttempt attempt, List<AnswerAttempt> answers) async {
    await super.completeMockAttempt(attempt, answers);
    if (failAfterCommit) throw StateError('response lost');
  }
}

void main() {
  for (final afterCommit in [false, true]) {
    test('atomic mock completion and stable retry, afterCommit=$afterCommit',
        () async {
      final dir = await Directory.systemTemp.createTemp('mock-completion-');
      final file = File('${dir.path}/progress.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      final repo = FailingCompletionRepository(db);
      final package = fixture(count: 500);
      var now = DateTime.utc(2026, 10, 7, 12);
      final controller = MockExamController(
          blueprint: MockExamBlueprint.fromPackage(package),
          repository: repo,
          now: () => now,
          random: Random(1));
      await controller.load();
      await controller.start();
      final question = controller.currentQuestion;
      await controller.answer('b');
      await controller.answer(question.correctAnswerId);
      await controller.moveTo(1);
      await controller.answer('b');
      final id = controller.attempt!.id;
      final order = controller.attempt!.answerOrder;
      expect(await repo.answerAttemptsForExam(package.exam.id), isEmpty);
      repo.failFinalSave = !afterCommit;
      repo.failAfterCommit = afterCommit;
      await expectLater(controller.finish(), throwsStateError);
      expect(controller.inProgress, isTrue);
      expect(controller.completionPending, isTrue);
      await expectLater(controller.answer('a'), throwsStateError);
      expect((await repo.answerAttemptsForExam(package.exam.id)).length,
          afterCommit ? 2 : 0);
      expect((await repo.questionStatesForExam(package.exam.id)).length,
          afterCommit ? 2 : 0);
      expect(
          (await repo.mockAttemptsForExam(package.exam.id)).single.status,
          afterCommit
              ? MockAttemptStatus.completed
              : MockAttemptStatus.inProgress);
      now = now.add(const Duration(minutes: 5));
      repo.failFinalSave = false;
      repo.failAfterCommit = false;
      await controller.finish();
      expect(controller.completionPending, isFalse);
      expect(controller.attempt!.correctCount, 1);
      expect(controller.attempt!.answerOrder, order);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      final reopened = DriftProgressRepository(db);
      final answers = await reopened.answerAttemptsForExam(package.exam.id);
      final states = await reopened.questionStatesForExam(package.exam.id);
      final saved =
          (await reopened.mockAttemptsForExam(package.exam.id)).single;
      expect(saved.id, id);
      expect(saved.status, MockAttemptStatus.completed);
      expect(saved.correctCount, 1);
      expect(saved.answerOrder, order);
      expect(answers.length, 2);
      expect(states.length, 2); // Unanswered questions are not completed.
      expect(states.every((s) => s.timesSeen == 1), isTrue);
      final correct = answers.singleWhere((a) => a.questionId == question.id);
      expect(correct.isCorrect, isTrue);
      expect(correct.sessionType, AttemptSessionType.mock);
      expect(correct.correctAnswerId, question.correctAnswerId);
      expect(correct.explanation, question.explanation);
      expect(correct.questionVersion, question.version);
      expect(correct.contentVersion, package.contentVersion);
      expect(correct.activeDurationSeconds, isNull);
      expect(correct.answeredAt, DateTime.utc(2026, 10, 7, 12));
      expect(saved.completedAt, correct.answeredAt);
    });
  }

  test('loading a legacy completed mock does not invent graded history',
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
    final legacy = controller.attempt!.copyWith(
        status: MockAttemptStatus.completed,
        correctCount: 1,
        completedAt: DateTime.utc(2026, 10, 7));
    await repo.saveMockAttempt(legacy);
    final restarted = MockExamController(
        blueprint: MockExamBlueprint.fromPackage(package), repository: repo);
    await restarted.load();
    expect(await repo.answerAttemptsForExam(package.exam.id), isEmpty);
    expect(await repo.questionStatesForExam(package.exam.id), isEmpty);
    expect((await repo.mockAttemptsForExam(package.exam.id)).single, legacy);
  });
}
