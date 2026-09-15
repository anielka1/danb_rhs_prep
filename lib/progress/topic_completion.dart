import '../mock_exam/mock_exam_blueprint.dart';
import '../domain/models/question_state.dart';
import '../features/content/domain/content_package.dart';

/// Counts distinct answered questions in the current approved bank, not scores
/// or completed sessions. Retired questions and repeated attempts do not inflate it.
class TopicCompletion {
  TopicCompletion(ContentPackage package, List<QuestionState> states) {
    final answered = states
        .where((s) => s.examId == package.exam.id && s.hasBeenAnswered)
        .map((s) => s.questionId)
        .toSet();
    final demo = package.exam.id.startsWith('demo_');
    if (demo) MockExamBlueprint.ensureDemoAllowed();
    for (final q in demo ? package.questions : package.approvedQuestions) {
      totals.update(q.topicId, (n) => n + 1, ifAbsent: () => 1);
      if (answered.contains(q.id)) {
        completed.update(q.topicId, (n) => n + 1, ifAbsent: () => 1);
      }
    }
  }

  final totals = <String, int>{};
  final completed = <String, int>{};
  bool isComplete(String id) =>
      (totals[id] ?? 0) > 0 && completed[id] == totals[id];
  String status(String id) => isComplete(id)
      ? 'Completed'
      : (completed[id] ?? 0) > 0
          ? 'In progress'
          : 'Not started';
}
