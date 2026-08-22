import 'readiness_band.dart';

/// An explainable, persisted result of the readiness algorithm (see
/// `ExamConfig.readiness` for the configured weights that produced it).
///
/// Invariants, enforced by the constructor (throws [ArgumentError] if
/// violated): [overallScore] is clamped to the 0-100 range;
/// [evidenceConfidence] is clamped to 0-1.
class ReadinessSnapshot {
  ReadinessSnapshot({
    required this.id,
    required this.examId,
    required this.calculatedAt,
    required this.overallScore,
    required this.band,
    required this.recentAccuracyComponent,
    required this.domainMasteryComponent,
    required this.mockPerformanceComponent,
    required this.repeatedMasteryComponent,
    required this.coverageComponent,
    required this.evidenceConfidence,
    required this.uniqueQuestionsAnswered,
  }) {
    if (overallScore < 0 || overallScore > 100) {
      throw ArgumentError.value(
        overallScore,
        'overallScore',
        'must be clamped to 0-100.',
      );
    }
    if (evidenceConfidence < 0 || evidenceConfidence > 1) {
      throw ArgumentError.value(
        evidenceConfidence,
        'evidenceConfidence',
        'must be clamped to 0-1.',
      );
    }
  }

  final String id;
  final String examId;

  /// Always stored in UTC.
  final DateTime calculatedAt;

  final double overallScore;
  final ReadinessBand band;

  final double recentAccuracyComponent;
  final double domainMasteryComponent;
  final double mockPerformanceComponent;
  final double repeatedMasteryComponent;
  final double coverageComponent;

  final double evidenceConfidence;
  final int uniqueQuestionsAnswered;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadinessSnapshot &&
        other.id == id &&
        other.examId == examId &&
        other.calculatedAt == calculatedAt &&
        other.overallScore == overallScore &&
        other.band == band &&
        other.recentAccuracyComponent == recentAccuracyComponent &&
        other.domainMasteryComponent == domainMasteryComponent &&
        other.mockPerformanceComponent == mockPerformanceComponent &&
        other.repeatedMasteryComponent == repeatedMasteryComponent &&
        other.coverageComponent == coverageComponent &&
        other.evidenceConfidence == evidenceConfidence &&
        other.uniqueQuestionsAnswered == uniqueQuestionsAnswered;
  }

  @override
  int get hashCode => Object.hash(
        id,
        examId,
        calculatedAt,
        overallScore,
        band,
        recentAccuracyComponent,
        domainMasteryComponent,
        mockPerformanceComponent,
        repeatedMasteryComponent,
        coverageComponent,
        evidenceConfidence,
        uniqueQuestionsAnswered,
      );
}
