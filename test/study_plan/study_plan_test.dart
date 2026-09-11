import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/study_plan_preferences.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';
import 'package:danb_rhs_prep/study_plan/study_plan.dart';
import 'package:danb_rhs_prep/study_plan/study_metrics.dart';
import 'fixtures.dart';

void main() {
  final package = fixture(),
      today = DateTime.utc(2026, 9, 10),
      policy = const StudyPlanPolicy();
  final preferences =
      StudyPlanPreferences(weekdays: [1, 2, 3, 4, 5, 6, 7], minutes: 45);
  StudyPlanProjection plan(
          {List<AnswerAttempt> history = const [],
          Set<String> reserved = const {},
          List<Question>? pool,
          DateTime? end,
          int? quota,
          StudyPlanPreferences? prefs}) =>
      policy.project(
          now: today,
          localToday: today,
          timezone: 'America/New_York',
          exam: package.exam,
          preferences: prefs ?? preferences,
          pool: pool ?? package.questions,
          attempts: history,
          examDate: end ?? today.add(const Duration(days: 30)),
          reservedIds: reserved,
          remainingUtcQuota: quota);
  test('500 actual questions, 30 sessions, F5 B3 S22 pace23; reserve75 pace20',
      () {
    final p = plan();
    expect([p.finalDays, p.bufferDays, p.studyDays, p.requiredPace],
        [5, 3, 22, 23]);
    expect(
        plan(reserved: package.questions.take(75).map((q) => q.id).toSet())
            .requiredPace,
        20);
  });
  test('time dominates required pace; no duplicate new assignment', () {
    final p = plan();
    expect(p.days.firstWhere((d) => d.date == today).newIds.length, 15);
    expect(p.limitedCoverage, isTrue);
    final ids = p.days.expand((d) => d.newIds).toList();
    expect(ids.toSet().length, ids.length);
    expect(p.days.every((d) => d.estimatedSeconds <= d.budgetSeconds), isTrue);
  });
  test('empty, retired and draft pools cannot produce questions', () {
    for (final status in [QuestionStatus.draft, QuestionStatus.retired]) {
      final p = plan(pool: fixture(status: status).questions);
      expect(p.condition, PlanCondition.emptyPool);
      expect(p.days.expand((d) => d.questionIds), isEmpty);
    }
  });
  test('small pool is exact, missing domains explicit', () {
    final p = plan(pool: package.questions.take(1).toList());
    expect(p.remainingQuestions, 1);
    expect(p.days.expand((d) => d.newIds).length, 1);
    expect(p.missingDomains.length, 2);
  });
  test('all answered is distinct; answers to retired content are retained', () {
    final history = package.questions
        .map((q) => answer(q, today.subtract(const Duration(days: 1))))
        .toList();
    expect(plan(history: history).condition, PlanCondition.allAnswered);
    expect(plan(history: history, pool: []).uniqueAnswered, 0);
    expect(history.length, 500);
  });
  test('today/past no automatic pre-exam work; tomorrow review only', () {
    for (final offset in [-1, 0]) {
      final p = plan(end: today.add(Duration(days: offset)));
      expect(p.condition, PlanCondition.examReached);
      expect(p.days.expand((d) => d.questionIds), isEmpty);
    }
    final p = plan(end: today.add(const Duration(days: 1)));
    expect(p.condition, PlanCondition.shortReview);
    expect(p.days.expand((d) => d.newIds), isEmpty);
  });
  test('rolling seven calendar days, no machine timezone dependence at DST',
      () {
    final day = DateTime.utc(2026, 3, 7);
    final p = policy.project(
        now: DateTime.utc(2026, 3, 8, 2),
        localToday: day,
        timezone: 'America/New_York',
        exam: package.exam,
        preferences: preferences,
        pool: package.questions,
        attempts: []);
    expect(p.days.length, 7);
    expect(p.days.map((d) => dateKey(d.date)).toSet().length, 7);
    expect(p.days.first.date, day);
  });
  test('free UTC quota and partial local budget are independent', () {
    expect(plan(quota: 0).days.first.questionIds, isEmpty);
    final a = answer(package.questions.first, today, seconds: 2600);
    final p = plan(history: [a]);
    expect(p.days.firstWhere((d) => d.date == today).budgetSeconds, 70);
    expect(p.days.firstWhere((d) => d.date == today).newIds.length, 0);
  });
  test('overdue errors first and bounded backlog visible', () {
    final history = package.questions
        .take(100)
        .map((q) =>
            answer(q, today.subtract(const Duration(days: 3)), correct: false))
        .toList();
    final p = plan(history: history);
    expect(p.days.firstWhere((d) => d.date == today).newIds, isEmpty);
    expect(p.days.firstWhere((d) => d.date == today).reviewIds.length, 36);
    expect(p.days.firstWhere((d) => d.date == today).reviewBacklog, 64);
  });
  test('success intervals 1/3/7/14; same-day and retry no extra stage', () {
    final q = package.questions.first;
    final h = <AnswerAttempt>[];
    for (var i = 0; i < 4; i++) {
      final day = today.add(Duration(days: i * 10));
      h.add(answer(q, day, confident: true));
      final r =
          policy.reviewQueue(attempts: h, preferences: preferences).single;
      expect(r.stage, i + 1);
      expect(r.dueDate.difference(day).inDays, [1, 3, 7, 14][i]);
    }
    h.add(h.last);
    h.add(answer(q, today.add(const Duration(days: 30)),
        id: 'same-day', confident: true));
    expect(
        policy.reviewQueue(attempts: h, preferences: preferences).single.stage,
        4);
    h.add(answer(q, today.add(const Duration(days: 31)), confident: false));
    expect(
        policy.reviewQueue(attempts: h, preferences: preferences).single.stage,
        0);
  });
  test('neutral confidence does not assert mastery and weekends shift', () {
    final prefs = StudyPlanPreferences(weekdays: [1], minutes: 15);
    final r = policy.reviewQueue(
        attempts: [answer(package.questions.first, today)],
        preferences: prefs).single;
    expect(r.stage, 0);
    expect(r.dueDate.weekday, DateTime.monday);
  });
  test(
      'first accuracy separate from review accuracy and tiny samples not retained',
      () {
    final q = package.questions.first;
    final history = [
      answer(q, today, correct: false),
      answer(q, today.add(const Duration(days: 1)), correct: true)
    ];
    final metrics = StudyMetrics(
        pool: package.questions,
        history: history,
        reviews:
            policy.reviewQueue(attempts: history, preferences: preferences),
        today: today);
    expect(metrics.firstAccuracy, 0);
    expect(metrics.reviewAccuracy, 1);
    expect(metrics.topics.first.status, isNot(TopicLearningStatus.retained));
  });
  test('availability codec rejects corrupt values and never invents minutes',
      () {
    expect(StudyPlanPreferences.decode(null), isNull);
    expect(
        StudyPlanPreferences.decode('{"version":1,"weekdays":[],"minutes":10}'),
        isNull);
    expect(StudyPlanPreferences.decode(preferences.encode()), preferences);
  });
  test('weighted deficits stay fair over twenty one-question sessions', () {
    final history = <AnswerAttempt>[];
    final counts = <String, int>{};
    for (var i = 0; i < 20; i++) {
      final date = today.add(Duration(days: i));
      final p = policy.project(
          now: date,
          localToday: date,
          timezone: 'Test',
          exam: package.exam,
          preferences: preferences,
          pool: package.questions,
          attempts: history,
          examDate: date.add(const Duration(days: 30)),
          dailyQuestionLimit: 1,
          reviewQueueOverride: []);
      final id = p.days.firstWhere((d) => d.date == date).newIds.single;
      final q = package.questions.firstWhere((q) => q.id == id);
      expect(history.any((a) => a.questionId == id), isFalse);
      counts.update(q.domainId, (n) => n + 1, ifAbsent: () => 1);
      history.add(answer(q, date));
    }
    expect(counts[package.exam.domains[0].id], 10);
    expect(counts[package.exam.domains[1].id], 5);
    expect(counts[package.exam.domains[2].id], 5);
  });
  test('same-day error then success cannot advance a review stage', () {
    final q = package.questions.first;
    final h = [
      answer(q, today, id: 'wrong', correct: false),
      answer(q, today, id: 'right', confident: true)
    ];
    expect(
        policy.reviewQueue(attempts: h, preferences: preferences).single.stage,
        0);
  });
  test('completed daily new allocation is not granted again to a fast learner',
      () {
    final initial = plan();
    final ids = initial.days.first.newIds;
    final h = ids
        .map((id) => answer(
            package.questions.firstWhere((q) => q.id == id), today,
            seconds: 5))
        .toList();
    final next = plan(history: h);
    expect(next.days.first.newIds.length, lessThan(3));
  });
}
