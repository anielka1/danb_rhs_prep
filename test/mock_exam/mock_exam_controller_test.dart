import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_controller.dart';
import '../support/mock_exam_test_support.dart';

void main() {
  test('deterministic start, answers, flags, navigation, finish and retake',
      () async {
    final first = await startedMock();
    final second = await startedMock();
    expect(first.attempt, second.attempt);
    for (var i = 0; i < 5; i++) {
      if (i != 0) await first.moveTo(i);
      await first.answer(i < 4 ? 'a' : 'b');
    }
    await first.toggleFlag();
    expect(first.attempt!.flaggedQuestionIds, {'demo-question-5'});
    await first.moveTo(0);
    expect(first.attempt!.answers['demo-question-1'], 'a');
    await first.finish();
    expect(first.result.outcome, 'Above practice threshold');
    expect(first.result.attempt.correctCount, 4);
    expect(first.result.isDemo, isTrue);
    await expectLater(first.answer('b'), throwsStateError);
    final oldId = first.attempt!.id;
    await first.start();
    expect(first.attempt!.id, isNot(oldId));
    expect(first.attempt!.answers, isEmpty);
    expect(first.attempt!.flaggedQuestionIds, isEmpty);
  });

  test(
      'unanswered questions count as incorrect; empty answers never fake success',
      () async {
    final controller = await startedMock();
    await controller.finish();
    expect(controller.result.outcome, 'Below practice threshold');
    expect(controller.result.attempt.correctCount, 0);
    expect(controller.result.attempt.answeredCount, 0);
  });

  test('threshold is inclusive and uses unrounded counts', () async {
    final controller = await startedMock(package: mockPackage(threshold: 60));
    for (var i = 0; i < 3; i++) {
      if (i != 0) await controller.moveTo(i);
      await controller.answer('a');
    }
    await controller.finish();
    expect(controller.result.outcome, 'Above practice threshold');
  });

  test('changed answer replaces earlier choice; flag toggle removes flag',
      () async {
    final controller = await startedMock();
    await controller.answer('a');
    await controller.answer('b');
    await controller.toggleFlag();
    await controller.toggleFlag();
    expect(controller.attempt!.answeredCount, 1);
    expect(controller.attempt!.flaggedQuestionIds, isEmpty);
    await controller.finish();
    expect(controller.result.attempt.correctCount, 0);
  });

  test('invalid answer, bounds and forbidden back navigation are rejected',
      () async {
    final controller = await startedMock(package: mockPackage(back: false));
    final before = controller.attempt;
    await expectLater(controller.answer('unknown'), throwsArgumentError);
    await expectLater(controller.moveTo(-1), throwsArgumentError);
    await expectLater(controller.moveTo(5), throwsArgumentError);
    expect(controller.attempt, before);
    await controller.moveTo(2);
    await expectLater(controller.moveTo(1), throwsArgumentError);
    expect(controller.currentIndex, 2);
  });

  test('save failure leaves answers, flags, position and completion unchanged',
      () async {
    final repo = ControlledMockRepository();
    final controller = await startedMock(repository: repo);
    final before = controller.attempt;
    repo.failSave = true;
    for (final action in <Future<void> Function()>[
      () => controller.answer('a'),
      controller.toggleFlag,
      () => controller.moveTo(2),
      controller.finish,
    ]) {
      await expectLater(action(), throwsStateError);
      expect(controller.attempt, before);
      expect(await repo.mockAttempt(before!.id), before);
    }
    repo.failSave = false;
    await controller.answer('a');
    expect(controller.attempt!.answeredCount, 1);
  });

  test('failed first save leaves no attempt and retry creates one', () async {
    final repo = ControlledMockRepository()..failSave = true;
    final controller = MockExamController(
        blueprint: MockExamBlueprint.fromPackage(mockPackage()),
        repository: repo);
    await controller.load();
    await expectLater(controller.start(), throwsStateError);
    expect(controller.attempt, isNull);
    repo.failSave = false;
    await controller.start();
    expect(await repo.mockAttemptsForExam('demo_exam'), hasLength(1));
  });

  test(
      'pending save rejects concurrent writes and does not publish speculative state',
      () async {
    final repo = ControlledMockRepository();
    final controller = await startedMock(repository: repo);
    repo.saveGate = Completer<void>();
    final pending = controller.answer('a');
    expect(controller.attempt!.answers, isEmpty);
    await expectLater(controller.toggleFlag(), throwsStateError);
    repo.saveGate!.complete();
    await pending;
    expect(controller.attempt!.answeredCount, 1);
  });

  test(
      'recreated controller restores question position, answers and flags offline',
      () async {
    final repo = ControlledMockRepository();
    final controller = await startedMock(repository: repo);
    await controller.answer('b');
    await controller.toggleFlag();
    await controller.moveTo(3);
    final restarted =
        MockExamController(blueprint: controller.blueprint, repository: repo);
    await restarted.load();
    await restarted.start();
    expect(restarted.attempt, controller.attempt);
    expect(restarted.currentIndex, 3);
    expect(await repo.mockAttemptsForExam('demo_exam'), hasLength(1));
  });

  test(
      'demo process reset uses a fresh repository without claiming durable history',
      () async {
    final first = await startedMock();
    await first.answer('a');
    final reset = await startedMock();
    expect(reset.attempt!.answers, isEmpty);
  });

  test('timer uses persisted start time, including resume after deadline',
      () async {
    var now = DateTime.utc(2026, 1, 1, 12);
    final repo = ControlledMockRepository();
    final controller = await startedMock(
        repository: repo, package: mockPackage(timed: true), now: () => now);
    now = now.add(const Duration(minutes: 11));
    final resumed = MockExamController(
        blueprint: controller.blueprint, repository: repo, now: () => now);
    await resumed.load();
    expect(resumed.remaining, Duration.zero);
    expect(resumed.isExpired, isTrue);
    await expectLater(resumed.answer('a'), throwsStateError);
    await resumed.finish();
    expect(resumed.result.outcome, 'Below practice threshold');
  });

  test(
      'untimed exams do not expire and clock rollback cannot produce negative duration',
      () async {
    var now = DateTime.utc(2026, 1, 1, 12);
    final controller = await startedMock(now: () => now);
    now = now.add(const Duration(days: 1));
    expect(controller.isExpired, isFalse);
    await controller.answer('a');
    now = now.subtract(const Duration(days: 2));
    await controller.finish();
    expect(controller.attempt!.completedAt, controller.attempt!.startedAt);
  });

  test(
      'a changed content version refuses to restore instead of silently discarding answers',
      () async {
    final repo = ControlledMockRepository();
    final controller = await startedMock(repository: repo);
    await controller.answer('a');
    final changed = MockExamController(
        blueprint:
            MockExamBlueprint.fromPackage(mockPackage(version: 'demo-2')),
        repository: repo);
    await expectLater(changed.load(), throwsFormatException);
    expect(await repo.mockAttempt(controller.attempt!.id), controller.attempt);
  });

  test(
      'multiple active attempts require recovery rather than arbitrary selection',
      () async {
    final repo = ControlledMockRepository();
    final first = await startedMock(repository: repo);
    final other = MockAttempt(
        id: 'other',
        examId: 'demo_exam',
        questionIds: first.attempt!.questionIds,
        answers: const {},
        flaggedQuestionIds: const {},
        status: MockAttemptStatus.inProgress,
        startedAt: first.attempt!.startedAt,
        durationMinutes: 10,
        contentVersion: 'demo-1');
    await repo.saveMockAttempt(other);
    final next =
        MockExamController(blueprint: first.blueprint, repository: repo);
    await expectLater(next.load(), throwsFormatException);
  });

  test(
      'controller and blueprint do not depend on Flutter, assets or storage plugins',
      () {
    for (final file in [
      'mock_exam_controller.dart',
      'mock_exam_blueprint.dart'
    ]) {
      final source = File('lib/mock_exam/$file').readAsStringSync();
      expect(source, isNot(contains('package:flutter/')));
      expect(source, isNot(contains('shared_preferences')));
      expect(source, isNot(contains('debug_demo_environment.dart')));
    }
  });
}
