import '../../exams/domain/exam_config.dart';
import '../../questions/domain/question.dart';

class ContentPackage {
  const ContentPackage({
    required this.exam,
    required this.contentVersion,
    required this.sourceVersion,
    required this.generatedAt,
    required this.questions,
  });

  final ExamConfig exam;
  final String contentVersion;
  final String sourceVersion;
  final DateTime? generatedAt;
  final List<Question> questions;

  List<Question> get approvedQuestions =>
      questions.where((question) => question.isApproved).toList(growable: false);
}
