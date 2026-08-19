import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/domain/content_validation.dart';

void main() {
  late String validSource;

  setUp(() {
    validSource = File('assets/content/danb_rhs/content.json').readAsStringSync();
  });

  test('bundled development package decodes and validates', () {
    final package = const ExamContentCodec().decode(validSource);
    final result = const ContentValidator().validate(package);

    expect(package.exam.id, 'danb_rhs');
    expect(package.exam.domains.map((domain) => domain.weight).reduce((a, b) => a + b), 1);
    expect(package.exam.mockExam.questionCount, 75);
    expect(package.exam.mockExam.durationMinutes, 60);
    expect(result.errors, isEmpty);
  });

  test('only approved questions are exposed for production sessions', () {
    final json = jsonDecode(validSource) as Map<String, dynamic>;
    final questions = json['questions'] as List<dynamic>;
    (questions.first as Map<String, dynamic>)['status'] = 'approved';

    final package = const ExamContentCodec().decode(jsonEncode(json));

    expect(package.questions, hasLength(2));
    expect(package.approvedQuestions, hasLength(1));
    expect(package.approvedQuestions.single.id, 'rhs-dev-001');
  });

  test('non-object JSON is rejected', () {
    expect(
      () => const ExamContentCodec().decode('[]'),
      throwsA(isA<FormatException>()),
    );
  });
}
