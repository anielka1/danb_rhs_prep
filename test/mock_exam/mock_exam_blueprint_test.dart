import 'dart:io';
import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import '../support/mock_exam_test_support.dart';

void main() {
  test('production draft bank remains unavailable without changing approval',
      () {
    final package = const ExamContentCodec().decode(
        File('assets/content/danb_rhs/content.json').readAsStringSync());
    expect(package.approvedQuestions, isEmpty);
    expect(() => MockExamBlueprint.fromPackage(package),
        throwsA(isA<MockExamUnavailable>()));
  });

  test(
      'deterministic largest-remainder blueprint preserves configured domain weights',
      () {
    final domains = [
      const DomainConfig(
          id: 'a',
          name: 'Demo A',
          weight: .5,
          topics: [TopicConfig(id: 't', name: 'Demo')]),
      const DomainConfig(
          id: 'b',
          name: 'Demo B',
          weight: .25,
          topics: [TopicConfig(id: 't', name: 'Demo')]),
      const DomainConfig(
          id: 'c',
          name: 'Demo C',
          weight: .25,
          topics: [TopicConfig(id: 't', name: 'Demo')]),
    ];
    final questions = [
      for (final d in domains)
        for (var i = 0; i < 5; i++)
          mockQuestion(id: 'demo-${d.id}-$i', domain: d.id, topic: 't')
    ];
    final package =
        mockPackage(domains: domains, questions: questions, count: 7);
    final a = MockExamBlueprint.fromPackage(package);
    final b = MockExamBlueprint.fromPackage(mockPackage(
        domains: domains, questions: questions.reversed.toList(), count: 7));
    expect(a.quotas, {'a': 3, 'b': 2, 'c': 2});
    expect(a.questions.map((q) => q.id), b.questions.map((q) => q.id));
    expect(a.questions.map((q) => q.id).toSet(), hasLength(7));
  });

  final invalidCases = <String, List<Question> Function()>{
    'empty bank': () => [],
    'insufficient bank': () => [mockQuestion()],
    'duplicate question IDs': () => List.generate(5, (_) => mockQuestion()),
    'invalid correct answer': () => [
          mockQuestion(correct: 'missing'),
          ...DebugDemoEnvironment.demoQuestions.skip(1)
        ],
    'duplicate answer IDs': () => [
          mockQuestion(answers: const [
            Answer(id: 'a', text: '4'),
            Answer(id: 'a', text: '5')
          ]),
          ...DebugDemoEnvironment.demoQuestions.skip(1)
        ],
    'unknown domain': () => [
          mockQuestion(domain: 'unknown'),
          ...DebugDemoEnvironment.demoQuestions.skip(1)
        ],
    'missing demo tag': () => [
          mockQuestion(tags: const []),
          ...DebugDemoEnvironment.demoQuestions.skip(1)
        ],
    'missing visible demo label': () => [
          mockQuestion(text: 'What is 2 + 2?'),
          ...DebugDemoEnvironment.demoQuestions.skip(1)
        ],
  };
  for (final entry in invalidCases.entries) {
    test('negative fixture: ${entry.key}', () {
      expect(
          () => MockExamBlueprint.fromPackage(
              mockPackage(questions: entry.value())),
          throwsA(isA<MockExamUnavailable>()));
    });
  }

  test('out-of-range and non-finite thresholds fail structurally', () {
    for (final threshold in [-1.0, 101.0, double.nan, double.infinity]) {
      expect(
          () =>
              MockExamBlueprint.fromPackage(mockPackage(threshold: threshold)),
          throwsA(isA<MockExamUnavailable>()));
    }
  });

  test('no result for in-progress, forged score or unresolved saved answer',
      () async {
    final controller = await startedMock();
    expect(() => controller.result, throwsFormatException);
    final attempt = controller.attempt!;
    final corrupt =
        attempt.copyWith(answers: {attempt.questionIds.first: 'missing'});
    expect(() => controller.blueprint.resolve(corrupt), throwsFormatException);
    final forged = attempt.copyWith(
        answers: {attempt.questionIds.first: 'b'},
        status: MockAttemptStatus.completed,
        completedAt: attempt.startedAt,
        correctCount: 1);
    expect(() => controller.blueprint.resultFor(forged), throwsFormatException);
  });

  test(
      'attempt model rejects invalid identities, duplicate sets, cursor and score',
      () {
    MockAttempt build(
            {List<String> ids = const ['q'],
            int index = 0,
            int duration = 10,
            int? score}) =>
        MockAttempt(
            id: 'attempt',
            examId: 'exam',
            questionIds: ids,
            answers: const {},
            flaggedQuestionIds: const {},
            status: score == null
                ? MockAttemptStatus.inProgress
                : MockAttemptStatus.completed,
            startedAt: DateTime.utc(2026),
            durationMinutes: duration,
            currentQuestionIndex: index,
            completedAt: score == null ? null : DateTime.utc(2026),
            correctCount: score);
    expect(() => build(ids: []), throwsArgumentError);
    expect(() => build(ids: ['q', 'q']), throwsArgumentError);
    expect(() => build(index: -1), throwsArgumentError);
    expect(() => build(index: 1), throwsArgumentError);
    expect(() => build(duration: 0), throwsArgumentError);
    expect(() => build(score: -1), throwsArgumentError);
    expect(() => build(score: 1), throwsArgumentError);
  });
}
