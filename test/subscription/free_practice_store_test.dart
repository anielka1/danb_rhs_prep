import 'dart:io';
import 'package:danb_rhs_prep/domain/repositories/progress_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/data/repositories/drift_free_practice_store.dart';
import '../study_plan/fixtures.dart';

void main() {
  test(
      'atomic trial ledger survives restart, reset, retries and failed answers',
      () async {
    final dir = await Directory.systemTemp.createTemp('trial-ledger-');
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    var progress = ProgressSessionRepository(DriftProgressRepository(db));
    var trial = DriftFreePracticeStore(db);
    final package = fixture(count: 8);
    final attempts = [
      for (var i = 0; i < 6; i++)
        answer(package.questions.first, DateTime.utc(2026, 1, 1),
            id: 'trial-$i', correct: i.isEven)
    ];
    await trial.registerSession(attempts.first.sessionId);
    expect((await trial.read()).remaining, 5);
    await expectLater(
        trial.record(attempts.first, () async {
          await progress.recordAnswerAttempt(attempts.first);
          throw StateError('disk failure before commit');
        }),
        throwsStateError);
    expect((await trial.read()).answeredCount, 0);
    expect(await progress.answerAttemptsForExam(package.exam.id), isEmpty);
    for (final a in attempts.take(3)) {
      await Future.wait([
        trial.record(a, () => progress.recordAnswerAttempt(a)),
        trial.record(a, () => progress.recordAnswerAttempt(a)),
      ]);
    }
    expect((await trial.read()).remaining, 2);
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    progress = ProgressSessionRepository(DriftProgressRepository(db));
    trial = DriftFreePracticeStore(db);
    expect((await trial.read()).remaining, 2);
    for (final a in attempts.skip(3).take(2)) {
      await trial.record(a, () => progress.recordAnswerAttempt(a));
    }
    await expectLater(
        trial.record(
            attempts.last, () => progress.recordAnswerAttempt(attempts.last)),
        throwsStateError);
    expect((await trial.read()).completed, true);
    expect((await progress.answerAttemptsForExam(package.exam.id)).length, 5);
    await trial.markCompletionPaywallShown();
    await progress.reset(package.exam.id);
    expect((await trial.read()).answeredCount, 5);
    expect((await trial.read()).completionPaywallShown, true);
    await db.close();
    await dir.delete(recursive: true);
  });
  test('schema five upgrade preserves answers and starts a new lifetime trial',
      () async {
    final dir = await Directory.systemTemp.createTemp('trial-migrate-');
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    final package = fixture(count: 1);
    final a = answer(package.questions.first, DateTime.utc(2026));
    await DriftProgressRepository(db).recordAnswerAttempt(a);
    await db.customStatement('DROP TABLE free_practice_trial');
    await db.customStatement('PRAGMA user_version = 5');
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    expect(
        (await DriftProgressRepository(db)
                .answerAttemptsForExam(package.exam.id))
            .single
            .id,
        a.id);
    expect((await DriftFreePracticeStore(db).read()).remaining, 5);
    await db.close();
    await dir.delete(recursive: true);
  });
}
