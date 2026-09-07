import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_controller.dart';

import '../support/mock_exam_test_support.dart';

/// PREP-665: the mock-exam counterpart of
/// `test/practice_session/practice_session_restart_test.dart`, against
/// the real, Drift/SQLite-backed `DriftProgressRepository` — not a
/// shared in-memory repository *object* kept alive across a "restarted"
/// controller (what `mock_exam_controller_test.dart`'s own restart test
/// already covers, proving only the controller's reload logic), and not
/// `InMemoryProgressRepository` (which by definition can't lose state
/// across a restart). "Restart" means the same thing it does everywhere
/// else in this suite: close this `AppDatabase` connection and open a
/// genuinely new one, over the same on-disk file, before continuing.
///
/// Unlike a practice session, a `MockAttempt` needs no separate
/// restoration step: its answers, flags, and current position are all
/// columns of the one row `saveMockAttempt`/`mockAttemptsForExam` already
/// round-trip, so `MockExamController.load` alone is sufficient — this
/// test exists to prove that end to end against real storage, not
/// because a gap like `PracticeSessionController`'s (fixed by
/// `PracticeSessionController.resume`) was found here too.
void main() {
  test(
      'answering some but not all questions, flagging one, then '
      'restarting, resumes the same in-progress mock attempt with its '
      'answers, flags, and position all intact', () async {
    final Directory tempDir =
        Directory.systemTemp.createTempSync('mock_exam_restart_test');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final File dbFile = File('${tempDir.path}/app.sqlite');

    final AppDatabase first = AppDatabase.forTesting(NativeDatabase(dbFile));
    final firstRepo = DriftProgressRepository(first);
    final blueprint = MockExamBlueprint.fromPackage(mockPackage());

    final firstController =
        MockExamController(blueprint: blueprint, repository: firstRepo);
    await firstController.load();
    await firstController.start();
    await firstController.answer('a');
    await firstController.toggleFlag();
    await firstController.moveTo(1);
    await firstController.answer('b');

    final String attemptId = firstController.attempt!.id;

    // Simulates the app/process being killed mid-exam: the connection is
    // genuinely closed, not merely left in scope.
    await first.close();

    // "Restart": a brand new AppDatabase, DriftProgressRepository, and
    // MockExamController, over the same file — nothing here is the same
    // Dart object as above.
    final AppDatabase reopened = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(reopened.close);
    final reopenedRepo = DriftProgressRepository(reopened);

    final resumedController =
        MockExamController(blueprint: blueprint, repository: reopenedRepo);
    await resumedController.load();
    await resumedController.start();

    expect(resumedController.attempt!.id, attemptId);
    expect(resumedController.attempt!.status, MockAttemptStatus.inProgress,
        reason: 'an attempt interrupted mid-way must not be silently '
            'marked complete or abandoned by surviving a restart');
    expect(resumedController.attempt!.answers, {
      blueprint.questions[0].id: 'a',
      blueprint.questions[1].id: 'b',
    });
    expect(resumedController.attempt!.flaggedQuestionIds,
        {blueprint.questions[0].id});
    expect(resumedController.currentIndex, 1);
  });
}
