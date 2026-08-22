import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/question_report.dart';

void main() {
  QuestionReport buildReport({
    QuestionReportStatus status = QuestionReportStatus.pendingSubmission,
    String? notes,
  }) {
    return QuestionReport(
      id: 'report-1',
      examId: 'danb-rhs',
      questionId: 'q1',
      questionVersion: 3,
      contentVersion: '2026.1',
      appVersion: '1.0.0',
      category: QuestionReportCategory.incorrectAnswer,
      status: status,
      createdAt: DateTime.utc(2026, 1, 1),
      notes: notes,
    );
  }

  test('equal field values produce equal instances and hash codes', () {
    final a = buildReport();
    final b = buildReport();
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('notes are optional and do not affect other categories', () {
    final withoutNotes = buildReport();
    expect(withoutNotes.notes, isNull);

    final withNotes = buildReport(notes: 'The diagram looks outdated.');
    expect(withNotes.notes, 'The diagram looks outdated.');
  });

  test('copyWith updates only the submission status', () {
    final report = buildReport();
    final submitted = report.copyWith(status: QuestionReportStatus.submitted);

    expect(submitted.status, QuestionReportStatus.submitted);
    expect(submitted.id, report.id);
    expect(submitted.questionId, report.questionId);
  });
}
