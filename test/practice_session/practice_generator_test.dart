import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/models/readiness_band.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import 'package:danb_rhs_prep/practice_session/practice_generator.dart';

const String _examId = 'test_exam';

ExamConfig _buildExamConfig({double practicePassingPercent = 70}) {
  return ExamConfig(
    id: _examId,
    name: 'Test Exam',
    provider: 'Test Provider',
    examVersion: 'v1',
    contentVersion: '1.0',
    domains: const [
      DomainConfig(id: 'd1', name: 'Domain 1', weight: 0.5, topics: [
        TopicConfig(id: 't1', name: 'Topic 1'),
        TopicConfig(id: 't1b', name: 'Topic 1B'),
      ]),
      DomainConfig(id: 'd2', name: 'Domain 2', weight: 0.5, topics: [
        TopicConfig(id: 't2', name: 'Topic 2'),
      ]),
    ],
    mockExam: MockExamConfig(
      questionCount: 2,
      durationMinutes: 10,
      practicePassingPercent: practicePassingPercent,
      allowsBackNavigation: true,
      timed: false,
    ),
    officialScoring: const OfficialScoringConfig(
      scaleMinimum: 200,
      scaleMaximum: 800,
      passingScaledScore: 400,
      isComputerAdaptive: false,
    ),
    readiness: const ReadinessConfig(
      weights: ReadinessWeights(
        recentAccuracy: 0.2,
        domainMastery: 0.2,
        mockPerformance: 0.2,
        repeatedMastery: 0.2,
        coverage: 0.2,
      ),
      thresholds: [
        ReadinessThreshold(
            minimum: 0, label: 'Starting', band: ReadinessBand.starting),
        ReadinessThreshold(
            minimum: 50, label: 'Developing', band: ReadinessBand.developing),
        ReadinessThreshold(
            minimum: 80, label: 'Exam Ready', band: ReadinessBand.examReady),
      ],
      priorScore: 0,
      minimumEvidenceQuestions: 5,
      recencyHalfLifeDays: 14,
      weakDomainPenalty: 0.1,
    ),
    subscriptionProductIds: const SubscriptionProductIds(
        weekly: 'w', monthly: 'm', threeMonths: '3m'),
    freeTier: const FreeTierConfig(
        dailyPracticeQuestions: 5,
        diagnosticQuestions: 10,
        includedMockExams: 1),
    disclaimer: 'Test disclaimer.',
  );
}

Question _buildQuestion({
  required String id,
  required String domainId,
  required String topicId,
  QuestionStatus status = QuestionStatus.approved,
  List<String> tags = const [],
  String text = 'What is 2 + 2?',
}) {
  return Question(
    id: id,
    examId: _examId,
    domainId: domainId,
    topicId: topicId,
    questionText: text,
    answers: const [Answer(id: 'a', text: '4'), Answer(id: 'b', text: '5')],
    correctAnswerId: 'a',
    explanation:
        'This is a sufficiently long explanation for validation purposes.',
    references: const [],
    difficulty: 1,
    status: status,
    version: 1,
    updatedAt: DateTime.utc(2026, 1, 1),
    sourceVersion: '1.0',
    tags: tags,
  );
}

ContentPackage _buildPackage(
  List<Question> questions, {
  double practicePassingPercent = 70,
}) {
  final exam = _buildExamConfig(practicePassingPercent: practicePassingPercent);
  return ContentPackage(
    exam: exam,
    contentVersion: exam.contentVersion,
    sourceVersion: '1.0',
    generatedAt: DateTime.utc(2026, 1, 1),
    questions: questions,
  );
}

