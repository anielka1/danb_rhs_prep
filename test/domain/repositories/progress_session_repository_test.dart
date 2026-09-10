import 'dart:async';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/progress_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class DelayedStorage extends InMemoryProgressRepository {
  Completer<void>? gate;
  bool failReset = false;
  int resets = 0;
  @override
  Future<void> savePracticeSession(PracticeSession session) async {
    await gate?.future;
    await super.savePracticeSession(session);
  }

  @override
  Future<void> resetProgressForExam(String id) async {
    resets++;
    if (failReset) throw StateError('controlled reset failure');
    await super.resetProgressForExam(id);
  }
}

void main() {
  const exam = DebugDemoEnvironment.demoExamId;
  final session = DebugDemoEnvironment.demoInProgressPracticeSession;
  test('reset drains accepted writes, rejects old retries and renews access',
      () async {
    final storage = DelayedStorage()..gate = Completer<void>();
    final old = ProgressSessionRepository(storage);
    final saving = old.savePracticeSession(session);
    final resetting = old.reset(exam);
    await expectLater(old.savePracticeSession(session), throwsStateError);
    expect(storage.resets, 0);
    storage.gate!.complete();
    await saving;
    final fresh = await resetting;
    expect(await storage.inProgressPracticeSession(exam), isNull);
    await expectLater(old.savePracticeSession(session), throwsStateError);
    await expectLater(
        old.recordAnswerAttempt(DebugDemoEnvironment.demoAnswerAttempts.first),
        throwsStateError);
    await expectLater(
        old.saveQuestionState(DebugDemoEnvironment.demoQuestionStates.first),
        throwsStateError);
    await expectLater(old.saveMockAttempt(DebugDemoEnvironment.demoMockAttempt),
        throwsStateError);
    await expectLater(
        old.saveReadinessSnapshot(DebugDemoEnvironment.demoReadinessSnapshot),
        throwsStateError);
    await fresh.savePracticeSession(session);
    expect(await fresh.inProgressPracticeSession(exam), isNotNull);
  });

  test('failed reset keeps the old lease usable and allows a later retry',
      () async {
    final storage = DelayedStorage()..failReset = true;
    final lease = ProgressSessionRepository(storage);
    await lease.savePracticeSession(session);
    await expectLater(lease.reset(exam), throwsStateError);
    expect(await lease.inProgressPracticeSession(exam), isNotNull);
    await lease
        .recordAnswerAttempt(DebugDemoEnvironment.demoAnswerAttempts.first);
    storage.failReset = false;
    final fresh = await lease.reset(exam);
    expect(await fresh.answerAttemptsForExam(exam), isEmpty);
    expect(await fresh.inProgressPracticeSession(exam), isNull);
  });
}
