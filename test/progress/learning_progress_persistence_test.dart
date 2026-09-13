import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/progress/learning_progress.dart';
import '../study_plan/fixtures.dart';

void main() {
  test('SQLite restart and write retry preserve tied event order and local day',
      () async {
    final directory = await Directory.systemTemp.createTemp('rhs-progress-');
    final file = File('${directory.path}/progress.sqlite');
    final package = fixture(count: 8);
    final q = package.questions.first;
    final stamp = DateTime.utc(2026, 9, 14);
    final first =
        answer(q, stamp, id: 'z-first', correct: false, localDay: '2026-09-13');
    final last = answer(q, stamp, id: 'a-last', localDay: '2026-09-13');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      var repo = DriftProgressRepository(db);
      await repo.recordAnswerAttempt(first);
      await repo.recordAnswerAttempt(last);
      await repo.recordAnswerAttempt(last);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      repo = DriftProgressRepository(db);
      final attempts = await repo.answerAttemptsForExam(package.exam.id);
      expect(attempts.map((a) => a.id), ['z-first', 'a-last']);
      final progress =
          LearningProgress.fromHistory(package: package, attempts: attempts);
      expect(progress.total.correct, 1);
      expect(progress.total.needsReview, 0);
      expect(progress.total.notAttempted, 7);
      expect(progress.days.single.answers, 2);
      expect(progress.correctToday(DateTime(2026, 9, 13)), 1);
      expect(progress.correctToday(DateTime(2026, 9, 14)), 0);
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });
}
