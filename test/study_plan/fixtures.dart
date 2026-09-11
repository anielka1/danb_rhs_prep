import 'dart:convert';
import 'dart:io';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';

/// Synthetic questions only in test/, with the actual configured domain weights.
ContentPackage fixture(
    {int count = 500, QuestionStatus status = QuestionStatus.approved}) {
  final raw = jsonDecode(
          File('assets/content/danb_rhs/content.json').readAsStringSync())
      as Map<String, dynamic>;
  return fixtureFromJson(raw, count: count, status: status);
}

ContentPackage fixtureFromJson(Map<String, dynamic> raw,
    {int count = 80, QuestionStatus status = QuestionStatus.approved}) {
  final exam = ExamConfig.fromJson(raw['exam'] as Map<String, dynamic>);
  final questions = <Question>[];
  for (var i = 0; i < count; i++) {
    final domain = exam.domains[i % 4 < 2 ? 0 : i % 4 - 1];
    questions.add(Question(
        id: 'fixture-$i',
        examId: exam.id,
        domainId: domain.id,
        topicId: domain.topics[(i ~/ 4) % domain.topics.length].id,
        questionText: 'Synthetic test question number $i?',
        answers: const [
          Answer(id: 'a', text: 'Correct fixture answer'),
          Answer(id: 'b', text: 'Alternative one'),
          Answer(id: 'c', text: 'Alternative two'),
          Answer(id: 'd', text: 'Alternative three')
        ],
        correctAnswerId: 'a',
        explanation:
            'Synthetic explanation used exclusively to verify the application behavior in tests.',
        references: const [
          QuestionReference(
              title: 'Fixture reference',
              source: 'Test source',
              section: 'Test section')
        ],
        difficulty: i % 5 + 1,
        status: status,
        version: 1,
        updatedAt: DateTime.utc(2026, 1, 1),
        sourceVersion: exam.contentVersion,
        tags: const ['test-fixture']));
  }
  return ContentPackage(
      exam: exam,
      contentVersion: exam.contentVersion,
      sourceVersion: raw['sourceVersion'] as String,
      generatedAt: DateTime.utc(2026, 1, 1),
      questions: questions);
}

AnswerAttempt answer(Question q, DateTime day,
        {String? id,
        bool correct = true,
        bool? confident,
        int? seconds,
        String? localDay}) =>
    AnswerAttempt(
        id: id ?? '${q.id}-${day.toIso8601String()}',
        examId: q.examId,
        questionId: q.id,
        domainId: q.domainId,
        topicId: q.topicId,
        difficulty: q.difficulty,
        sessionId: 'session-${day.day}',
        sessionType: AttemptSessionType.practice,
        selectedAnswerId: correct ? 'a' : 'b',
        isCorrect: correct,
        answeredAt: day,
        confident: confident,
        activeDurationSeconds: seconds,
        localAnsweredDate: localDay ?? day.toIso8601String().substring(0, 10),
        questionVersion: 1,
        correctAnswerId: 'a',
        explanation: q.explanation,
        contentVersion: 'fixture');
