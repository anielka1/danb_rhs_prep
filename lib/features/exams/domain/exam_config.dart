import '../../../domain/models/readiness_band.dart';

class ReadinessThreshold {
  const ReadinessThreshold({
    required this.minimum,
    required this.label,
    required this.band,
  });

  final int minimum;
  final String label;
  final ReadinessBand band;

  factory ReadinessThreshold.fromJson(Map<String, Object?> json) {
    return ReadinessThreshold(
      minimum: _int(json['minimum']),
      label: _string(json['label']),
      band: ReadinessBand.values.firstWhere(
        (value) => value.name == json['band'],
        orElse: () => ReadinessBand.starting,
      ),
    );
  }
}

class ReadinessWeights {
  const ReadinessWeights({
    required this.recentAccuracy,
    required this.domainMastery,
    required this.mockPerformance,
    required this.repeatedMastery,
    required this.coverage,
  });

  final double recentAccuracy;
  final double domainMastery;
  final double mockPerformance;
  final double repeatedMastery;
  final double coverage;

  double get total =>
      recentAccuracy +
      domainMastery +
      mockPerformance +
      repeatedMastery +
      coverage;

  factory ReadinessWeights.fromJson(Map<String, Object?> json) {
    return ReadinessWeights(
      recentAccuracy: _double(json['recentAccuracy']),
      domainMastery: _double(json['domainMastery']),
      mockPerformance: _double(json['mockPerformance']),
      repeatedMastery: _double(json['repeatedMastery']),
      coverage: _double(json['coverage']),
    );
  }
}

class ReadinessConfig {
  const ReadinessConfig({
    required this.weights,
    required this.thresholds,
    required this.priorScore,
    required this.minimumEvidenceQuestions,
    required this.recencyHalfLifeDays,
    required this.weakDomainPenalty,
  });

  final ReadinessWeights weights;
  final List<ReadinessThreshold> thresholds;
  final double priorScore;
  final int minimumEvidenceQuestions;
  final double recencyHalfLifeDays;
  final double weakDomainPenalty;

  factory ReadinessConfig.fromJson(Map<String, Object?> json) {
    return ReadinessConfig(
      weights: ReadinessWeights.fromJson(_map(json['weights'])),
      thresholds: _list(json['thresholds'])
          .map((item) => ReadinessThreshold.fromJson(_map(item)))
          .toList(growable: false),
      priorScore: _double(json['priorScore']),
      minimumEvidenceQuestions: _int(json['minimumEvidenceQuestions']),
      recencyHalfLifeDays: _double(json['recencyHalfLifeDays']),
      weakDomainPenalty: _double(json['weakDomainPenalty']),
    );
  }
}

class TopicConfig {
  const TopicConfig({required this.id, required this.name});

  final String id;
  final String name;

  factory TopicConfig.fromJson(Map<String, Object?> json) {
    return TopicConfig(id: _string(json['id']), name: _string(json['name']));
  }
}

class DomainConfig {
  const DomainConfig({
    required this.id,
    required this.name,
    required this.weight,
    required this.topics,
  });

  final String id;
  final String name;
  final double weight;
  final List<TopicConfig> topics;

  factory DomainConfig.fromJson(Map<String, Object?> json) {
    return DomainConfig(
      id: _string(json['id']),
      name: _string(json['name']),
      weight: _double(json['weight']),
      topics: _list(json['topics'])
          .map((item) => TopicConfig.fromJson(_map(item)))
          .toList(growable: false),
    );
  }
}

class MockExamConfig {
  const MockExamConfig({
    required this.questionCount,
    required this.durationMinutes,
    required this.practicePassingPercent,
    required this.allowsBackNavigation,
    required this.timed,
  });

  final int questionCount;
  final int durationMinutes;
  final double practicePassingPercent;
  final bool allowsBackNavigation;
  final bool timed;

  factory MockExamConfig.fromJson(Map<String, Object?> json) {
    return MockExamConfig(
      questionCount: _int(json['questionCount']),
      durationMinutes: _int(json['durationMinutes']),
      practicePassingPercent: _double(json['practicePassingPercent']),
      allowsBackNavigation: _bool(json['allowsBackNavigation']),
      timed: _bool(json['timed']),
    );
  }
}

