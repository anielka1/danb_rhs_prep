import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/models/readiness_band.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';

void main() {
  late InMemoryProgressRepository repository;

  setUp(() {
    repository = InMemoryProgressRepository();
  });

  test('recorded answer attempts are scoped by exam', () async {
    final attempt = AnswerAttempt(
      id: 'attempt-1',
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
    );

    await repository.recordAnswerAttempt(attempt);
    await repository.recordAnswerAttempt(attempt.copyWithExam('other-exam'));

    final attempts = await repository.answerAttemptsForExam('danb-rhs');
    expect(attempts, [attempt]);
  });

  test('an unrecorded question state defaults to unseen', () async {
    final state = await repository.questionState('danb-rhs', 'q1');
    expect(state.hasBeenAnswered, isFalse);
  });

  test('saveQuestionState is retrievable by exam and question', () async {
    final state = QuestionState.unseen(
      examId: 'danb-rhs',
      questionId: 'q1',
    ).withAttempt(isCorrect: true, answeredAt: DateTime.utc(2026, 1, 1));

    await repository.saveQuestionState(state);

    expect(await repository.questionState('danb-rhs', 'q1'), state);
    expect(await repository.questionStatesForExam('danb-rhs'), [state]);
  });

  test('inProgressPracticeSession finds the only unfinished session', () async {
    final inProgress = PracticeSession(
      id: 'session-1',
      examId: 'danb-rhs',
      mode: PracticeMode.quickPractice,
      questionIds: const ['q1'],
      status: SessionStatus.inProgress,
      startedAt: DateTime.utc(2026, 1, 1),
    );
    final completed = PracticeSession(
      id: 'session-2',
      examId: 'danb-rhs',
      mode: PracticeMode.quickPractice,
      questionIds: const ['q2'],
      status: SessionStatus.completed,
      startedAt: DateTime.utc(2026, 1, 1),
      completedAt: DateTime.utc(2026, 1, 1, 1),
    );

    await repository.savePracticeSession(inProgress);
    await repository.savePracticeSession(completed);

    final resumable = await repository.inProgressPracticeSession('danb-rhs');
    expect(resumable, inProgress);
  });

  test('mock attempts are retrievable by id and by exam', () async {
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

    expect(await repository.mockAttempt('mock-1'), attempt);
    expect(await repository.mockAttemptsForExam('danb-rhs'), [attempt]);
    expect(await repository.mockAttempt('missing'), isNull);
  });

  test('latestReadinessSnapshot returns the most recently calculated one',
      () async {
    final older = ReadinessSnapshot(
      id: 'snap-1',
      examId: 'danb-rhs',
      calculatedAt: DateTime.utc(2026, 1, 1),
      overallScore: 40,
      band: ReadinessBand.starting,
      recentAccuracyComponent: 40,
      domainMasteryComponent: 40,
      mockPerformanceComponent: 40,
      repeatedMasteryComponent: 40,
      coverageComponent: 40,
      evidenceConfidence: 0.5,
      uniqueQuestionsAnswered: 20,
    );
    final newer = ReadinessSnapshot(
      id: 'snap-2',
      examId: 'danb-rhs',
      calculatedAt: DateTime.utc(2026, 2, 1),
      overallScore: 55,
      band: ReadinessBand.developing,
      recentAccuracyComponent: 55,
      domainMasteryComponent: 55,
      mockPerformanceComponent: 55,
      repeatedMasteryComponent: 55,
      coverageComponent: 55,
      evidenceConfidence: 0.6,
      uniqueQuestionsAnswered: 40,
    );

    await repository.saveReadinessSnapshot(older);
    await repository.saveReadinessSnapshot(newer);

    expect(await repository.latestReadinessSnapshot('danb-rhs'), newer);
    expect(
      await repository.readinessSnapshotsForExam('danb-rhs'),
      [older, newer],
    );
  });
}

extension on AnswerAttempt {
  AnswerAttempt copyWithExam(String examId) {
    return AnswerAttempt(
      id: id,
      examId: examId,
      questionId: questionId,
      domainId: domainId,
      topicId: topicId,
      difficulty: difficulty,
      sessionId: sessionId,
      sessionType: sessionType,
      selectedAnswerId: selectedAnswerId,
      isCorrect: isCorrect,
      answeredAt: answeredAt,
    );
  }
}
