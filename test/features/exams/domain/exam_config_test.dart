import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/readiness_band.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';

void main() {
  group('ExamConfig.fromJson', () {
    Map<String, Object?> validJson() => {
          'id': 'danb-rhs',
          'name': 'DANB RHS',
          'provider': 'DANB',
          'examVersion': '1',
          'contentVersion': '2026.1',
          'domains': [
            {
              'id': 'domain-1',
              'name': 'Radiation Safety',
              'weight': 0.6,
              'topics': [
                {'id': 'topic-1', 'name': 'Shielding'},
              ],
            },
          ],
          'mockExam': {
            'questionCount': 100,
            'durationMinutes': 90,
            'practicePassingPercent': 80,
            'allowsBackNavigation': true,
            'timed': true,
          },
          'officialScoring': {
            'scaleMinimum': 200,
            'scaleMaximum': 800,
            'passingScaledScore': 400,
            'isComputerAdaptive': false,
          },
          'readiness': {
            'weights': {
              'recentAccuracy': 0.3,
              'domainMastery': 0.25,
              'mockPerformance': 0.25,
              'repeatedMastery': 0.1,
              'coverage': 0.1,
            },
            'thresholds': [
              {'minimum': 75, 'label': 'Exam Ready', 'band': 'examReady'},
            ],
            'priorScore': 40,
            'minimumEvidenceQuestions': 40,
            'recencyHalfLifeDays': 21,
            'weakDomainPenalty': 0.1,
          },
          'subscriptionProductIds': {
            'weekly': 'w',
            'monthly': 'm',
            'threeMonths': '3m',
          },
          'freeTier': {
            'dailyPracticeQuestions': 5,
            'diagnosticQuestions': 10,
            'includedMockExams': 1,
          },
          'disclaimer': 'Not an official DANB product.',
        };

    test('parses every nested config from a well-formed JSON object', () {
      final config = ExamConfig.fromJson(validJson());

      expect(config.id, 'danb-rhs');
      expect(config.domains, hasLength(1));
      expect(config.domains.single.topics.single.id, 'topic-1');
      expect(config.mockExam.questionCount, 100);
      expect(config.officialScoring.scaleMaximum, 800);
      expect(config.readiness.weights.recentAccuracy, 0.3);
      expect(config.readiness.thresholds.single.band, ReadinessBand.examReady);
      expect(config.subscriptionProductIds.all, ['w', 'm', '3m']);
      expect(config.freeTier.includedMockExams, 1);
    });

    test(
        'missing fields fall back to honest empty/zero defaults, never a '
        'guessed value', () {
      final config = ExamConfig.fromJson(const <String, Object?>{});

      expect(config.id, '');
      expect(config.domains, isEmpty);
      expect(config.mockExam.questionCount, 0);
      expect(config.mockExam.allowsBackNavigation, isFalse);
      expect(config.readiness.thresholds, isEmpty);
      expect(config.disclaimer, '');
    });

    test(
        'an unrecognized readiness band falls back to starting, never a '
        'guessed higher band', () {
      final json = validJson();
      (json['readiness']! as Map<String, Object?>)['thresholds'] = [
        {'minimum': 0, 'label': 'Mystery', 'band': 'not_a_real_band'},
      ];
      final config = ExamConfig.fromJson(json);
      expect(config.readiness.thresholds.single.band, ReadinessBand.starting);
    });
  });

  test('ReadinessWeights.total sums every component', () {
    const weights = ReadinessWeights(
      recentAccuracy: 0.3,
      domainMastery: 0.25,
      mockPerformance: 0.25,
      repeatedMastery: 0.1,
      coverage: 0.1,
    );
    expect(weights.total, closeTo(1.0, 0.0001));
  });

  test('SubscriptionProductIds.all lists every product id in a stable order',
      () {
    const ids = SubscriptionProductIds(
      weekly: 'w',
      monthly: 'm',
      threeMonths: '3m',
    );
    expect(ids.all, ['w', 'm', '3m']);
  });
}
