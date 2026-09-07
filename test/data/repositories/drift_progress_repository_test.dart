import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/models/readiness_band.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';

void main() {
  late AppDatabase db;
  late DriftProgressRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftProgressRepository(db);
  });

  tearDown(() => db.close());

  group('answer attempts', () {
    AnswerAttempt buildAttempt({
      String id = 'attempt-1',
      String examId = 'danb-rhs',
    }) {
      return AnswerAttempt(
        id: id,
        examId: examId,
        questionId: 'q1',
        domainId: 'radiation-protection',
        topicId: 'shielding',
        difficulty: 2,
        sessionId: 'session-1',
        sessionType: AttemptSessionType.practice,
        selectedAnswerId: 'a1',
        isCorrect: true,
        answeredAt: DateTime.utc(2026, 1, 1),
      );
    }

    test('recorded attempts are scoped by exam', () async {
      final attempt = buildAttempt();
      await repository.recordAnswerAttempt(attempt);
      await repository.recordAnswerAttempt(
          buildAttempt(id: 'attempt-2', examId: 'other-exam'));

      expect(await repository.answerAttemptsForExam('danb-rhs'), [attempt]);
    });

    test(
        'is genuinely append-only: answering the same question twice in '
        'the same session records two distinct attempts, never an '
        'overwrite — this is exactly what a real primary-key id must '
        'guarantee', () async {
      final first = buildAttempt(id: 'attempt-1');
      final second = AnswerAttempt(
        id: 'attempt-2',
        examId: first.examId,
        questionId: first.questionId,
        domainId: first.domainId,
        topicId: first.topicId,
        difficulty: first.difficulty,
        sessionId: first.sessionId,
        sessionType: first.sessionType,
        selectedAnswerId: 'a2',
        isCorrect: false,
        answeredAt: DateTime.utc(2026, 1, 1, 0, 1),
      );

      await repository.recordAnswerAttempt(first);
      await repository.recordAnswerAttempt(second);

      final attempts = await repository.answerAttemptsForExam('danb-rhs');
      expect(attempts, hasLength(2));
      expect(attempts, containsAll([first, second]));
    });

    test(
        'recording two attempts with the same id but different content '
        'fails loudly rather than silently overwriting history', () async {
      await repository.recordAnswerAttempt(buildAttempt(id: 'dup'));
      await expectLater(
        // Same id, but a different selected answer/outcome than what was
        // already recorded — a real conflict, not a retry.
        repository.recordAnswerAttempt(AnswerAttempt(
          id: 'dup',
          examId: 'danb-rhs',
          questionId: 'q1',
          domainId: 'radiation-protection',
          topicId: 'shielding',
          difficulty: 2,
          sessionId: 'session-1',
          sessionType: AttemptSessionType.practice,
          selectedAnswerId: 'a2',
          isCorrect: false,
          answeredAt: DateTime.utc(2026, 1, 1),
        )),
        throwsA(anything),
      );
    });

    test(
        'recording the exact same attempt twice (same id, identical '
        'content) is a genuinely idempotent no-op — PREP-664 — not a '
        'failure and not a second history entry', () async {
      final attempt = buildAttempt(id: 'dup');
      await repository.recordAnswerAttempt(attempt);

      await repository.recordAnswerAttempt(attempt);

      final attempts = await repository.answerAttemptsForExam('danb-rhs');
      expect(attempts, [attempt],
          reason: 'the identical resubmission must not add a second row');
    });

    test(
        'a genuinely idempotent resubmission (PREP-664) does not '
        're-count the question-state update — only the original, '
        'first-time recording affected it', () async {
      final attempt = buildAttempt(id: 'dup');
      await repository.recordAnswerAttempt(attempt);
      final QuestionState afterFirst =
          await repository.questionState('danb-rhs', 'q1');
      expect(afterFirst.timesSeen, 1);

      await repository.recordAnswerAttempt(attempt);

      final QuestionState afterIdempotentResubmit =
          await repository.questionState('danb-rhs', 'q1');
      expect(afterIdempotentResubmit, afterFirst,
          reason: 'timesSeen/timesCorrect must not double-count a safe, '
              'idempotent no-op resubmission');
    });

    test('answeredAt is read back as UTC', () async {
      await repository.recordAnswerAttempt(buildAttempt());
      final attempts = await repository.answerAttemptsForExam('danb-rhs');
      expect(attempts.single.answeredAt.isUtc, isTrue);
    });

    test('contentVersion round-trips, and is null when not given', () async {
      final versioned = AnswerAttempt(
        id: 'attempt-versioned',
        examId: 'danb-rhs',
        questionId: 'q1',
        domainId: 'radiation-protection',
        topicId: 'shielding',
        difficulty: 2,
        sessionId: 'session-1',
        sessionType: AttemptSessionType.practice,
        selectedAnswerId: 'a1',
        isCorrect: true,
        answeredAt: DateTime.utc(2026, 1, 1),
        contentVersion: '2026.1',
      );
      await repository.recordAnswerAttempt(versioned);
      await repository.recordAnswerAttempt(buildAttempt(id: 'attempt-plain'));

      final attempts = await repository.answerAttemptsForExam('danb-rhs');
      expect(
        attempts.firstWhere((a) => a.id == 'attempt-versioned').contentVersion,
        '2026.1',
      );
      expect(
        attempts.firstWhere((a) => a.id == 'attempt-plain').contentVersion,
        isNull,
      );
    });

    test(
        'recordAnswerAttempt (PREP-664) atomically updates the aggregate '
        'question state in the same call — a caller never has to '
        'separately call questionState/saveQuestionState itself', () async {
      await repository.recordAnswerAttempt(buildAttempt(id: 'attempt-1'));
      await repository.recordAnswerAttempt(AnswerAttempt(
        id: 'attempt-2',
        examId: 'danb-rhs',
        questionId: 'q1',
        domainId: 'radiation-protection',
        topicId: 'shielding',
        difficulty: 2,
        sessionId: 'session-1',
        sessionType: AttemptSessionType.practice,
        selectedAnswerId: 'wrong',
        isCorrect: false,
        answeredAt: DateTime.utc(2026, 1, 2),
      ));

      final state = await repository.questionState('danb-rhs', 'q1');
      expect(state.timesSeen, 2);
      expect(state.timesCorrect, 1);
      expect(state.timesIncorrect, 1);
      expect(state.consecutiveCorrect, 0,
          reason: 'the second, incorrect attempt must reset the streak');
      expect(state.lastAnsweredAt, DateTime.utc(2026, 1, 2));
    });

    test(
        'a rejected same-id-different-content conflict never applies its '
        'question-state update either — the conflict check and the '
        'state update are part of one atomic transaction, not two '
        'independent writes', () async {
      await repository.recordAnswerAttempt(buildAttempt(id: 'attempt-1'));
      final QuestionState afterFirst =
          await repository.questionState('danb-rhs', 'q1');
      expect(afterFirst.timesSeen, 1);

      // Same id as the attempt already recorded above, but different
      // content — a real conflict, which must fail before ever reaching
      // the question-state update inside the same transaction.
      await expectLater(
        repository.recordAnswerAttempt(AnswerAttempt(
          id: 'attempt-1',
          examId: 'danb-rhs',
          questionId: 'q1',
          domainId: 'radiation-protection',
          topicId: 'shielding',
          difficulty: 2,
          sessionId: 'session-1',
          sessionType: AttemptSessionType.practice,
          selectedAnswerId: 'different-answer',
          isCorrect: false,
          answeredAt: DateTime.utc(2026, 1, 1),
        )),
        throwsA(anything),
      );

      final QuestionState afterRejectedConflict =
          await repository.questionState('danb-rhs', 'q1');
      expect(afterRejectedConflict, afterFirst,
          reason: 'the rejected conflict must not have double-counted the '
              'question state — proving the conflict check and the state '
              'update roll back together, not independently');
    });
  });

  group('question state', () {
    test('an unrecorded question state defaults to unseen', () async {
      final state = await repository.questionState('danb-rhs', 'q1');
      expect(state.hasBeenAnswered, isFalse);
    });

    test('saveQuestionState is retrievable by exam and question', () async {
      final state = QuestionState.unseen(examId: 'danb-rhs', questionId: 'q1')
          .withAttempt(isCorrect: true, answeredAt: DateTime.utc(2026, 1, 1));

      await repository.saveQuestionState(state);

      expect(await repository.questionState('danb-rhs', 'q1'), state);
      expect(await repository.questionStatesForExam('danb-rhs'), [state]);
    });

    test('saveQuestionState upserts by (examId, questionId)', () async {
      final seen = QuestionState.unseen(examId: 'danb-rhs', questionId: 'q1')
          .withAttempt(isCorrect: true, answeredAt: DateTime.utc(2026, 1, 1));
      await repository.saveQuestionState(seen);

      final seenAgain = seen.withAttempt(
          isCorrect: false, answeredAt: DateTime.utc(2026, 1, 2));
      await repository.saveQuestionState(seenAgain);

      final states = await repository.questionStatesForExam('danb-rhs');
      expect(states, [seenAgain]);
    });
  });

  group('practice sessions', () {
    test('inProgressPracticeSession finds the only unfinished session',
        () async {
      final inProgress = PracticeSession(
        id: 'session-1',
        examId: 'danb-rhs',
        mode: PracticeMode.quickPractice,
        questionIds: const ['q1', 'q2'],
        status: SessionStatus.inProgress,
        startedAt: DateTime.utc(2026, 1, 1),
      );
      final completed = PracticeSession(
        id: 'session-2',
        examId: 'danb-rhs',
        mode: PracticeMode.quickPractice,
        questionIds: const ['q3'],
        status: SessionStatus.completed,
        startedAt: DateTime.utc(2026, 1, 1),
        completedAt: DateTime.utc(2026, 1, 1, 1),
      );

      await repository.savePracticeSession(inProgress);
      await repository.savePracticeSession(completed);

      expect(
          await repository.inProgressPracticeSession('danb-rhs'), inProgress);
    });

    test(
        'savePracticeSession upserts by id (a session moving from '
        'inProgress to completed replaces its own prior row)', () async {
      final session = PracticeSession(
        id: 'session-1',
        examId: 'danb-rhs',
        mode: PracticeMode.quickPractice,
        questionIds: const ['q1'],
        status: SessionStatus.inProgress,
        startedAt: DateTime.utc(2026, 1, 1),
      );
      await repository.savePracticeSession(session);

      final finished = session.copyWith(
        status: SessionStatus.completed,
        completedAt: DateTime.utc(2026, 1, 1, 1),
      );
      await repository.savePracticeSession(finished);

      expect(await repository.inProgressPracticeSession('danb-rhs'), isNull);
    });

    test('questionIds preserve their exact order through the JSON column',
        () async {
      final session = PracticeSession(
        id: 'session-1',
        examId: 'danb-rhs',
        mode: PracticeMode.quickPractice,
        questionIds: const ['q3', 'q1', 'q2'],
        status: SessionStatus.inProgress,
        startedAt: DateTime.utc(2026, 1, 1),
      );
      await repository.savePracticeSession(session);

      final reloaded = await repository.inProgressPracticeSession('danb-rhs');
      expect(reloaded!.questionIds, ['q3', 'q1', 'q2']);
    });

    test('contentVersion round-trips, and is null when not given', () async {
      final versioned = PracticeSession(
        id: 'session-1',
        examId: 'danb-rhs',
        mode: PracticeMode.quickPractice,
        questionIds: const ['q1'],
        status: SessionStatus.inProgress,
        startedAt: DateTime.utc(2026, 1, 1),
        contentVersion: '2026.1',
      );
      await repository.savePracticeSession(versioned);

      final reloaded = await repository.inProgressPracticeSession('danb-rhs');
      expect(reloaded!.contentVersion, '2026.1');
    });
  });

  group('mock attempts', () {
    test('mock attempts are retrievable by id and by exam', () async {
      final attempt = MockAttempt(
        id: 'mock-1',
        examId: 'danb-rhs',
        questionIds: const ['q1', 'q2'],
        answers: const {'q1': 'a'},
        flaggedQuestionIds: const {'q2'},
        status: MockAttemptStatus.inProgress,
        startedAt: DateTime.utc(2026, 1, 1),
        durationMinutes: 60,
      );

      await repository.saveMockAttempt(attempt);

      expect(await repository.mockAttempt('mock-1'), attempt);
      expect(await repository.mockAttemptsForExam('danb-rhs'), [attempt]);
      expect(await repository.mockAttempt('missing'), isNull);
    });

    test('a completed attempt with score round-trips exactly', () async {
      final attempt = MockAttempt(
        id: 'mock-1',
        examId: 'danb-rhs',
        questionIds: const ['q1', 'q2'],
        answers: const {'q1': 'a', 'q2': 'b'},
        flaggedQuestionIds: const {},
        status: MockAttemptStatus.completed,
        startedAt: DateTime.utc(2026, 1, 1),
        durationMinutes: 60,
        completedAt: DateTime.utc(2026, 1, 1, 1),
        correctCount: 1,
        contentVersion: '2026.1',
      );

      await repository.saveMockAttempt(attempt);

      expect(await repository.mockAttempt('mock-1'), attempt);
    });

    test('saveMockAttempt upserts by id', () async {
      final attempt = MockAttempt(
        id: 'mock-1',
        examId: 'danb-rhs',
        questionIds: const ['q1'],
        answers: const {},
        flaggedQuestionIds: const {},
        status: MockAttemptStatus.inProgress,
        startedAt: DateTime.utc(2026, 1, 1),
        durationMinutes: 60,
      );
      await repository.saveMockAttempt(attempt);

      final updated = attempt.copyWith(
        answers: const {'q1': 'a'},
        status: MockAttemptStatus.completed,
        completedAt: DateTime.utc(2026, 1, 1, 1),
        correctCount: 1,
      );
      await repository.saveMockAttempt(updated);

      final all = await repository.mockAttemptsForExam('danb-rhs');
      expect(all, [updated]);
    });
  });

  group('readiness snapshots', () {
    ReadinessSnapshot buildSnapshot({
      required String id,
      required DateTime calculatedAt,
      double overallScore = 40,
    }) {
      return ReadinessSnapshot(
        id: id,
        examId: 'danb-rhs',
        calculatedAt: calculatedAt,
        overallScore: overallScore,
        band: ReadinessBand.starting,
        recentAccuracyComponent: overallScore,
        domainMasteryComponent: overallScore,
        mockPerformanceComponent: overallScore,
        repeatedMasteryComponent: overallScore,
        coverageComponent: overallScore,
        evidenceConfidence: 0.5,
        uniqueQuestionsAnswered: 20,
      );
    }

    test('latestReadinessSnapshot returns the most recently calculated one',
        () async {
      final older =
          buildSnapshot(id: 'snap-1', calculatedAt: DateTime.utc(2026, 1, 1));
      final newer = buildSnapshot(
          id: 'snap-2',
          calculatedAt: DateTime.utc(2026, 2, 1),
          overallScore: 55);

      await repository.saveReadinessSnapshot(older);
      await repository.saveReadinessSnapshot(newer);

      expect(await repository.latestReadinessSnapshot('danb-rhs'), newer);
      expect(await repository.readinessSnapshotsForExam('danb-rhs'),
          containsAll([older, newer]));
    });

    test(
        'is append-only: saving a snapshot never replaces a prior one, '
        'even for the same exam', () async {
      final first =
          buildSnapshot(id: 'snap-1', calculatedAt: DateTime.utc(2026, 1, 1));
      final second =
          buildSnapshot(id: 'snap-2', calculatedAt: DateTime.utc(2026, 1, 2));

      await repository.saveReadinessSnapshot(first);
      await repository.saveReadinessSnapshot(second);

      expect(
          await repository.readinessSnapshotsForExam('danb-rhs'), hasLength(2));
    });
  });
}
