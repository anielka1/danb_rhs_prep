import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_content_repository.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';

ExamConfig _buildExam(String id) {
  return ExamConfig(
    id: id,
    name: 'DANB RHS',
    provider: 'DANB',
    examVersion: '2026',
    contentVersion: '2026.1',
    domains: const [],
    mockExam: const MockExamConfig(
      questionCount: 75,
      durationMinutes: 60,
      practicePassingPercent: 75,
      allowsBackNavigation: true,
      timed: true,
    ),
    officialScoring: const OfficialScoringConfig(
      scaleMinimum: 200,
      scaleMaximum: 800,
      passingScaledScore: 525,
      isComputerAdaptive: true,
    ),
    readiness: const ReadinessConfig(
      weights: ReadinessWeights(
        recentAccuracy: 0.3,
        domainMastery: 0.25,
        mockPerformance: 0.25,
        repeatedMastery: 0.1,
        coverage: 0.1,
      ),
      thresholds: [],
      priorScore: 0,
      minimumEvidenceQuestions: 20,
      recencyHalfLifeDays: 14,
      weakDomainPenalty: 0.1,
    ),
    subscriptionProductIds: const SubscriptionProductIds(
      weekly: 'danb_rhs_premium_weekly',
      monthly: 'danb_rhs_premium_monthly',
      threeMonths: 'danb_rhs_premium_3_months',
    ),
    freeTier: const FreeTierConfig(
      dailyPracticeQuestions: 10,
      diagnosticQuestions: 15,
      includedMockExams: 1,
    ),
    disclaimer: 'Not affiliated with or endorsed by DANB.',
  );
}

void main() {
  test('loadContentPackage returns a registered package', () async {
    final package = ContentPackage(
      exam: _buildExam('danb-rhs'),
      contentVersion: '2026.1',
      sourceVersion: '2026.1-source',
      generatedAt: DateTime.utc(2026, 1, 1),
      questions: const [],
    );
    final repository = InMemoryContentRepository({'danb-rhs': package});

    final loaded = await repository.loadContentPackage('danb-rhs');

    expect(loaded, same(package));
  });

  test('loadContentPackage throws for an unregistered exam', () async {
    final repository = InMemoryContentRepository(const {});

    expect(
      () => repository.loadContentPackage('unknown-exam'),
      throwsStateError,
    );
  });
}
