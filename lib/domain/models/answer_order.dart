import 'dart:math';
import '../../features/questions/domain/question.dart';

/// Stable answer identities, persisted once before a new session opens.
class AnswerOrder {
  static Map<String, List<String>> shuffled(
          List<Question> questions, Random random) =>
      {
        for (final q in questions)
          q.id: (q.answers.map((a) => a.id).toList()..shuffle(random)),
      };

  static Map<String, List<String>>? freeze(Map<String, List<String>>? value) =>
      value == null
          ? null
          : Map.unmodifiable({
              for (final e in value.entries)
                e.key: List<String>.unmodifiable(e.value),
            });

  static Map<String, List<String>>? decode(Object? value) => value == null
      ? null
      : {
          for (final e in (value as Map<String, dynamic>).entries)
            e.key: List<String>.from(e.value as List),
        };

  static bool equal(
      Map<String, List<String>>? a, Map<String, List<String>>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      final ids = b[e.key];
      if (ids == null || ids.length != e.value.length) return false;
      for (var i = 0; i < ids.length; i++) {
        if (ids[i] != e.value[i]) return false;
      }
    }
    return true;
  }

  static int hash(Map<String, List<String>>? value) => value == null
      ? 0
      : Object.hashAllUnordered(value.entries
          .map((e) => Object.hash(e.key, Object.hashAll(e.value))));

  /// Null is the legacy contract: leave the content order untouched. Invalid
  /// saved permutations fail closed rather than silently reshuffling answers.
  static List<Question> resolve(
      List<Question> questions, Map<String, List<String>>? order) {
    if (order == null) return List.unmodifiable(questions);
    if (order.length != questions.length) {
      throw const FormatException('Invalid saved answer order.');
    }
    return List.unmodifiable(questions.map((q) {
      final ids = order[q.id];
      final answers = {for (final a in q.answers) a.id: a};
      if (ids == null ||
          ids.length != answers.length ||
          ids.toSet().length != ids.length ||
          !ids.every(answers.containsKey)) {
        throw const FormatException(
            'Saved answer identities do not match content.');
      }
      return Question(
          id: q.id,
          examId: q.examId,
          domainId: q.domainId,
          topicId: q.topicId,
          questionText: q.questionText,
          answers: List.unmodifiable(ids.map((id) => answers[id]!)),
          correctAnswerId: q.correctAnswerId,
          explanation: q.explanation,
          references: q.references,
          difficulty: q.difficulty,
          status: q.status,
          version: q.version,
          updatedAt: q.updatedAt,
          sourceVersion: q.sourceVersion,
          tags: q.tags);
    }));
  }
}
