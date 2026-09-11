import '../domain/models/practice_session.dart';
import 'dart:math' as math;
import '../domain/models/answer_attempt.dart';
import '../domain/models/study_plan_preferences.dart';
import '../features/exams/domain/exam_config.dart';
import '../features/questions/domain/question.dart';

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

enum StudyDayType { study, buffer, review, rest, mock, exam }

enum StudyDayStatus { projected, inProgress, completed, missed }

enum PlanCondition {
  available,
  needsAvailability,
  emptyPool,
  noStudyDays,
  examReached,
  shortReview,
  allAnswered
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

class StudyPlanDay {
  StudyPlanDay(
      {required this.date,
      required this.type,
      this.status = StudyDayStatus.projected,
      Iterable<String> newIds = const [],
      Iterable<String> reviewIds = const [],
      required this.budgetSeconds,
      this.estimatedSeconds = 0,
      this.reviewBacklog = 0,
      this.recordedAnswers = 0,
      this.spentSeconds = 0})
      : newIds = List.unmodifiable(newIds),
        reviewIds = List.unmodifiable(reviewIds);
  final DateTime date;
  final StudyDayType type;
  final StudyDayStatus status;
  final List<String> newIds, reviewIds;
  final int budgetSeconds, estimatedSeconds, reviewBacklog;
  final int recordedAnswers, spentSeconds;
  List<String> get questionIds => [...reviewIds, ...newIds];
}

class StudyPlanProjection {
  const StudyPlanProjection(
      {required this.days,
      required this.condition,
      required this.availableQuestions,
      required this.uniqueAnswered,
      required this.requiredPace,
      required this.studyDays,
      required this.finalDays,
      required this.bufferDays,
      required this.remainingQuestions,
      required this.projectedNewQuestions,
      required this.reviews,
      required this.missingDomains,
      required this.timezone,
      required this.newSeconds,
      required this.reviewSeconds});
  final List<StudyPlanDay> days;
  final PlanCondition condition;
  final int availableQuestions,
      uniqueAnswered,
      requiredPace,
      studyDays,
      finalDays,
      bufferDays,
      remainingQuestions,
      projectedNewQuestions;
  final List<ReviewItem> reviews;
  final List<String> missingDomains;
  final String timezone;
  final int newSeconds, reviewSeconds;
  bool get limitedCoverage => projectedNewQuestions < remainingQuestions;
}

class StudyPlanPolicy {
  const StudyPlanPolicy(
      {this.initialNewSeconds = 90,
      this.initialReviewSeconds = 45,
      this.explanationSeconds = 30,
      this.reviewShare = .30,
      this.retainedQuestions = 3,
      this.retainedDays = 3});

  /// Reading is an explicit allowance, never relabelled answer-time history.
  final int explanationSeconds;
  final int initialNewSeconds,
      initialReviewSeconds,
      retainedQuestions,
      retainedDays;
  final double reviewShare;

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