QuestionState _seenState({
  required String questionId,
  required int timesSeen,
  required int timesCorrect,
  required int timesIncorrect,
}) {
  return QuestionState(
    examId: _examId,
    questionId: questionId,
    bookmarked: false,
    timesSeen: timesSeen,
    timesCorrect: timesCorrect,
    timesIncorrect: timesIncorrect,
    consecutiveCorrect: 0,
    lastAnsweredAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('saved questions', () {
    final questions = [
      _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1'),
      _buildQuestion(id: 'q2', domainId: 'd2', topicId: 't2'),
      _buildQuestion(
          id: 'q3',
          domainId: 'd1',
          topicId: 't1',
          status: QuestionStatus.retired),
      _buildQuestion(id: 'q4', domainId: 'd1', topicId: 't1'),
    ];
    final states = [
      for (final id in ['q1', 'q2', 'q3', 'missing'])
        QuestionState.unseen(examId: _examId, questionId: id)
            .copyWith(bookmarked: true),
      QuestionState.unseen(examId: 'another_exam', questionId: 'q4')
          .copyWith(bookmarked: true),
    ];
    test(
        'includes unseen bookmarks, excludes retired, missing and other-exam records',
        () {
      final generator = PracticeGenerator.select(
          package: _buildPackage(questions),
          questionStates: states,
          requestedCount: 20,
          focus: PracticeFocus.bookmarkedQuestions);
      expect(generator.questions.map((q) => q.id), ['q1', 'q2']);
    });
    test('combines bookmarks with topic selection and count limits', () {
      final generator = PracticeGenerator.select(
          package: _buildPackage(questions),
          questionStates: states,
          requestedCount: 20,
          maxCount: 1,
          domainId: 'd2',
          topicId: 't2',
          focus: PracticeFocus.bookmarkedQuestions);
      expect(generator.questions.map((q) => q.id), ['q2']);
    });
    test('removing bookmarks does not fall back to all questions', () {
      expect(
          () => PracticeGenerator.select(
              package: _buildPackage(questions),
              questionStates:
                  states.map((s) => s.copyWith(bookmarked: false)).toList(),
              requestedCount: 5,
              focus: PracticeFocus.bookmarkedQuestions),
          throwsA(isA<PracticeGenerationUnavailable>().having((e) => e.message,
              'message', contains('No saved questions match'))));
    });
    test('an empty topic does not pull saved questions from a different topic',
        () {
      expect(
          () => PracticeGenerator.select(
              package: _buildPackage(questions),
              questionStates: states,
              requestedCount: 5,
              topicId: 't1b',
              focus: PracticeFocus.bookmarkedQuestions),
          throwsA(isA<PracticeGenerationUnavailable>()));
    });
  });
  group('approved-only and basic count enforcement', () {
    test('excludes non-approved questions from the pool', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1'),
        _buildQuestion(
            id: 'q2',
            domainId: 'd1',
            topicId: 't1',
            status: QuestionStatus.draft),
        _buildQuestion(
            id: 'q3',
            domainId: 'd1',
            topicId: 't1',
            status: QuestionStatus.retired),
      ];
      final generator = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: const [],
        requestedCount: 10,
      );

      expect(generator.questions.map((q) => q.id), ['q1']);
    });

    test('caps at requestedCount when more approved questions are available',
        () {
      final questions = List.generate(
          10, (i) => _buildQuestion(id: 'q$i', domainId: 'd1', topicId: 't1'));
      final generator = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: const [],
        requestedCount: 5,
      );

      expect(generator.questions, hasLength(5));
      expect(generator.requestedCount, 5);
    });

    test('never returns a duplicate question id', () {
      final questions = List.generate(
          8, (i) => _buildQuestion(id: 'q$i', domainId: 'd1', topicId: 't1'));
      final generator = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: const [],
        requestedCount: 20,
      );

      expect(generator.questions.map((q) => q.id).toSet(),
          hasLength(generator.questions.length));
    });

    test(
        'is deterministic: the same inputs always produce the same '
        'selection', () {
      final questions = List.generate(
          10, (i) => _buildQuestion(id: 'q$i', domainId: 'd1', topicId: 't1'));
      final package = _buildPackage(questions);

      final first = PracticeGenerator.select(
          package: package, questionStates: const [], requestedCount: 5);
      final second = PracticeGenerator.select(
          package: package, questionStates: const [], requestedCount: 5);

      expect(
          first.questions.map((q) => q.id), second.questions.map((q) => q.id));
    });

    test(
        'does not restrict requestedCount to 5/10/20 — the engine is not '
        'coupled to a specific picker UI', () {
      final questions = List.generate(
          10, (i) => _buildQuestion(id: 'q$i', domainId: 'd1', topicId: 't1'));
      final generator = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: const [],
        requestedCount: 7,
      );

      expect(generator.questions, hasLength(7));
    });

    test('rejects a non-positive requestedCount', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1')
      ];
      expect(
        () => PracticeGenerator.select(
          package: _buildPackage(questions),
          questionStates: const [],
          requestedCount: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('small pool and no-questions edge cases', () {
    test(
        'a pool smaller than requestedCount returns every eligible '
        'question, not an error', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1'),
        _buildQuestion(id: 'q2', domainId: 'd1', topicId: 't1'),
      ];
      final generator = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: const [],
        requestedCount: 20,
      );

      expect(generator.questions, hasLength(2));
      expect(generator.requestedCount, 20,
          reason: 'requestedCount is what was asked for, not what was '
              'available — callers compare the two for "N of M" messaging');
    });

    test('zero eligible questions throws PracticeGenerationUnavailable', () {
      expect(
        () => PracticeGenerator.select(
          package: _buildPackage(const []),
          questionStates: const [],
          requestedCount: 10,
        ),
        throwsA(isA<PracticeGenerationUnavailable>()),
      );
    });

    test(
        'a filter that matches nothing (e.g. an empty weak-areas pool) '
        'throws PracticeGenerationUnavailable, never an empty session', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1')
      ];
      expect(
        () => PracticeGenerator.select(
          package: _buildPackage(questions),
          questionStates: const [],
          requestedCount: 10,
          focus: PracticeFocus.incorrectQuestions,
        ),
        throwsA(isA<PracticeGenerationUnavailable>()),
      );
    });
  });

  group('domain and topic filters', () {
    test('domainId restricts the pool to that domain only', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1'),
        _buildQuestion(id: 'q2', domainId: 'd2', topicId: 't2'),
      ];
      final generator = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: const [],
        requestedCount: 10,
        domainId: 'd1',
      );

      expect(generator.questions.map((q) => q.id), ['q1']);
    });

    test(
        'topicId restricts the pool to that topic only, even within the '
        'same domain', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1'),
        _buildQuestion(id: 'q2', domainId: 'd1', topicId: 't1b'),
      ];
      final generator = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: const [],
        requestedCount: 10,
        topicId: 't1',
      );

      expect(generator.questions.map((q) => q.id), ['q1']);
    });

    test('domainId and topicId compose together', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1'),
        _buildQuestion(id: 'q2', domainId: 'd1', topicId: 't1b'),
        _buildQuestion(id: 'q3', domainId: 'd2', topicId: 't2'),
      ];
      final generator = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: const [],
        requestedCount: 10,
        domainId: 'd1',
        topicId: 't1b',
      );

      expect(generator.questions.map((q) => q.id), ['q2']);
    });
  });

  group('incorrect-questions focus', () {
    test('selects only the supplied current incorrect question IDs', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1'),
        _buildQuestion(id: 'q2', domainId: 'd1', topicId: 't1'),
        _buildQuestion(id: 'q3', domainId: 'd1', topicId: 't1'),
      ];
      final states = [
        _seenState(
            questionId: 'q1', timesSeen: 3, timesCorrect: 3, timesIncorrect: 0),
        _seenState(
            questionId: 'q2', timesSeen: 2, timesCorrect: 1, timesIncorrect: 1),
      ];
      final generator = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: states,
        requestedCount: 10,
        focus: PracticeFocus.incorrectQuestions,
        currentIncorrectIds: const {'q2'},
      );

      expect(generator.questions.map((q) => q.id), ['q2']);
    });

    test(
        'a question state for a question no longer in the content '
        'package is ignored, not a crash', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1')
      ];
      final states = [
        _seenState(
            questionId: 'retired-question',
            timesSeen: 1,
            timesCorrect: 0,
            timesIncorrect: 1),
      ];

      expect(
        () => PracticeGenerator.select(
          package: _buildPackage(questions),
          questionStates: states,
          requestedCount: 10,
          focus: PracticeFocus.incorrectQuestions,
          currentIncorrectIds: const {'q2'},
        ),
        throwsA(isA<PracticeGenerationUnavailable>()),
        reason: 'q1 has no history at all, so the incorrect-only pool is '
            'genuinely empty — the stale state must not fabricate a match',
      );
    });
  });

  group('weak-areas focus', () {
    test(
        'selects questions from a topic whose aggregate accuracy is '
        'below the weak threshold, excluding a topic at or above it', () {
      final questions = [
        _buildQuestion(id: 'weak-1', domainId: 'd1', topicId: 't1'),
        _buildQuestion(id: 'weak-2', domainId: 'd1', topicId: 't1'),
        _buildQuestion(id: 'strong-1', domainId: 'd2', topicId: 't2'),
      ];
      final states = [
        // Topic t1: 1 correct / 4 seen = 25% — below threshold.
        _seenState(
            questionId: 'weak-1',
            timesSeen: 3,
            timesCorrect: 0,
            timesIncorrect: 3),
        _seenState(
            questionId: 'weak-2',
            timesSeen: 1,
            timesCorrect: 1,
            timesIncorrect: 0),
        // Topic t2: 9 correct / 10 seen = 90% — at/above threshold.
        _seenState(
            questionId: 'strong-1',
            timesSeen: 10,
            timesCorrect: 9,
            timesIncorrect: 1),
      ];
      final generator = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: states,
        requestedCount: 10,
        focus: PracticeFocus.weakAreas,
      );

      expect(
          generator.questions.map((q) => q.id).toSet(), {'weak-1', 'weak-2'});
    });

    test(
        'a topic with no recorded history at all is never "weak" — '
        'weakness requires actual evidence, not an assumption', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1')
      ];

      expect(
        () => PracticeGenerator.select(
          package: _buildPackage(questions),
          questionStates: const [],
          requestedCount: 10,
          focus: PracticeFocus.weakAreas,
        ),
        throwsA(isA<PracticeGenerationUnavailable>()),
      );
    });

    test(
        'a topic exactly at the weak threshold is not weak (strictly '
        'below only)', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1')
      ];
      final states = [
        _seenState(
            questionId: 'q1',
            timesSeen: 10,
            timesCorrect: 7,
            timesIncorrect: 3),
      ];

      expect(
        () => PracticeGenerator.select(
          package: _buildPackage(questions),
          questionStates: states,
          requestedCount: 10,
          focus: PracticeFocus.weakAreas,
        ),
        throwsA(isA<PracticeGenerationUnavailable>()),
        reason: '70% accuracy is exactly the threshold, not below it',
      );
    });

    test(
        'the weak threshold is derived from the package\'s own '
        'practicePassingPercent, not a hard-coded 70% — a topic at 60% is '
        'weak under a 70% passing bar but not under a 50% one', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1'),
      ];
      final states = [
        // 6 correct / 10 seen = 60% accuracy.
        _seenState(
            questionId: 'q1',
            timesSeen: 10,
            timesCorrect: 6,
            timesIncorrect: 4),
      ];

      final underDefaultThreshold = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: states,
        requestedCount: 10,
        focus: PracticeFocus.weakAreas,
      );
      expect(underDefaultThreshold.questions.map((q) => q.id), ['q1'],
          reason: '60% < 70% (this package\'s practicePassingPercent), so '
              'the topic is weak');

      expect(
        () => PracticeGenerator.select(
          package: _buildPackage(questions, practicePassingPercent: 50),
          questionStates: states,
          requestedCount: 10,
          focus: PracticeFocus.weakAreas,
        ),
        throwsA(isA<PracticeGenerationUnavailable>()),
        reason: '60% >= 50% (a lower configured passing percent), so the '
            'same topic is no longer weak — proving the threshold is read '
            'from content, not hard-coded',
      );
    });
  });

  group('free-tier maxCount', () {
    test('caps the selection below requestedCount when maxCount is smaller',
        () {
      final questions = List.generate(
          10, (i) => _buildQuestion(id: 'q$i', domainId: 'd1', topicId: 't1'));
      final generator = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: const [],
        requestedCount: 20,
        maxCount: 3,
      );

      expect(generator.questions, hasLength(3));
    });

    test(
        'maxCount of zero throws a distinct "limit reached" message, not '
        '"no eligible questions"', () {
      final questions = [
        _buildQuestion(id: 'q1', domainId: 'd1', topicId: 't1')
      ];

      expect(
        () => PracticeGenerator.select(
          package: _buildPackage(questions),
          questionStates: const [],
          requestedCount: 10,
          maxCount: 0,
        ),
        throwsA(isA<PracticeGenerationUnavailable>().having(
          (e) => e.message,
          'message',
          contains('limit'),
        )),
      );
    });

    test('a null maxCount means no additional cap beyond requestedCount', () {
      final questions = List.generate(
          10, (i) => _buildQuestion(id: 'q$i', domainId: 'd1', topicId: 't1'));
      final generator = PracticeGenerator.select(
        package: _buildPackage(questions),
        questionStates: const [],
        requestedCount: 6,
      );

      expect(generator.questions, hasLength(6));
    });
  });

  group('demo content (mirrors MockExamBlueprint)', () {
    test(
        'a well-formed demo package selects from its draft demo '
        'questions, since approved-only would otherwise leave nothing '
        'to practice with in debug/test builds', () {
      final demoExam = ExamConfig(
        id: 'demo_test_exam',
        name: 'Demo Exam',
        provider: 'Test Provider',
        examVersion: 'v1',
        contentVersion: '1.0',
        domains: const [
          DomainConfig(id: 'd1', name: 'Domain 1', weight: 1.0, topics: [
            TopicConfig(id: 't1', name: 'Topic 1'),
          ]),
        ],
        mockExam: const MockExamConfig(
            questionCount: 1,
            durationMinutes: 10,
            practicePassingPercent: 70,
            allowsBackNavigation: true,
            timed: false),
        officialScoring: const OfficialScoringConfig(
            scaleMinimum: 200,
            scaleMaximum: 800,
            passingScaledScore: 400,
            isComputerAdaptive: false),
        readiness: _buildExamConfig().readiness,
        subscriptionProductIds: const SubscriptionProductIds(
            weekly: 'w', monthly: 'm', threeMonths: '3m'),
        freeTier: const FreeTierConfig(
            dailyPracticeQuestions: 5,
            diagnosticQuestions: 10,
            includedMockExams: 1),
        disclaimer: 'Test disclaimer.',
      );
      final demoQuestions = [
        Question(
          id: 'demo-q1',
          examId: 'demo_test_exam',
          domainId: 'd1',
          topicId: 't1',
          questionText: '[Demo] What is 2 + 2?',
          answers: const [
            Answer(id: 'a', text: '4'),
            Answer(id: 'b', text: '5')
          ],
          correctAnswerId: 'a',
          explanation: 'This is a demo explanation of sufficient length here.',
          references: const [],
          difficulty: 1,
          status: QuestionStatus.draft,
          version: 1,
          updatedAt: DateTime.utc(2026, 1, 1),
          sourceVersion: 'demo-fixtures-v1',
          tags: const ['demo'],
        ),
      ];
      final package = ContentPackage(
        exam: demoExam,
        contentVersion: demoExam.contentVersion,
        sourceVersion: '1.0',
        generatedAt: DateTime.utc(2026, 1, 1),
        questions: demoQuestions,
      );

      final generator = PracticeGenerator.select(
        package: package,
        questionStates: const [],
        requestedCount: 5,
      );

      expect(generator.questions.map((q) => q.id), ['demo-q1']);
    });

    test(
        'demo mode requires MockExamBlueprint.ensureDemoAllowed to pass '
        '— reusing the same production/profile AOT gate, not a second '
        'one', () {
      // A plain sanity check that this doesn't throw in the debug/test
      // environment this suite runs in; the actual product/profile AOT
      // block is proven once, generically, by
      // test/debug/demo_release_isolation_test.dart.
      expect(MockExamBlueprint.ensureDemoAllowed, returnsNormally);
    });
  });

  group('maxFreePracticeQuestionsToday', () {
    test('an active premium entitlement has no limit at all', () {
      final entitlement = Entitlement(
        tier: EntitlementTier.premium,
        source: EntitlementSource.purchase,
        lastVerifiedAt: DateTime.utc(2026, 1, 1),
      );

      final result = maxFreePracticeQuestionsToday(
        entitlement: entitlement,
        now: DateTime.utc(2026, 1, 1),
        answeredToday: 100,
        dailyLimit: 5,
      );

      expect(result, isNull);
    });

    test('a free entitlement under the limit gets the remaining allowance', () {
      final result = maxFreePracticeQuestionsToday(
        entitlement: Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1)),
        now: DateTime.utc(2026, 1, 1),
        answeredToday: 2,
        dailyLimit: 5,
      );

      expect(result, 3);
    });

    test(
        'a free entitlement at or beyond the limit gets zero, never '
        'negative', () {
      final atLimit = maxFreePracticeQuestionsToday(
        entitlement: Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1)),
        now: DateTime.utc(2026, 1, 1),
        answeredToday: 5,
        dailyLimit: 5,
      );
      final overLimit = maxFreePracticeQuestionsToday(
        entitlement: Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1)),
        now: DateTime.utc(2026, 1, 1),
        answeredToday: 9,
        dailyLimit: 5,
      );

      expect(atLimit, 0);
      expect(overLimit, 0);
    });

    test('an expired premium entitlement is treated as free', () {
      final expired = Entitlement(
        tier: EntitlementTier.premium,
        source: EntitlementSource.purchase,
        lastVerifiedAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 1, 2),
      );

      final result = maxFreePracticeQuestionsToday(
        entitlement: expired,
        now: DateTime.utc(2026, 2, 1),
        answeredToday: 2,
        dailyLimit: 5,
      );

      expect(result, 3);
    });
  });

  group('practiceAttemptsAnsweredToday', () {
    AnswerAttempt buildAttempt({
      required String id,
      required AttemptSessionType sessionType,
      required DateTime answeredAt,
    }) {
      return AnswerAttempt(
        id: id,
        examId: _examId,
        questionId: 'q1',
        domainId: 'd1',
        topicId: 't1',
        difficulty: 1,
        sessionId: 'session-1',
        sessionType: sessionType,
        selectedAnswerId: 'a',
        isCorrect: true,
        answeredAt: answeredAt,
      );
    }

    test('counts only practice-type attempts from today (UTC)', () {
      final now = DateTime.utc(2026, 3, 5, 12);
      final attempts = [
        buildAttempt(
            id: 'a1',
            sessionType: AttemptSessionType.practice,
            answeredAt: DateTime.utc(2026, 3, 5, 1)),
        buildAttempt(
            id: 'a2',
            sessionType: AttemptSessionType.practice,
            answeredAt: DateTime.utc(2026, 3, 5, 23, 59)),
        buildAttempt(
            id: 'a3',
            sessionType: AttemptSessionType.mock,
            answeredAt: DateTime.utc(2026, 3, 5, 12)),
        buildAttempt(
            id: 'a4',
            sessionType: AttemptSessionType.diagnostic,
            answeredAt: DateTime.utc(2026, 3, 5, 12)),
        buildAttempt(
            id: 'a5',
            sessionType: AttemptSessionType.practice,
            answeredAt: DateTime.utc(2026, 3, 4, 23, 59)),
      ];

      final result =
          practiceAttemptsAnsweredToday(attempts: attempts, now: now);

      expect(result, 2,
          reason: 'only a1 and a2 are practice-type and answered on the '
              'same UTC calendar day as now; a3/a4 are the wrong session '
              'type and a5 is the previous UTC day');
    });

    test('a local-time DateTime is normalized to UTC before comparing', () {
      final now = DateTime.utc(2026, 3, 5, 12);
      final localAnsweredAt = DateTime.utc(2026, 3, 5, 8).toLocal();
      final attempts = [
        buildAttempt(
            id: 'a1',
            sessionType: AttemptSessionType.practice,
            answeredAt: localAnsweredAt),
      ];

      expect(practiceAttemptsAnsweredToday(attempts: attempts, now: now), 1);
    });

    test('an empty attempt list is zero', () {
      expect(
        practiceAttemptsAnsweredToday(
            attempts: const [], now: DateTime.utc(2026, 3, 5)),
        0,
      );
    });
  });
}
