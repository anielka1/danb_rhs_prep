import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/data/repositories/drift_user_settings_repository.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/progress_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/progress_reset_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> seed(ProgressRepository repo) async {
  for (final a in DebugDemoEnvironment.demoAnswerAttempts) {
    await repo.recordAnswerAttempt(a);
  }
  for (final q in DebugDemoEnvironment.demoQuestionStates) {
    await repo.saveQuestionState(q);
  }
  await repo
      .savePracticeSession(DebugDemoEnvironment.demoInProgressPracticeSession);
  await repo.saveMockAttempt(DebugDemoEnvironment.demoMockAttempt);
  await repo.saveReadinessSnapshot(DebugDemoEnvironment.demoReadinessSnapshot);
  await repo.saveQuestionState(
      QuestionState.unseen(examId: 'other', questionId: 'q')
          .copyWith(bookmarked: true));
}

void main() {
  const exam = DebugDemoEnvironment.demoExamId;
  for (final drift in [false, true]) {
    test('reset is exam-scoped and repeatable, SQLite=$drift', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final ProgressRepository repo;
      if (drift) {
        repo = DriftProgressRepository(db);
      } else {
        repo = InMemoryProgressRepository();
      }
      final settings = DriftUserSettingsRepository(db);
      await settings.saveProfile(DebugDemoEnvironment.demoProfile);
      await seed(repo);
      final reset = repo as ProgressResetRepository;
      await reset.resetProgressForExam(exam);
      await reset.resetProgressForExam(exam);
      expect(await repo.answerAttemptsForExam(exam), isEmpty);
      expect(await repo.questionStatesForExam(exam), isEmpty);
      expect(await repo.inProgressPracticeSession(exam), isNull);
      expect(await repo.mockAttemptsForExam(exam), isEmpty);
      expect(await repo.readinessSnapshotsForExam(exam), isEmpty);
      expect((await repo.questionState('other', 'q')).bookmarked, isTrue);
      final profile = await settings.loadProfile(exam);
      expect(profile!.dailyGoalQuestions,
          DebugDemoEnvironment.demoProfile.dailyGoalQuestions);
      expect(profile.themePreference,
          DebugDemoEnvironment.demoProfile.themePreference);
      expect(profile.onboardingComplete, isTrue);
      await repo
          .recordAnswerAttempt(DebugDemoEnvironment.demoAnswerAttempts.first);
      expect(await repo.answerAttemptsForExam(exam), hasLength(1));
    });
  }

  test('SQLite failure midway rolls back every deleted table', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftProgressRepository(db);
    await seed(repo);
    final attempts = await repo.answerAttemptsForExam(exam);
    final states = await repo.questionStatesForExam(exam);
    await db.customStatement(
        '''CREATE TRIGGER block_reset BEFORE DELETE ON mock_attempts
      BEGIN SELECT RAISE(ABORT, 'controlled test failure'); END''');
    await expectLater(
        repo.resetProgressForExam(exam), throwsA(isA<Exception>()));
    expect(await repo.answerAttemptsForExam(exam), attempts);
    expect((await repo.questionStatesForExam(exam)).length, states.length);
    expect(await repo.inProgressPracticeSession(exam), isNotNull);
    expect(await repo.mockAttemptsForExam(exam), hasLength(1));
    expect(await repo.readinessSnapshotsForExam(exam), hasLength(1));
    await db.customStatement('DROP TRIGGER block_reset');
    await repo.resetProgressForExam(exam);
    expect(await repo.answerAttemptsForExam(exam), isEmpty);
  });
}
