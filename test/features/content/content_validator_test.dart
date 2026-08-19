import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/domain/content_validation.dart';

void main() {
  late Map<String, dynamic> validJson;

  setUp(() {
    validJson = jsonDecode(
      File('assets/content/danb_rhs/content.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  Set<String> validate(Map<String, dynamic> json) {
    final package = const ExamContentCodec().decode(jsonEncode(json));
    return const ContentValidator()
        .validate(package)
        .errors
        .map((issue) => issue.code)
        .toSet();
  }

  Map<String, dynamic> firstQuestion() {
    return (validJson['questions'] as List<dynamic>).first
        as Map<String, dynamic>;
  }

  test('duplicate question IDs are rejected', () {
    final questions = validJson['questions'] as List<dynamic>;
    (questions[1] as Map<String, dynamic>)['id'] =
        (questions[0] as Map<String, dynamic>)['id'];

    expect(validate(validJson), contains('duplicate_or_missing_question_id'));
  });

  test('missing answers are rejected', () {
    firstQuestion()['answers'] = <Object?>[];

    expect(validate(validJson), contains('missing_answers'));
  });

  test('a missing or unknown correct answer is rejected', () {
    firstQuestion()['correctAnswerId'] = 'not-an-answer';

    expect(validate(validJson), contains('invalid_correct_answer'));
  });

  test('unknown domains and topics are rejected', () {
    firstQuestion()['domainId'] = 'unknown-domain';
    final domainErrors = validate(validJson);
    expect(domainErrors, contains('invalid_question_domain'));

    validJson = jsonDecode(
      File('assets/content/danb_rhs/content.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    firstQuestion()['topicId'] = 'unknown-topic';
    expect(validate(validJson), contains('invalid_question_topic'));
  });

  test('missing explanations are rejected', () {
    firstQuestion()['explanation'] = '';

    expect(validate(validJson), contains('missing_explanation'));
  });

  test('malformed references are rejected', () {
    final references = firstQuestion()['references'] as List<dynamic>;
    final reference = references.first as Map<String, dynamic>;
    reference['url'] = '://not-a-url';

    expect(validate(validJson), contains('malformed_reference_url'));
  });

  test('domain weights must total one', () {
    final exam = validJson['exam'] as Map<String, dynamic>;
    final domains = exam['domains'] as List<dynamic>;
    (domains.first as Map<String, dynamic>)['weight'] = 0.4;

    expect(validate(validJson), contains('invalid_domain_weight_total'));
  });

  test('evidence confidence grows conservatively and caps at one', () {
    expect(readinessEvidenceConfidence(0, 40), 0);
    expect(readinessEvidenceConfidence(10, 40), closeTo(0.5, 0.0001));
    expect(readinessEvidenceConfidence(100, 40), 1);
  });
}
