import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/features/questions/domain/question.dart';

void main() {
  Question buildQuestion({
    QuestionStatus status = QuestionStatus.approved,
    String correctAnswerId = 'a',
    List<Answer>? answers,
  }) {
    return Question(
      id: 'q1',
      examId: 'danb-rhs',
      domainId: 'domain-1',
      topicId: 'topic-1',
      questionText: 'What is 2 + 2?',
      answers: answers ??
          const [
            Answer(id: 'a', text: '4'),
            Answer(id: 'b', text: '5'),
          ],
      correctAnswerId: correctAnswerId,
      explanation: '2 + 2 = 4.',
      references: const [],
      difficulty: 2,
      status: status,
      version: 1,
      updatedAt: DateTime.utc(2026, 1, 1),
      sourceVersion: '2026.1',
      tags: const ['arithmetic'],
    );
  }

  group('isApproved', () {
    test('true only for QuestionStatus.approved', () {
      expect(buildQuestion(status: QuestionStatus.approved).isApproved, isTrue);
      for (final status in [
        QuestionStatus.draft,
        QuestionStatus.reviewed,
        QuestionStatus.retired,
        QuestionStatus.unknown,
      ]) {
        expect(buildQuestion(status: status).isApproved, isFalse,
            reason: '$status must not be treated as approved');
      }
    });
  });

  group('correctAnswer', () {
    test('returns the answer matching correctAnswerId', () {
      final question = buildQuestion(correctAnswerId: 'b');
      expect(question.correctAnswer?.id, 'b');
      expect(question.correctAnswer?.text, '5');
    });

    test('is null when no answer matches correctAnswerId', () {
      final question = buildQuestion(correctAnswerId: 'does-not-exist');
      expect(question.correctAnswer, isNull);
    });
  });

  group('Question.fromJson', () {
    Map<String, Object?> validJson() => {
          'id': 'q1',
          'examId': 'danb-rhs',
          'domainId': 'domain-1',
          'topicId': 'topic-1',
          'questionText': 'What is 2 + 2?',
          'answers': [
            {'id': 'a', 'text': '4'},
            {'id': 'b', 'text': '5', 'distractorExplanation': 'Off by one.'},
          ],
          'correctAnswerId': 'a',
          'explanation': '2 + 2 = 4.',
          'references': [
            {
              'title': 'Arithmetic Basics',
              'source': 'Demo Source',
              'section': '1.1',
              'url': 'https://example.com/arithmetic',
            },
          ],
          'difficulty': 2,
          'status': 'approved',
          'version': 3,
          'updatedAt': '2026-01-01T00:00:00.000Z',
          'sourceVersion': '2026.1',
          'tags': [' arithmetic ', '', 'basics'],
        };

    test('parses every field from a well-formed JSON object', () {
      final question = Question.fromJson(validJson());

      expect(question.id, 'q1');
      expect(question.answers, hasLength(2));
      expect(question.answers[1].distractorExplanation, 'Off by one.');
      expect(question.correctAnswerId, 'a');
      expect(question.references, hasLength(1));
      expect(question.references.single.url,
          Uri.parse('https://example.com/arithmetic'));
      expect(question.difficulty, 2);
      expect(question.status, QuestionStatus.approved);
      expect(question.version, 3);
      expect(question.updatedAt, DateTime.utc(2026, 1, 1));
      // Blank tags are dropped and remaining ones trimmed, not passed
      // through verbatim.
      expect(question.tags, ['arithmetic', 'basics']);
    });

    test(
        'an unrecognized status falls back to QuestionStatus.unknown, '
        'never a guessed default', () {
      final json = validJson()..['status'] = 'not_a_real_status';
      expect(Question.fromJson(json).status, QuestionStatus.unknown);
    });

    test('a missing status falls back to QuestionStatus.unknown', () {
      final json = validJson()..remove('status');
      expect(Question.fromJson(json).status, QuestionStatus.unknown);
    });

    test('an unparseable updatedAt is null rather than a fabricated date', () {
      final json = validJson()..['updatedAt'] = 'not-a-date';
      expect(Question.fromJson(json).updatedAt, isNull);
    });

    test(
        'a malformed answer/reference entry falls back to an empty map '
        'rather than throwing', () {
      final json = validJson()
        ..['answers'] = [
          'not-a-map',
          {'id': 'a', 'text': '4'},
        ];
      final question = Question.fromJson(json);
      expect(question.answers, hasLength(2));
      expect(question.answers.first.id, '');
      expect(question.answers.last.id, 'a');
    });
  });

  group('Answer.fromJson', () {
    test('distractorExplanation is null, not empty, when absent', () {
      final answer = Answer.fromJson({'id': 'a', 'text': '4'});
      expect(answer.distractorExplanation, isNull);
    });
  });

  group('QuestionReference.fromJson', () {
    test('url is null when absent', () {
      final reference = QuestionReference.fromJson({
        'title': 'Title',
        'source': 'Source',
        'section': '1.1',
      });
      expect(reference.url, isNull);
    });

    test(
        'an unparseable url still produces a usable Uri rather than '
        'throwing', () {
      final reference = QuestionReference.fromJson({
        'title': 'Title',
        'source': 'Source',
        'section': '1.1',
        'url': 'not a valid uri',
      });
      expect(reference.url, isNotNull);
    });
  });
}