class OfficialScoringConfig {
  const OfficialScoringConfig({
    required this.scaleMinimum,
    required this.scaleMaximum,
    required this.passingScaledScore,
    required this.isComputerAdaptive,
  });

  final int scaleMinimum;
  final int scaleMaximum;
  final int passingScaledScore;
  final bool isComputerAdaptive;

  factory OfficialScoringConfig.fromJson(Map<String, Object?> json) {
    return OfficialScoringConfig(
      scaleMinimum: _int(json['scaleMinimum']),
      scaleMaximum: _int(json['scaleMaximum']),
      passingScaledScore: _int(json['passingScaledScore']),
      isComputerAdaptive: _bool(json['isComputerAdaptive']),
    );
  }
}

class SubscriptionProductIds {
  const SubscriptionProductIds({
    required this.weekly,
    required this.monthly,
    required this.threeMonths,
  });

  final String weekly;
  final String monthly;
  final String threeMonths;

  List<String> get all => [weekly, monthly, threeMonths];

  factory SubscriptionProductIds.fromJson(Map<String, Object?> json) {
    return SubscriptionProductIds(
      weekly: _string(json['weekly']),
      monthly: _string(json['monthly']),
      threeMonths: _string(json['threeMonths']),
    );
  }
}

class FreeTierConfig {
  const FreeTierConfig({
    required this.dailyPracticeQuestions,
    required this.diagnosticQuestions,
    required this.includedMockExams,
  });

  final int dailyPracticeQuestions;
  final int diagnosticQuestions;
  final int includedMockExams;

  factory FreeTierConfig.fromJson(Map<String, Object?> json) {
    return FreeTierConfig(
      dailyPracticeQuestions: _int(json['dailyPracticeQuestions']),
      diagnosticQuestions: _int(json['diagnosticQuestions']),
      includedMockExams: _int(json['includedMockExams']),
    );
  }
}

class ExamConfig {
  const ExamConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.examVersion,
    required this.contentVersion,
    required this.domains,
    required this.mockExam,
    required this.officialScoring,
    required this.readiness,
    required this.subscriptionProductIds,
    required this.freeTier,
    required this.disclaimer,
  });

  final String id;
  final String name;
  final String provider;
  final String examVersion;
  final String contentVersion;
  final List<DomainConfig> domains;
  final MockExamConfig mockExam;
  final OfficialScoringConfig officialScoring;
  final ReadinessConfig readiness;
  final SubscriptionProductIds subscriptionProductIds;
  final FreeTierConfig freeTier;
  final String disclaimer;

  factory ExamConfig.fromJson(Map<String, Object?> json) {
    return ExamConfig(
      id: _string(json['id']),
      name: _string(json['name']),
      provider: _string(json['provider']),
      examVersion: _string(json['examVersion']),
      contentVersion: _string(json['contentVersion']),
      domains: _list(json['domains'])
          .map((item) => DomainConfig.fromJson(_map(item)))
          .toList(growable: false),
      mockExam: MockExamConfig.fromJson(_map(json['mockExam'])),
      officialScoring: OfficialScoringConfig.fromJson(
        _map(json['officialScoring']),
      ),
      readiness: ReadinessConfig.fromJson(_map(json['readiness'])),
      subscriptionProductIds: SubscriptionProductIds.fromJson(
        _map(json['subscriptionProductIds']),
      ),
      freeTier: FreeTierConfig.fromJson(_map(json['freeTier'])),
      disclaimer: _string(json['disclaimer']),
    );
  }
}

Map<String, Object?> _map(Object? value) {
  return value is Map<String, Object?> ? value : const <String, Object?>{};
}

List<Object?> _list(Object? value) {
  return value is List<Object?> ? value : const <Object?>[];
}

String _string(Object? value) => value is String ? value.trim() : '';
int _int(Object? value) => value is num ? value.toInt() : 0;
double _double(Object? value) => value is num ? value.toDouble() : 0;
bool _bool(Object? value) => value is bool ? value : false;
