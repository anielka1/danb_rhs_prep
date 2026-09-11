import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/domain/models/answer_order.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/study_plan/planned_session_service.dart';
import '../study_plan/fixtures.dart';
import '../support/controlled_random.dart';

class FailingStartRepository extends InMemoryProgressRepository {
  bool fail = true;
  @override
  Future<void> savePracticeSession(PracticeSession session) async {
    if (fail) throw StateError('Write failed');
    await super.savePracticeSession(session);
  }
}

void main() {
  final package = fixture();
  final now = DateTime.utc(2026, 9, 11);
  for (final mode in PracticeMode.values) {
    test(
        '$mode preserves shuffled IDs and historical feedback after SQLite restart',
        () async {
      final dir = Directory.systemTemp.createTempSync('answer-order');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/progress.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      var repo = DriftProgressRepository(db);
      final questions = package.questions.take(2).toList();
      final order =
          AnswerOrder.shuffled(questions, ControlledRandom(rotate: true));
      final session = PracticeSession(
          id: 'session',
          examId: package.exam.id,
          mode: mode,
          questionIds: questions.map((q) => q.id).toList(),
          answerOrder: order,
          status: SessionStatus.inProgress,
          startedAt: now);
      await repo.savePracticeSession(session);
      final controller = PracticeSessionController(
          session: session,
          questions: questions,
          progressRepository: repo,
          now: () => now);
      expect(controller.currentQuestion.answers.map((a) => a.id),
          ['b', 'c', 'd', 'a']);
      expect((await controller.submitAnswer('a')).isCorrect, isTrue);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db.close);
      repo = DriftProgressRepository(db);
      final saved = (await repo.inProgressPracticeSession(package.exam.id))!;
      expect(saved, session);
      final restored = await PracticeSessionController.resume(
          session: saved,
          questions: questions,
          progressRepository: repo,
          now: () => now);
      expect(restored.questions.first.answers.map((a) => a.id),
          ['b', 'c', 'd', 'a']);
      expect(restored.currentIndex, 1);
      expect(restored.correctCount, 1);
      expect((await restored.submitAnswer('b')).isCorrect, isFalse);
      expect(restored.session.answerOrder, order);
      expect(
          (await repo.answerAttemptsForExam(package.exam.id))
              .first
              .correctAnswerId,
          'a');
    });
  }
  test(
      'diagnostic saves order before opening, retry and restart never shuffle it',
      () async {
    final repo = FailingStartRepository();
    final random = ControlledRandom(rotate: true);
    Future<PracticeSessionController> start(ControlledRandom source) =>
        const PlannedSessionService().start(
            package: package,
            repository: repo,
            entitlement: Entitlement.free(lastVerifiedAt: now),
            now: () => now,
            diagnostic: true,
            random: source);
    await expectLater(start(random), throwsStateError);
    expect(await repo.practiceSessionsForExam(package.exam.id), isEmpty);
    repo.fail = false;
    final first = await start(random);
    expect(
        first.currentQuestion.answers.map((a) => a.id), ['b', 'c', 'd', 'a']);
    final restored = await start(ControlledRandom(forbid: true));
    expect(restored.session.answerOrder, first.session.answerOrder);
    expect(await repo.practiceSessionsForExam(package.exam.id), hasLength(1));
  });
  test(
      'legacy order is unchanged; invalid saved orders fail closed; metadata is immutable',
      () {
    final questions = package.questions.take(1).toList();
    expect(AnswerOrder.resolve(questions, null).single, same(questions.single));
    for (final invalid in <Map<String, List<String>>>[
      {},
      {
        questions.single.id: ['a', 'a', 'c', 'd']
      },
      {
        questions.single.id: ['a', 'b', 'c', 'unknown']
      },
      {
        questions.single.id: ['a', 'b', 'c']
      },
    ]) {
      expect(
          () => AnswerOrder.resolve(questions, invalid), throwsFormatException);
    }
    final order = AnswerOrder.freeze(
        AnswerOrder.shuffled(questions, ControlledRandom()))!;
    expect(
        () => order[questions.single.id]!.removeLast(), throwsUnsupportedError);
    expect(() => order.clear(), throwsUnsupportedError);
  });
}
