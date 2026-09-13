import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/practice_session/resumable_session.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import '../study_plan/fixtures.dart';

void main() {
  for (final completed in [false, true]) {
    test(
        'retire only unfinished diagnostic; preserve SQLite history on restart completed=$completed',
        () async {
      final dir = await Directory.systemTemp.createTemp('retired-check-');
      final file = File('${dir.path}/progress.db');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        var repo = DriftProgressRepository(db);
        final package = fixture(count: 3);
        final session = PracticeSession(
            id: 'legacy',
            examId: package.exam.id,
            mode: PracticeMode.diagnostic,
            questionIds: package.questions.map((q) => q.id).toList(),
            answerOrder: {
              for (final q in package.questions)
                q.id: q.answers.reversed.map((a) => a.id).toList()
            },
            status: SessionStatus.inProgress,
            startedAt: DateTime.utc(2026, 9, 1));
        await repo.savePracticeSession(session);
        final controller = PracticeSessionController(
            session: session,
            questions: package.questions,
            progressRepository: repo);
        await controller.submitAnswer('b');
        if (completed) {
          for (var i = 1; i < 3; i++) {
            controller.moveTo(i);
            await controller.submitAnswer('a');
          }
          await controller.complete();
        }
        final answers = await repo.answerAttemptsForExam(package.exam.id);
        final before =
            (await repo.practiceSessionsForExam(package.exam.id)).single;
        expect(await resumablePracticeSession(repo, package.exam.id), isNull);
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        repo = DriftProgressRepository(db);
        expect(await resumablePracticeSession(repo, package.exam.id), isNull);
        final saved =
            (await repo.practiceSessionsForExam(package.exam.id)).single;
        expect(
            saved,
            completed
                ? before
                : before.copyWith(status: SessionStatus.abandoned));
        expect(saved.completedAt, completed ? before.completedAt : null);
        expect(await repo.answerAttemptsForExam(package.exam.id), answers);
        final fresh = PracticeSession(
            id: 'fresh',
            examId: package.exam.id,
            mode: PracticeMode.quickPractice,
            questionIds: session.questionIds,
            status: SessionStatus.inProgress,
            startedAt: DateTime.utc(2026, 9, 13));
        await repo.savePracticeSession(fresh);
        expect(await resumablePracticeSession(repo, package.exam.id), fresh);
        expect(await repo.answerAttemptsForExam(package.exam.id), answers);
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    });
  }
}
