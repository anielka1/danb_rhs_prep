import '../domain/models/answer_attempt.dart';
import '../domain/models/mock_attempt.dart';
import '../features/content/domain/content_package.dart';
import '../practice_session/practice_generator.dart';

class QuestionCounts {
  const QuestionCounts(this.correct, this.needsReview, this.notAttempted,
      [this.gradeUnavailable = 0]);
  final int correct, needsReview, notAttempted, gradeUnavailable;
  int get total => correct + needsReview + notAttempted + gradeUnavailable;
}

class DailyActivity {
  const DailyActivity(this.date, this.correct, this.incorrect);
  final String date;
  final int correct, incorrect;
  int get answers => correct + incorrect;
}

/// Saved grades, never re-evaluated against a newer answer key.
class LearningProgress {
  LearningProgress._(this.total, this.domains, this.incorrectIds, this.days,
      this.hasMockDetailLimitation);
  final QuestionCounts total;
  final Map<String, QuestionCounts> domains;
  final Set<String> incorrectIds;
  final List<DailyActivity> days;
  final bool hasMockDetailLimitation;

  static String localDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int correctToday(DateTime now) => days
      .where((day) => day.date == localDate(now))
      .fold(0, (sum, day) => sum + day.correct);

  factory LearningProgress.fromHistory({
    required ContentPackage package,
    required List<AnswerAttempt> attempts,
    List<MockAttempt> mocks = const [],
  }) {
    final available = <String, String>{};
    if (package.questions.isNotEmpty) {
      try {
        for (final q in PracticeGenerator.select(
                package: package,
                questionStates: const [],
                requestedCount: package.questions.length)
            .questions) {
          available[q.id] = q.domainId;
        }
      } on PracticeGenerationUnavailable {
        // The same content eligibility gate as practice.
      }
    }
    final latest = <String, AnswerAttempt>{};
    final daily = <String, (int, int)>{};
    final ids = <String>{};
    final completed = {
      for (final m in mocks)
        if (m.examId == package.exam.id &&
            m.status == MockAttemptStatus.completed)
          m.id: m
    };
    final mockAnswers = <String, Set<String>>{};
    for (final a in attempts) {
      if (a.examId != package.exam.id || !ids.add(a.id)) continue;
      if (a.sessionType == AttemptSessionType.mock) {
        if (!completed.containsKey(a.sessionId) ||
            !completed[a.sessionId]!.answers.containsKey(a.questionId)) {
          continue;
        }
        if (!(mockAnswers[a.sessionId] ??= {}).add(a.questionId)) continue;
      }
      // Repository insertion order is authoritative, including clock changes.
      latest[a.questionId] = a;
      final day = a.localAnsweredDate ?? localDate(a.answeredAt.toLocal());
      final (correct, incorrect) = daily[day] ?? (0, 0);
      daily[day] =
          (correct + (a.isCorrect ? 1 : 0), incorrect + (a.isCorrect ? 0 : 1));
    }
    var limitation = false;
    final unknown = <String>{};
    for (final m in completed.values) {
      final recorded = mockAnswers[m.id] ?? const <String>{};
      if (recorded.length == m.answers.length) continue;
      limitation = true;
      for (final id in m.answers.keys.where((id) => !recorded.contains(id))) {
        final last = latest[id];
        if (last == null || !last.answeredAt.isAfter(m.completedAt!)) {
          unknown.add(id);
        }
      }
      // A complete frozen score supports daily totals, not question-level grades.
      // Partial imported AnswerAttempt data cannot be reconciled safely.
      if (recorded.isNotEmpty) continue;
      final day = localDate(m.completedAt!.toLocal());
      final (correct, incorrect) = daily[day] ?? (0, 0);
      daily[day] = (
        correct + m.correctCount!,
        incorrect + m.answers.length - m.correctCount!
      );
    }
    final wrong = <String>{};
    QuestionCounts counts(Iterable<String> questions) {
      var correct = 0, incorrect = 0, unanswered = 0, unavailable = 0;
      for (final id in questions) {
        final a = latest[id];
        if (unknown.contains(id)) {
          unavailable++;
        } else if (a == null) {
          unanswered++;
        } else if (a.isCorrect) {
          correct++;
        } else {
          incorrect++;
          wrong.add(id);
        }
      }
      return QuestionCounts(correct, incorrect, unanswered, unavailable);
    }

    final total = counts(available.keys);
    final domains = {
      for (final d in package.exam.domains)
        d.id: counts(available.keys.where((id) => available[id] == d.id))
    };
    final dates = daily.keys.toList()..sort((a, b) => b.compareTo(a));
    return LearningProgress._(
        total,
        Map.unmodifiable(domains),
        Set.unmodifiable(wrong),
        List.unmodifiable([
          for (final date in dates)
            DailyActivity(date, daily[date]!.$1, daily[date]!.$2)
        ]),
        limitation);
  }
}
