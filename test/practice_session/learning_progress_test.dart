import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/progress/learning_progress.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import '../study_plan/fixtures.dart';

void main() {
  final package = fixture(count: 6);
  final q = package.questions.first;
  final now = DateTime.utc(2026, 9, 13);
  test('latest answer wins ties in persisted order; attempts remain daily', () {
    final wrong = answer(q, now, id: 'a', correct: false);
    final correct = answer(q, now, id: 'b');
    final result = LearningProgress.fromHistory(
        package: package, attempts: [wrong, correct, correct]);
    expect(result.total.correct, 1);
    expect(result.total.needsReview, 0);
    expect(result.total.notAttempted, 5);
    expect(result.days.single.answers, 2);
    expect(result.incorrectIds, isEmpty);
    final reversed = LearningProgress.fromHistory(
        package: package, attempts: [correct, wrong]);
    expect(reversed.incorrectIds, {q.id});
    expect(reversed.total.correct, 0);
    expect(reversed.total.needsReview, 1);
    expect(reversed.domains.values.fold(0, (n, d) => n + d.total), 6);
    expect(reversed.domains.values.fold(0, (n, d) => n + d.needsReview), 1);
  });
  test('persisted order remains authoritative when the clock moves backwards',
      () {
    final result = LearningProgress.fromHistory(package: package, attempts: [
      answer(q, now, id: 'new'),
      answer(q, now.subtract(const Duration(days: 1)),
          id: 'old', correct: false),
    ]);
    expect(result.total.needsReview, 1);
    expect(result.days, hasLength(2));
  });
  test('captured local date survives midnight and removed content', () {
    final result = LearningProgress.fromHistory(
        package: fixture(count: 0),
        attempts: [
          answer(q, DateTime.utc(2026, 9, 14), localDay: '2026-09-13')
        ]);
    expect(result.correctToday(DateTime(2026, 9, 13)), 1);
    expect(result.correctToday(DateTime(2026, 9, 14)), 0);
    expect(result.total.total, 0);
    expect(result.days.single.answers, 1);
  });
  test('empty history includes all configured subjects and available bank', () {
    final result = LearningProgress.fromHistory(package: package, attempts: []);
    expect(result.domains.keys, package.exam.domains.map((d) => d.id));
    expect(result.total.notAttempted, 6);
    expect(result.days, isEmpty);
  });
  MockAttempt mock({bool complete = true}) => MockAttempt(
      id: 'mock',
      examId: package.exam.id,
      questionIds: package.questions.map((q) => q.id).toList(),
      answers: {q.id: q.correctAnswerId},
      flaggedQuestionIds: {},
      status:
          complete ? MockAttemptStatus.completed : MockAttemptStatus.inProgress,
      startedAt: now,
      durationMinutes: 60,
      completedAt: complete ? now : null,
      correctCount: complete ? 1 : null);
  AnswerAttempt mockAnswer() => AnswerAttempt(
      id: 'mock-answer',
      examId: package.exam.id,
      questionId: q.id,
      domainId: q.domainId,
      topicId: q.topicId,
      difficulty: q.difficulty,
      sessionId: 'mock',
      sessionType: AttemptSessionType.mock,
      selectedAnswerId: q.correctAnswerId,
      isCorrect: true,
      answeredAt: now);
  test('frozen mock score counts answered only without inventing unique grades',
      () {
    final result = LearningProgress.fromHistory(
        package: package, attempts: [], mocks: [mock()]);
    expect(result.days.single.answers, 1);
    expect(result.days.single.incorrect, 0);
    expect(result.total.notAttempted, 5);
    expect(result.total.gradeUnavailable, 1);
    expect(result.total.total, 6);
    expect(result.hasMockDetailLimitation, isTrue);
  });
  test('completed mock AnswerAttempt avoids aggregate double count', () {
    final result = LearningProgress.fromHistory(
        package: package,
        attempts: [mockAnswer(), mockAnswer()],
        mocks: [mock()]);
    expect(result.days.single.answers, 1);
    expect(result.total.correct, 1);
    expect(result.hasMockDetailLimitation, isFalse);
  });
  test('active mock never reveals correctness', () {
    final result = LearningProgress.fromHistory(
        package: package,
        attempts: [mockAnswer()],
        mocks: [mock(complete: false)]);
    expect(result.days, isEmpty);
    expect(result.total.notAttempted, 6);
  });
  test(
      'legacy dates use local fallback and frozen correctness survives key changes',
      () {
    final old = AnswerAttempt(
        id: 'old',
        examId: package.exam.id,
        questionId: q.id,
        domainId: q.domainId,
        topicId: q.topicId,
        difficulty: q.difficulty,
        sessionId: 'practice',
        sessionType: AttemptSessionType.practice,
        selectedAnswerId: 'b',
        correctAnswerId: 'b',
        isCorrect: true,
        answeredAt: now);
    expect(q.correctAnswerId, 'a');
    final result =
        LearningProgress.fromHistory(package: package, attempts: [old]);
    expect(result.total.correct, 1);
    expect(result.days.single.date, LearningProgress.localDate(now.toLocal()));
  });
  test('a later dated grade resolves an aggregate-only mock question', () {
    final result = LearningProgress.fromHistory(package: package, attempts: [
      answer(q, now.add(const Duration(days: 1)), id: 'later', correct: false)
    ], mocks: [
      mock(),
      mock()
    ]);
    expect(result.total.gradeUnavailable, 0);
    expect(result.incorrectIds, {q.id});
    expect(result.days.fold(0, (n, d) => n + d.answers), 2);
  });
  test('partial imported mock grades are not expanded or double counted', () {
    final partial =
        mock().copyWith(answers: {q.id: 'a', package.questions[1].id: 'b'});
    final result = LearningProgress.fromHistory(
        package: package, attempts: [mockAnswer()], mocks: [partial]);
    expect(result.total.correct, 1);
    expect(result.total.gradeUnavailable, 1);
    expect(result.days.single.answers, 1);
    expect(result.hasMockDetailLimitation, isTrue);
  });
}
