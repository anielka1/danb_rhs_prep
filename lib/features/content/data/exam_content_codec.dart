import 'dart:convert';

import '../../exams/domain/exam_config.dart';
import '../../questions/domain/question.dart';
import '../domain/content_package.dart';

class ExamContentCodec {
  const ExamContentCodec();

  ContentPackage decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Content package must be a JSON object.');
    }

    final examJson = decoded['exam'];
    final questionsJson = decoded['questions'];
    if (examJson is! Map<String, Object?> || questionsJson is! List<Object?>) {
      throw const FormatException(
        'Content package requires an exam object and questions array.',
      );
    }

    return ContentPackage(
      exam: ExamConfig.fromJson(examJson),
      contentVersion: _string(decoded['contentVersion']),
      sourceVersion: _string(decoded['sourceVersion']),
      generatedAt: DateTime.tryParse(_string(decoded['generatedAt'])),
      questions: questionsJson
          .map((item) => Question.fromJson(
                item is Map<String, Object?> ? item : const <String, Object?>{},
              ))
          .toList(growable: false),
    );
  }
}

String _string(Object? value) => value is String ? value.trim() : '';
