import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/readiness_band.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';

void main() {
  ReadinessSnapshot buildSnapshot({
    double overallScore = 62,
    double evidenceConfidence = 0.8,
  }) {
    return ReadinessSnapshot(
      id: 'snapshot-1',
      examId: 'danb-rhs',
      calculatedAt: DateTime.utc(2026, 1, 1),
      overallScore: overallScore,
      band: ReadinessBand.gettingClose,
      recentAccuracyComponent: 65,
      domainMasteryComponent: 60,
      mockPerformanceComponent: 50,
      repeatedMasteryComponent: 70,
      coverageComponent: 55,
      evidenceConfidence: evidenceConfidence,
      uniqueQuestionsAnswered: 120,
    );
  }

  test('equal field values produce equal instances and hash codes', () {
    final a = buildSnapshot();
    final b = buildSnapshot();
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('reuses the shared ReadinessBand enum', () {
    final snapshot = buildSnapshot();
    expect(snapshot.band, ReadinessBand.gettingClose);
  });

  test('an overall score outside 0-100 violates the invariant', () {
    expect(
      () => buildSnapshot(overallScore: 101),
      throwsArgumentError,
    );
    expect(
      () => buildSnapshot(overallScore: -1),
      throwsArgumentError,
    );
  });

  test('an evidence confidence outside 0-1 violates the invariant', () {
    expect(
      () => buildSnapshot(evidenceConfidence: 1.1),
      throwsArgumentError,
    );
  });
}
