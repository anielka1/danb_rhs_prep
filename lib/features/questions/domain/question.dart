enum QuestionStatus { draft, reviewed, approved, retired, unknown }

class Answer {
  const Answer({
    required this.id,
    required this.text,
    this.distractorExplanation,
  });

  final String id;
  final String text;
  final String? distractorExplanation;

  factory Answer.fromJson(Map<String, Object?> json) {
    return Answer(
      id: _string(json['id']),
      text: _string(json['text']),
      distractorExplanation: _nullableString(json['distractorExplanation']),
    );
  }
}

class QuestionReference {
  const QuestionReference({
    required this.title,
    required this.source,
    required this.section,
    this.url,
  });

  final String title;
  final String source;
  final String section;
  final Uri? url;

  factory QuestionReference.fromJson(Map<String, Object?> json) {
    final rawUrl = _nullableString(json['url']);
    final parsedUrl = rawUrl == null
        ? null
        : Uri.tryParse(rawUrl) ?? Uri(path: rawUrl);
    return QuestionReference(
      title: _string(json['title']),
      source: _string(json['source']),
      section: _string(json['section']),
      url: parsedUrl,
    );
  }
}

class Question {
  const Question({
    required this.id,
    required this.examId,
    required this.domainId,
    required this.topicId,
    required this.questionText,
    required this.answers,
    required this.correctAnswerId,
    required this.explanation,
    required this.references,
    required this.difficulty,
    required this.status,
    required this.version,
    required this.updatedAt,
    required this.sourceVersion,
    required this.tags,
  });

  final String id;
  final String examId;
  final String domainId;
  final String topicId;
  final String questionText;
  final List<Answer> answers;
  final String correctAnswerId;
  final String explanation;
  final List<QuestionReference> references;
  final int difficulty;
  final QuestionStatus status;
  final int version;
  final DateTime? updatedAt;
  final String sourceVersion;
  final List<String> tags;

  bool get isApproved => status == QuestionStatus.approved;

  Answer? get correctAnswer {
    for (final answer in answers) {
      if (answer.id == correctAnswerId) return answer;
    }
    return null;
  }

  factory Question.fromJson(Map<String, Object?> json) {
    final statusName = _string(json['status']);
    return Question(
      id: _string(json['id']),
      examId: _string(json['examId']),
      domainId: _string(json['domainId']),
      topicId: _string(json['topicId']),
      questionText: _string(json['questionText']),
      answers: _list(json['answers'])
          .map((item) => Answer.fromJson(_map(item)))
          .toList(growable: false),
      correctAnswerId: _string(json['correctAnswerId']),
      explanation: _string(json['explanation']),
      references: _list(json['references'])
          .map((item) => QuestionReference.fromJson(_map(item)))
          .toList(growable: false),
      difficulty: _int(json['difficulty']),
      status: QuestionStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => QuestionStatus.unknown,
      ),
      version: _int(json['version']),
      updatedAt: DateTime.tryParse(_string(json['updatedAt'])),
      sourceVersion: _string(json['sourceVersion']),
      tags: _list(json['tags'])
          .whereType<String>()
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false),
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
String? _nullableString(Object? value) {
  final parsed = _string(value);
  return parsed.isEmpty ? null : parsed;
}

int _int(Object? value) => value is num ? value.toInt() : 0;
