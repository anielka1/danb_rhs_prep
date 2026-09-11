import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_controller.dart';
import '../study_plan/fixtures.dart';
import '../support/controlled_random.dart';
import '../support/mock_exam_test_support.dart';

class CommitThenFailRepository extends InMemoryProgressRepository {
  bool fail = true;
  @override
  Future<void> saveMockAttempt(MockAttempt attempt) async {
    await super.saveMockAttempt(attempt);
    if (fail) {
      fail = false;
      throw StateError('Response lost');
    }
  }
}

void main() {
  final package = fixture();
  test(
      'exact domain quotas, unique approved IDs, least exposure then controlled ties',
      () {
    final stable = MockExamBlueprint.fromPackage(package);
    final counts = {for (final q in stable.questions) q.id: 3};
    final rotated = MockExamBlueprint.fromPackage(package,
        exposureCounts: counts, random: ControlledRandom(rotate: true));
    expect(rotated.questions.length, package.exam.mockExam.questionCount);
    expect(rotated.questions.map((q) => q.id).toSet().length,
        rotated.questions.length);
    for (final e in stable.quotas.entries) {
      expect(
          rotated.questions.where((q) => q.domainId == e.key).length, e.value);
    }
    expect(
        rotated.questions
            .every((q) => q.isApproved && !counts.containsKey(q.id)),
        isTrue);
    final repeat = MockExamBlueprint.fromPackage(package,
        exposureCounts: counts, random: ControlledRandom(rotate: true));
    expect(
        rotated.questions.map((q) => q.id), repeat.questions.map((q) => q.id));
    final otherTie = MockExamBlueprint.fromPackage(package,
        exposureCounts: counts, random: ControlledRandom());
    expect(rotated.questions.map((q) => q.id).toList(),
        isNot(otherTie.questions.map((q) => q.id).toList()));
  });
  test('reserve precedes exposure ranking without changing quotas', () {
    final initial = MockExamBlueprint.fromPackage(package);
    final reserved = initial.questions.map((q) => q.id).toSet();
    final result = MockExamBlueprint.fromPackage(package,
        preferredQuestionIds: reserved,
        exposureCounts: {for (final id in reserved) id: 20},
        random: ControlledRandom(rotate: true));
    expect(result.questions.map((q) => q.id).toSet(), reserved);
    expect(result.quotas, initial.quotas);
  });
  test(
      'new exam rotates away from previous unanswered sets and practice exposure',
      () async {
    final repo = InMemoryProgressRepository();
    final bp = MockExamBlueprint.fromPackage(package);
    final c = MockExamController(
        blueprint: bp, repository: repo, random: ControlledRandom());
    await c.load();
    await c.start();
    final first = c.attempt!;
    await c.finish();
    // One otherwise unseen candidate was answered in ordinary practice.
    final practiced =
        package.questions.firstWhere((q) => !first.questionIds.contains(q.id));
    await repo
        .recordAnswerAttempt(answer(practiced, DateTime.utc(2026, 9, 11)));
    await c.start();
    expect(
        c.attempt!.questionIds.toSet().intersection(first.questionIds.toSet()),
        isEmpty);
    expect(c.attempt!.questionIds, isNot(contains(practiced.id)));
    expect(c.attempt!.seenBeforeStartCount, 0);
  });
  test(
      'small pool reuses least exposed candidates, never duplicates within an exam',
      () async {
    final bp = MockExamBlueprint.fromPackage(mockPackage());
    final repo = InMemoryProgressRepository();
    final c = MockExamController(
        blueprint: bp,
        repository: repo,
        random: ControlledRandom(rotate: true));
    await c.load();
    await c.start();
    final first = c.attempt!.questionIds.toSet();
    for (var i = 0; i < 3; i++) {
      await c.finish();
      await c.start();
      expect(c.attempt!.questionIds.toSet(), first);
      expect(c.attempt!.questionIds, hasLength(first.length));
    }
    final counts = {
      for (var i = 0; i < bp.questions.length; i++) bp.questions[i].id: i + 1
    };
    final subset = MockExamBlueprint.fromPackage(mockPackage(count: 3),
        exposureCounts: counts, random: ControlledRandom(rotate: true));
    expect(subset.questions.map((q) => q.id).toSet(),
        bp.questions.take(3).map((q) => q.id).toSet());
  });
  test(
      'persisted-before-error start retries the same exam without consuming randomness',
      () async {
    final repo = CommitThenFailRepository();
    final bp = MockExamBlueprint.fromPackage(mockPackage());
    final c = MockExamController(
        blueprint: bp,
        repository: repo,
        random: ControlledRandom(rotate: true));
    await c.load();
    await expectLater(c.start(), throwsStateError);
    expect(c.attempt, isNull);
    final saved = (await repo.mockAttemptsForExam(bp.package.exam.id)).single;
    await c.start();
    expect(c.attempt, saved);
    final restored = MockExamController(
        blueprint: bp,
        repository: repo,
        random: ControlledRandom(forbid: true));
    await restored.load();
    await restored.start();
    expect(restored.attempt, saved);
    expect(await repo.mockAttemptsForExam(bp.package.exam.id), hasLength(1));
    for (var i = 0; i < restored.questions.length; i++) {
      if (i > 0) await restored.moveTo(i);
      final q = restored.currentQuestion;
      expect(q.answers.last.id, q.correctAnswerId);
      await restored.answer(q.correctAnswerId);
    }
    await restored.finish();
    expect(restored.result.attempt.correctCount, restored.questions.length);
    expect(restored.result.questions.first.answers.map((a) => a.id),
        restored.questions.first.answers.map((a) => a.id));
  });
  test('failed write before commit exposes no exam, retry creates one',
      () async {
    final repo = ControlledMockRepository()..failSave = true;
    final c = MockExamController(
        blueprint: MockExamBlueprint.fromPackage(mockPackage()),
        repository: repo,
        random: ControlledRandom());
    await c.load();
    await expectLater(c.start(), throwsStateError);
    expect(c.attempt, isNull);
    expect(await repo.mockAttemptsForExam('demo_exam'), isEmpty);
    repo.failSave = false;
    await c.start();
    expect(await repo.mockAttemptsForExam('demo_exam'), hasLength(1));
  });
}
