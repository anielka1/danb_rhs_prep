import 'dart:math' as math;
import '../domain/models/answer_attempt.dart';
import '../domain/models/study_plan_preferences.dart';

/// UTC-flagged calendar components, NOT an instant or a timezone conversion.
DateTime calendarDate(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);
String dateKey(DateTime value) =>
    calendarDate(value).toIso8601String().substring(0, 10);
DateTime nextStudyDate(DateTime date, Set<int> weekdays) {
  if (weekdays.isEmpty) throw ArgumentError('No study weekdays');
  var day = calendarDate(date);
  while (!weekdays.contains(day.weekday)) {
    day = day.add(const Duration(days: 1));
  }
  return day;
}

enum TopicLearningStatus { insufficientData, learning, needsReview, retained }

class ReviewItem {
  const ReviewItem(
      {required this.questionId,
      required this.dueDate,
      required this.stage,
      required this.afterError,
      required this.afterExam});
  final String questionId;
  final DateTime dueDate;
  final int stage;
  final bool afterError;
  final bool afterExam;
  int get policyVersion => 2;
}

/// Legacy review evidence remains interpretable; no daily allocation is computed.
class StudyPlanPolicy {
  const StudyPlanPolicy();

  /// Derived from append-only history: recording the same attempt id twice cannot
  /// advance a review or count work twice. Null confidence never advances mastery.
  List<ReviewItem> reviewQueue(
      {required List<AnswerAttempt> attempts,
      required StudyPlanPreferences preferences,
      DateTime? examDate}) {
    final byQuestion = <String, List<AnswerAttempt>>{};
    final ids = <String>{};
    for (final a in attempts) {
      if (ids.add(a.id)) (byQuestion[a.questionId] ??= []).add(a);
    }
    final result = <ReviewItem>[];
    for (final entry in byQuestion.entries) {
      var stage = 0;
      String? lastSuccessDate;
      String? lastAttemptDate;
      DateTime? due;
      var error = false;
      for (final a in entry.value) {
        // Old rows have no local-day evidence. UTC date is a documented fallback,
        // never used as evidence of confident retention.
        final day = a.localAnsweredDate == null
            ? calendarDate(a.answeredAt.toUtc())
            : calendarDate(DateTime.parse(a.localAnsweredDate!));
        final advance = a.isCorrect &&
            a.confident == true &&
            a.localAnsweredDate != null &&
            lastSuccessDate != dateKey(day) &&
            lastAttemptDate != dateKey(day);
        error = !a.isCorrect || a.confident == false;
        if (error) {
          stage = 0;
          lastSuccessDate = null;
        } else if (advance) {
          stage = math.min(4, stage + 1);
          lastSuccessDate = dateKey(day);
        }
        // Only a new confident success earns the stage's longer interval.
        // Neutral answers keep the stage but schedule a short next-study-day
        // check. Early answers can shorten, never delay, an existing due date.
        final interval = advance ? const [1, 3, 7, 14][stage - 1] : 1;
        final candidate = nextStudyDate(
            day.add(Duration(days: interval)), preferences.weekdays);
        if (due == null || error || advance) {
          due = candidate;
        } else if (lastAttemptDate != dateKey(day)) {
          due = due.isAfter(day) && due.isBefore(candidate) ? due : candidate;
        }
        lastAttemptDate = dateKey(day);
      }
      result.add(ReviewItem(
          questionId: entry.key,
          dueDate: due!,
          stage: stage,
          afterError: error,
          afterExam:
              examDate != null && !due.isBefore(calendarDate(examDate))));
    }
    result.sort((a, b) {
      final c = a.dueDate.compareTo(b.dueDate);
      return c != 0 ? c : a.questionId.compareTo(b.questionId);
    });
    return result;
  }
}
