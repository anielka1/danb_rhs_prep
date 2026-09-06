import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';

void main() {
  ExamConfig buildExamConfig() {
    return const ExamConfig(
      id: 'danb-rhs',
      name: 'DANB RHS',
      provider: 'DANB',
      examVersion: '1',
      contentVersion: '2026.1',
      domains: [],
      mockExam: MockExamConfig(
        questionCount: 5,
        durationMinutes: 10,
        practicePassingPercent: 70,
        allowsBackNavigation: true,
        timed: false,
      ),
      officialScoring: OfficialScoringConfig(
        scaleMinimum: 200,
        scaleMaximum: 800,
        passingScaledScore: 400,
        isComputerAdaptive: false,
      ),
      readiness: ReadinessConfig(
        weights: ReadinessWeights(
          recentAccuracy: 0.3,
          domainMastery: 0.25,
          mockPerformance: 0.25,
          repeatedMastery: 0.1,
          coverage: 0.1,
        ),
        thresholds: [],
        priorScore: 40,
        minimumEvidenceQuestions: 40,
        recencyHalfLifeDays: 21,
        weakDomainPenalty: 0.1,
      ),
      subscriptionProductIds: SubscriptionProductIds(
        weekly: 'w',
        monthly: 'm',
        threeMonths: '3m',
      ),
      freeTier: FreeTierConfig(
        dailyPracticeQuestions: 5,
        diagnosticQuestions: 10,
        includedMockExams: 1,
      ),
      disclaimer: 'Not an official DANB product.',
    );
  }

  Question buildQuestion(String id, {required QuestionStatus status}) {
    return Question(
      id: id,
      examId: 'danb-rhs',
      domainId: 'domain-1',
      topicId: 'topic-1',
      questionText: 'Question $id',
      answers: const [Answer(id: 'a', text: 'Answer')],
      correctAnswerId: 'a',
      explanation: 'Because.',
      references: const [],
      difficulty: 1,
      status: status,
      version: 1,
      updatedAt: null,
      sourceVersion: '2026.1',
      tags: const [],
    );
  }

  test('approvedQuestions excludes every non-approved status', () {
    final package = ContentPackage(
      exam: buildExamConfig(),
      contentVersion: '2026.1',
      sourceVersion: '2026.1',
      generatedAt: DateTime.utc(2026, 1, 1),
      questions: [
        buildQuestion('approved-1', status: QuestionStatus.approved),
        buildQuestion('draft-1', status: QuestionStatus.draft),
        buildQuestion('reviewed-1', status: QuestionStatus.reviewed),
        buildQuestion('retired-1', status: QuestionStatus.retired),
        buildQuestion('approved-2', status: QuestionStatus.approved),
      ],
    );

    expect(
      package.approvedQuestions.map((q) => q.id),
      ['approved-1', 'approved-2'],
    );
  });

  test('approvedQuestions is empty, not an error, when no question qualifies',
      () {
    final package = ContentPackage(
      exam: buildExamConfig(),
      contentVersion: '2026.1',
      sourceVersion: '2026.1',
      generatedAt: null,
      questions: [buildQuestion('draft-1', status: QuestionStatus.draft)],
    );

    expect(package.approvedQuestions, isEmpty);
  });
}