  StudyPlanProjection project(
      {required DateTime now,
      required DateTime localToday,
      required String timezone,
      required ExamConfig exam,
      required StudyPlanPreferences? preferences,
      required List<Question> pool,
      required List<AnswerAttempt> attempts,
      DateTime? examDate,
      Set<String> reservedIds = const {},
      Set<String> additionalSeenIds = const {},
      int? dailyQuestionLimit,
      int? remainingUtcQuota,
      Map<String, StudyDayType> overrides = const {},
      List<ReviewItem>? reviewQueueOverride,
      List<PracticeSession> sessions = const [],
      Map<String, int> mockBudgets = const {}}) {
    final today = calendarDate(localToday);
    final deadline = examDate == null ? null : calendarDate(examDate);
    final history = <String, AnswerAttempt>{
      for (final a in attempts)
        if (a.examId == exam.id) a.id: a
    }.values.toList();
    final approved = <String, Question>{
      for (final q in pool)
        if (q.examId == exam.id && q.isApproved) q.id: q
    };
    final ordinary =
        approved.values.where((q) => !reservedIds.contains(q.id)).toList();
    final seen = {...history.map((a) => a.questionId), ...additionalSeenIds};
    final remaining = ordinary.where((q) => !seen.contains(q.id)).toList();
    final missing = exam.domains
        .where((d) => !ordinary.any((q) => q.domainId == d.id))
        .map((d) => d.id)
        .toList();
    final reviews = preferences == null
        ? <ReviewItem>[]
        : reviewQueueOverride ??
            reviewQueue(
                attempts: history,
                preferences: preferences,
                examDate: deadline);
    final firstIds = <String>{};
    final newMeasurements = <int>[], reviewMeasurements = <int>[];
    final priorNewMeasurements = <int>[];
    for (final a in history) {
      final first = firstIds.add(a.questionId);
      final duration = a.activeDurationSeconds;
      if (duration != null && duration >= 5 && duration <= 300) {
        (first ? newMeasurements : reviewMeasurements).add(duration);
        if (first &&
            (a.localAnsweredDate ?? dateKey(a.answeredAt.toUtc()))
                    .compareTo(dateKey(today)) <
                0) {
          priorNewMeasurements.add(duration);
        }
      }
    }
    int estimate(List<int> values, int fallback) {
      if (values.length < 5) return fallback;
      values.sort();
      return math.max(fallback * 2 ~/ 3, values[values.length ~/ 2]);
    }

    final newSeconds =
        estimate(newMeasurements, initialNewSeconds) + explanationSeconds;
    final reviewSeconds =
        estimate(reviewMeasurements, initialReviewSeconds) + explanationSeconds;
    final dates = <DateTime>[];
    final horizon = deadline ?? today.add(const Duration(days: 7));
    if (preferences != null) {
      for (var day = today;
          day.isBefore(horizon);
          day = day.add(const Duration(days: 1))) {
        if ((preferences.weekdays.contains(day.weekday) ||
                overrides.containsKey(dateKey(day))) &&
            overrides[dateKey(day)] != StudyDayType.rest) {
          dates.add(day);
        }
      }
    }
    final d = dates.length,
        f = math.min(5, (dates.length * .2).floor()),
        b = (dates.length * .1).floor();
    final s = d - f - b;
    final pace = s > 0 ? (remaining.length / s).ceil() : 0;
    var condition = preferences == null
        ? PlanCondition.needsAvailability
        : approved.isEmpty
            ? PlanCondition.emptyPool
            : deadline != null && !deadline.isAfter(today)
                ? PlanCondition.examReached
                : d == 0
                    ? PlanCondition.noStudyDays
                    : deadline == today.add(const Duration(days: 1))
                        ? PlanCondition.shortReview
                        : remaining.isEmpty
                            ? PlanCondition.allAnswered
                            : PlanCondition.available;
    final allocated = <String>{};
    final domainCounts = <String, int>{};
    final unique = <String>{};
    for (final a in history) {
      if (unique.add(a.questionId)) {
        domainCounts.update(a.domainId, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final topicAttempts = <String, List<AnswerAttempt>>{};
    for (final a in history) {
      (topicAttempts[a.topicId] ??= []).add(a);
    }
    final weights = {
      for (final domain in exam.domains) domain.id: domain.weight
    };
    final weightSum = weights.values.fold<double>(0, (a, b) => a + b);
    final days = <StudyPlanDay>[];
    var projected = 0;
    // Forecast successes size future workload only; never persisted as evidence.
    final forecast = {for (final r in reviews) r.questionId: r};
    for (var i = 0; i < dates.length; i++) {
      final day = dates[i];
      final isToday = day == today;
      var type = overrides[dateKey(day)] ??
          (i >= d - f
              ? StudyDayType.review
              : b > 0 &&
                      ((i + 1) * b ~/ math.max(1, d - f)) >
                          (i * b ~/ math.max(1, d - f))
                  ? StudyDayType.buffer
                  : StudyDayType.study);
      if (condition == PlanCondition.shortReview) type = StudyDayType.review;
      var spent = 0, answered = 0, newAnswered = 0;
      final seenBefore = <String>{};
      for (final a in history) {
        final first = seenBefore.add(a.questionId);
        if (a.localAnsweredDate == dateKey(day)) {
          spent += a.activeDurationSeconds ??
              (first
                  ? newSeconds - explanationSeconds
                  : reviewSeconds - explanationSeconds);
          answered++;
          if (first) newAnswered++;
        }
      }
      final commitments = sessions
          .where((session) =>
              session.examId == exam.id &&
              session.planDate == dateKey(day) &&
              session.mode == PracticeMode.planned)
          .toList();
      final committedNew = commitments
          .expand((s) =>
              s.questionIds.where((id) => !s.reviewQuestionIds.contains(id)))
          .toSet();
      final remainingCommitment = committedNew
          .where((id) =>
              !seen.contains(id) &&
              approved.containsKey(id) &&
              !reservedIds.contains(id))
          .toList();
      final budget = math.max(
          0,
          (type == StudyDayType.mock
                      ? (mockBudgets[dateKey(day)] ?? 0)
                      : preferences!.minutes) *
                  60 -
              spent -
              answered * explanationSeconds);
      var time = budget;
      var slots = dailyQuestionLimit ?? 1000000;
      if (isToday && remainingUtcQuota != null) {
        slots = math.min(slots, remainingUtcQuota);
      }
      final due = forecast.values
          .where((r) =>
              approved.containsKey(r.questionId) &&
              !reservedIds.contains(r.questionId) &&
              (!r.dueDate.isAfter(day) ||
                  type == StudyDayType.review && r.afterExam))
          .toList()
        ..sort((a, b) {
          final errorA = a.afterError && a.dueDate.isBefore(day),
              errorB = b.afterError && b.dueDate.isBefore(day);
          if (errorA != errorB) return errorA ? -1 : 1;
          final cmp = a.dueDate.compareTo(b.dueDate);
          return cmp != 0 ? cmp : a.questionId.compareTo(b.questionId);
        });
      final reviewIds = <String>[], newIds = <String>[];
      // Future reviews are projections, never counted as recorded successes.
      // Once work has begun, use optional buffers before overloading normal days.
      final useBuffer = type == StudyDayType.buffer &&
          history.isNotEmpty &&
          remaining.length - allocated.length >
              math.max(0, s - i) * (budget * (1 - reviewShare) ~/ newSeconds);
      if ((type != StudyDayType.buffer || useBuffer) &&
          type != StudyDayType.rest &&
          type != StudyDayType.mock) {
        for (final r in due) {
          if (time < reviewSeconds || slots <= 0) break;
          reviewIds.add(r.questionId);
          time -= reviewSeconds;
          slots--;
          final stage = math.min(4, r.stage + 1);
          final dueDate = nextStudyDate(
              day.add(Duration(days: const [1, 3, 7, 14][stage - 1])),
              preferences!.weekdays);
          forecast[r.questionId] = ReviewItem(
              questionId: r.questionId,
              dueDate: dueDate,
              stage: stage,
              afterError: false,
              afterExam: deadline != null && !dueDate.isBefore(deadline));
        }
        if (type == StudyDayType.study || useBuffer) {
          // Reserve review time even before enough history exists to project it.
          final newTime = math.max(0, budget - (budget * reviewShare).ceil());
          // Future pace uses the remaining pool. Today's unstarted baseline
          // reconstructs the pool before today's first answers; once started,
          // persisted session IDs are the commitment, including after restart.
          final baselineCapacity =
              (preferences!.minutes * 60 * (1 - reviewShare)) ~/
                  (estimate(priorNewMeasurements, initialNewSeconds) +
                      explanationSeconds);
          final dayTarget = isToday && commitments.isNotEmpty
              ? remainingCommitment.length
              : math.max(
                  0,
                  (isToday && s > 0
                          ? math.min(
                              ((remaining.length + newAnswered) / s).ceil(),
                              baselineCapacity)
                          : pace) -
                      newAnswered);
          var count = math.min(dayTarget,
              math.min(slots, math.min(time, newTime) ~/ newSeconds));
          while (count-- > 0) {
            final candidates = remaining
                .where((q) =>
                    !allocated.contains(q.id) &&
                    (!isToday ||
                        commitments.isEmpty ||
                        remainingCommitment.contains(q.id)))
                .toList();
            if (candidates.isEmpty) break;
            final total = domainCounts.values.fold<int>(0, (a, b) => a + b) + 1;
            double deficit(Question q) => weightSum == 0
                ? 0
                : (weights[q.domainId] ?? 0) / weightSum * total -
                    (domainCounts[q.domainId] ?? 0);
            int topicPriority(Question q) {
              final h = topicAttempts[q.topicId];
              if (h == null) return 0;
              return h.where((a) => a.isCorrect).length / h.length < .7 ? 1 : 2;
            }

            int difficulty(Question q) {
              final h = topicAttempts[q.topicId];
              final target = h == null
                  ? (preferences.stage == StudyStage.mostlyReviewing ? 3 : 2)
                  : h.where((a) => a.isCorrect).length / h.length >= .8
                      ? 4
                      : 2;
              return (q.difficulty - target).abs();
            }

            candidates.sort((a, b) {
              if (isToday && commitments.isNotEmpty) {
                return remainingCommitment
                    .indexOf(a.id)
                    .compareTo(remainingCommitment.indexOf(b.id));
              }
              var c = deficit(b).compareTo(deficit(a));
              if (c != 0) return c;
              c = topicPriority(a).compareTo(topicPriority(b));
              if (c != 0) return c;
              c = difficulty(a).compareTo(difficulty(b));
              return c != 0 ? c : a.id.compareTo(b.id);
            });
            final q = candidates.first;
            allocated.add(q.id);
            newIds.add(q.id);
            time -= newSeconds;
            final dueDate = nextStudyDate(
                day.add(const Duration(days: 1)), preferences.weekdays);
            forecast[q.id] = ReviewItem(
                questionId: q.id,
                dueDate: dueDate,
                stage: 1,
                afterError: false,
                afterExam: deadline != null && !dueDate.isBefore(deadline));
            domainCounts.update(q.domainId, (n) => n + 1, ifAbsent: () => 1);
          }
        }
      }
      projected += newIds.length;
      days.add(StudyPlanDay(
          date: day,
          type: type,
          budgetSeconds: budget,
          estimatedSeconds: type == StudyDayType.mock ? budget : budget - time,
          newIds: newIds,
          reviewIds: reviewIds,
          reviewBacklog: due.length - reviewIds.length,
          recordedAnswers: answered,
          spentSeconds: spent,
          status: commitments.any((s) => s.status == SessionStatus.inProgress)
              ? StudyDayStatus.inProgress
              : answered == 0
                  ? StudyDayStatus.projected
                  : time == 0 || newIds.isEmpty && reviewIds.isEmpty
                      ? StudyDayStatus.completed
                      : StudyDayStatus.inProgress));
    }
    // Calendar includes days off and immutable session history, separate from D.
    for (var day = today;
        day.isBefore(horizon);
        day = day.add(const Duration(days: 1))) {
      if (!days.any((d) => d.date == day)) {
        final recorded =
            history.where((a) => a.localAnsweredDate == dateKey(day)).toList();
        days.add(StudyPlanDay(
            date: day,
            type: StudyDayType.rest,
            budgetSeconds: 0,
            recordedAnswers: recorded.length,
            spentSeconds: recorded.fold<int>(
                0, (sum, a) => sum + (a.activeDurationSeconds ?? 0)),
            status: recorded.isEmpty
                ? StudyDayStatus.projected
                : StudyDayStatus.completed));
      }
    }
    if (deadline != null && !deadline.isBefore(today)) {
      days.add(StudyPlanDay(
          date: deadline, type: StudyDayType.exam, budgetSeconds: 0));
    }
    final historicDates = {
      ...sessions
          .where((s) => s.examId == exam.id)
          .map((s) => s.planDate)
          .whereType<String>(),
      ...history
          .map((a) => a.localAnsweredDate ?? dateKey(a.answeredAt.toUtc()))
    };
    for (final key in historicDates) {
      final date = calendarDate(DateTime.parse(key));
      final entries = sessions
          .where((s) => s.examId == exam.id && s.planDate == key)
          .toList();
      if (!date.isBefore(today)) continue;
      final recorded = history
          .where((a) =>
              (a.localAnsweredDate ?? dateKey(a.answeredAt.toUtc())) == key)
          .toList();
      final pendingNew = <String>{}, pendingReviews = <String>{};
      for (final session in entries) {
        if (session.status == SessionStatus.completed) continue;
        final doneIds = history
            .where((a) => a.sessionId == session.id)
            .map((a) => a.questionId)
            .toSet();
        for (final id
            in session.questionIds.where((id) => !doneIds.contains(id))) {
          (session.reviewQuestionIds.contains(id) ? pendingReviews : pendingNew)
              .add(id);
        }
      }
      days.add(StudyPlanDay(
          date: date,
          type: overrides[key] ?? StudyDayType.study,
          newIds: pendingNew,
          reviewIds: pendingReviews,
          status: entries.any((s) => s.status == SessionStatus.inProgress)
              ? StudyDayStatus.inProgress
              : (entries.isEmpty && recorded.isNotEmpty) ||
                      (entries.isNotEmpty &&
                          entries.every(
                              (s) => s.status == SessionStatus.completed))
                  ? StudyDayStatus.completed
                  : StudyDayStatus.missed,
          budgetSeconds: 0,
          recordedAnswers: recorded.length,
          spentSeconds: recorded.fold<int>(
              0, (sum, a) => sum + (a.activeDurationSeconds ?? 0)),
          estimatedSeconds: pendingNew.length * newSeconds +
              pendingReviews.length * reviewSeconds));
    }
    days.sort((a, b) => a.date.compareTo(b.date));
    return StudyPlanProjection(
        days: List.unmodifiable(days),
        condition: condition,
        availableQuestions: approved.length,
        uniqueAnswered: seen.intersection(approved.keys.toSet()).length,
        requiredPace: pace,
        studyDays: s,
        finalDays: f,
        bufferDays: b,
        remainingQuestions: remaining.length,
        projectedNewQuestions: projected,
        reviews: reviews,
        missingDomains: missing,
        timezone: timezone,
        newSeconds: newSeconds,
        reviewSeconds: reviewSeconds);
  }
}
