import '../domain/models/answer_attempt.dart';
import '../features/questions/domain/question.dart';
import 'study_plan.dart';

class TopicEvidence {
  const TopicEvidence(this.topicId, this.status, this.questions, this.days);
  final String topicId;
  final TopicLearningStatus status;
  final int questions, days;
}

class StudyMetrics {
  StudyMetrics(
      {required List<Question> pool,
      required List<AnswerAttempt> history,
      required List<ReviewItem> reviews,
      required DateTime today,
      int retainedQuestions = 3,
      int retainedDays = 3}) {
    final approved = {
      for (final q in pool)
        if (q.isApproved) q.id: q
    };
    final first = <String, AnswerAttempt>{};
    final repeats = <AnswerAttempt>[];
    final ids = <String>{};
    for (final a in history) {
      if (!approved.containsKey(a.questionId) || !ids.add(a.id)) continue;
      if (first.containsKey(a.questionId)) {
        repeats.add(a);
      } else {
        first[a.questionId] = a;
      }
    }
    uniqueAnswered = first.length;
    available = approved.length;
    firstAccuracy = first.isEmpty
        ? null
        : first.values.where((a) => a.isCorrect).length / first.length;
    reviewAccuracy = repeats.isEmpty
        ? null
        : repeats.where((a) => a.isCorrect).length / repeats.length;
    topics = [
      for (final topic in approved.values.map((q) => q.topicId).toSet())
        _topic(
            topic,
            history
                .where((a) =>
                    approved.containsKey(a.questionId) && a.topicId == topic)
                .toList(),
            reviews,
            today,
            retainedQuestions,
            retainedDays)
    ];
  }
  late final int uniqueAnswered, available;
  late final double? firstAccuracy, reviewAccuracy;
  late final List<TopicEvidence> topics;
  static TopicEvidence _topic(String id, List<AnswerAttempt> history,
      List<ReviewItem> reviews, DateTime today, int minQuestions, int minDays) {
    final questions = history.map((a) => a.questionId).toSet();
    final days =
        history.map((a) => a.localAnsweredDate).whereType<String>().toSet();
    final queue = reviews.where((r) => questions.contains(r.questionId));
    final due = queue
        .any((r) => r.afterError || !r.dueDate.isAfter(calendarDate(today)));
    final retained = questions.length >= minQuestions &&
        days.length >= minDays &&
        queue.where((r) => r.stage >= 3 && !r.afterExam).length >= minQuestions;
    return TopicEvidence(
        id,
        questions.length < minQuestions || days.length < 2
            ? TopicLearningStatus.insufficientData
            : due
                ? TopicLearningStatus.needsReview
                : retained
                    ? TopicLearningStatus.retained
                    : TopicLearningStatus.learning,
        questions.length,
        days.length);
  }
}
