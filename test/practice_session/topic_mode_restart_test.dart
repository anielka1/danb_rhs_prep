import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import '../study_plan/fixtures.dart';

void main() {
  test('topic mode and answer order survive a database restart and close',
      () async {
    final dir = await Directory.systemTemp.createTemp('topic-mode-');
    final file = File('${dir.path}/progress.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });
    final package = fixture(count: 3);
    final repo = DriftProgressRepository(db);
    final order = {
      for (final q in package.questions)
        q.id: q.answers.reversed.map((a) => a.id).toList()
    };
    final session = PracticeSession(
        id: 'topic',
        examId: package.exam.id,
        mode: PracticeMode.topicPractice,
        questionIds: package.questions.map((q) => q.id).toList(),
        answerOrder: order,
        status: SessionStatus.inProgress,
        startedAt: DateTime.utc(2026, 10, 7));
    await repo.savePracticeSession(session);
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    final reopened = DriftProgressRepository(db);
    final saved = (await reopened.inProgressPracticeSession(package.exam.id))!;
    expect(saved.mode, PracticeMode.topicPractice);
    expect(saved.answerOrder, order);
    final controller = await PracticeSessionController.resume(
        session: saved,
        questions: package.questions,
        progressRepository: reopened);
    await controller.complete();
    expect(await reopened.inProgressPracticeSession(package.exam.id), isNull);
    expect(
        (await reopened.practiceSessionsForExam(package.exam.id))
            .single
            .answerOrder,
        order);
    expect(await reopened.answerAttemptsForExam(package.exam.id), isEmpty);
    expect(await reopened.questionStatesForExam(package.exam.id), isEmpty);
  });
}
