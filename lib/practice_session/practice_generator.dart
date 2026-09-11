import 'dart:math';
import '../domain/models/answer_attempt.dart';
import '../domain/models/entitlement.dart';
import '../domain/models/question_state.dart';
import '../features/content/domain/content_package.dart';
import '../features/content/domain/content_validation.dart';
import '../features/questions/domain/question.dart';
import '../mock_exam/mock_exam_blueprint.dart' show MockExamBlueprint;

/// A safe, user-facing reason why a practice session can't be generated.
class PracticeGenerationUnavailable implements Exception {
  const PracticeGenerationUnavailable(this.message);
  final String message;
}

/// What determines a practice session's question pool, beyond the
/// always-applied approved-only/domain/topic filters (PREP-667).
enum PracticeFocus {
  /// No extra filtering — any eligible question in scope.
  any,

  /// Questions belonging to a topic whose recorded accuracy is below the
  /// active exam's `mockExam.practicePassingPercent` — see
  /// [PracticeGenerator.select]'s doc comment for exactly how "weak" is
  /// computed from [QuestionState] history.
  weakAreas,

  /// Questions the user has answered incorrectly at least once
  /// ([QuestionState.timesIncorrect] greater than zero) — "previously
  /// missed", regardless of whether it's since been answered correctly
  /// too.
  incorrectQuestions,

  /// Questions explicitly saved with a bookmark, answered or unseen.
  bookmarkedQuestions,
}

/// Selects a deterministic, duplicate-free, approved-only question set for
/// a practice session — Section 12's "Question Engine" (obtain approved
/// questions, filter by domain/topic/weak/incorrect, create sessions
/// without duplicates, enforce available question count), deliberately
/// **not** Section 16's much larger weighted adaptive-priority engine,
/// which is separate, later work.
///
/// Selection defaults to a stable question-ID sort. An injected Random shuffles
/// the eligible pool before capping it (the one-question Home launcher).
/// Answer ordering is a separate persisted session concern. Mock selection uses
/// exposure-ranked randomness only when starting a new mock, not in this engine.
class PracticeGenerator {
  PracticeGenerator._(this.questions, this.requestedCount, this.focus);

  /// Builds a practice question set.
  ///
  /// [requestedCount] is the number of questions asked for (e.g. 5, 10, or
  /// 20 from a future picker UI) — this engine itself does not restrict it
  /// to those specific values; that's a UI-level convention, not a rule
  /// this general-purpose selector should hard-code.
  ///
  /// [maxCount], when given, is an additional hard ceiling — the
  /// free-tier daily practice limit, already resolved by the caller (see
  /// [maxFreePracticeQuestionsToday]) into a plain number *before*
  /// calling this. This engine never itself queries a repository or an
  /// entitlement to compute that number, keeping it testable purely
  /// against fakes ("silniki mozna rozwijac na fakes"). `maxCount == 0`
  /// throws [PracticeGenerationUnavailable] with a distinct message from
  /// "no eligible questions", so a caller (and its UI) can tell "you've
  /// hit today's limit" apart from "there's nothing to practice at all".
  ///
  /// [domainId]/[topicId], when given, restrict the pool before [focus]
  /// is applied; both may be combined with any [focus].
  ///
  /// [focus] narrows the pool further:
  /// * [PracticeFocus.weakAreas] — a topic is "weak" when
  ///   [QuestionState] history shows at least one seen question in it and
  ///   the topic's aggregate accuracy (summed correct / summed seen,
  ///   across every question in the topic with recorded history) is below
  ///   [package]'s own `exam.mockExam.practicePassingPercent` (converted
  ///   from its 0-100 scale) — the same bar a mock exam attempt is judged
  ///   against, read live from content rather than a second, hard-coded
  ///   threshold that could drift out of sync with it. [questionStates]
  ///   entries for a question no longer present in [package] are ignored,
  ///   never crashing this lookup.
  /// * [PracticeFocus.incorrectQuestions] — any question with
  ///   [QuestionState.timesIncorrect] greater than zero.
  /// * [PracticeFocus.bookmarkedQuestions] — bookmarked questions in the
  ///   active exam, including ones that have not been answered yet.
  ///
  /// Fewer than [requestedCount] eligible questions ("mala pule") is not
  /// an error — every eligible question (up to [maxCount], if given) is
  /// returned; check `questions.length` against [requestedCount] to show
  /// "N of M available" messaging if desired. Zero eligible questions
  /// ("brak pytan") does throw [PracticeGenerationUnavailable], matching
  /// [ExamOverviewScreen]'s existing "never start a session with zero
  /// real questions" empty-state principle — never a session that
  /// silently has nothing in it.
  factory PracticeGenerator.select({
    required ContentPackage package,
    required List<QuestionState> questionStates,
    required int requestedCount,
    int? maxCount,
    String? domainId,
    String? topicId,
    PracticeFocus focus = PracticeFocus.any,
    Set<String> excludedQuestionIds = const {},
    Random? random,
  }) {
    if (requestedCount <= 0) {
      throw ArgumentError.value(
          requestedCount, 'requestedCount', 'must be positive');
    }
    if (maxCount != null && maxCount <= 0) {
      throw const PracticeGenerationUnavailable(
        "You've reached today's free practice limit.",
      );
    }

    final validation = const ContentValidator().validate(package);
    if (!validation.isValid) {
      throw const PracticeGenerationUnavailable('Practice content is invalid.');
    }

    // Mirrors MockExamBlueprint.fromPackage's own demo detection and
    // validation exactly, including reusing its ensureDemoAllowed gate —
    // see that class's doc comment; not duplicated as a second gate.
    final bool isDemo = package.exam.id.startsWith('demo_') ||
        package.questions.any((q) => q.tags.contains('demo'));
    if (isDemo) {
      MockExamBlueprint.ensureDemoAllowed();
      if (!package.exam.id.startsWith('demo_') ||
          package.questions.any((q) =>
              !q.tags.contains('demo') ||
              !q.id.startsWith('demo-') ||
              !q.questionText.startsWith('[Demo]') ||
              q.status != QuestionStatus.draft)) {
        throw const PracticeGenerationUnavailable(
            'Demo questions must be clearly labelled drafts.');
      }
    }
    final List<Question> eligible =
        isDemo ? package.questions : package.approvedQuestions;

    Iterable<Question> pool =
        eligible.where((q) => !excludedQuestionIds.contains(q.id));
    if (domainId != null) {
      pool = pool.where((q) => q.domainId == domainId);
    }
    if (topicId != null) {
      pool = pool.where((q) => q.topicId == topicId);
    }

    switch (focus) {
      case PracticeFocus.any:
        break;
      case PracticeFocus.bookmarkedQuestions:
        final savedIds = {
          for (final state in questionStates)
            if (state.examId == package.exam.id && state.bookmarked)
              state.questionId,
        };
        pool = pool.where((q) => savedIds.contains(q.id));
      case PracticeFocus.incorrectQuestions:
        final Set<String> incorrectIds = {
          for (final state in questionStates)
            if (state.timesIncorrect > 0) state.questionId,
        };
        pool = pool.where((q) => incorrectIds.contains(q.id));
      case PracticeFocus.weakAreas:
        final double threshold =
            package.exam.mockExam.practicePassingPercent / 100;
        final Set<String> weakTopicIds =
            _weakTopicIds(questionStates, package.questions, threshold);
        pool = pool.where((q) => weakTopicIds.contains(q.topicId));
    }

    final List<Question> sorted = pool.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (sorted.isEmpty) {
      if (focus == PracticeFocus.bookmarkedQuestions) {
        throw const PracticeGenerationUnavailable(
          'No saved questions match this selection. Bookmark questions during practice, or choose another topic.',
        );
      }
      throw const PracticeGenerationUnavailable(
          'There are no eligible questions for this selection.');
    }

    if (random != null) sorted.shuffle(random);

    final int cap = [
      requestedCount,
      if (maxCount != null) maxCount,
      sorted.length,
    ].reduce((a, b) => a < b ? a : b);

    return PracticeGenerator._(
      List.unmodifiable(sorted.take(cap)),
      requestedCount,
      focus,
    );
  }

  static Set<String> _weakTopicIds(
    List<QuestionState> questionStates,
    List<Question> allQuestions,
    double accuracyThreshold,
  ) {
    final Map<String, String> topicByQuestionId = {
      for (final q in allQuestions) q.id: q.topicId,
    };
    final Map<String, (int correct, int seen)> byTopic = {};
    for (final state in questionStates) {
      if (state.timesSeen == 0) continue;
      final String? topicId = topicByQuestionId[state.questionId];
      // A question the user has history for but that no longer exists in
      // the current content package (e.g. retired) contributes nothing —
      // never crashes this lookup.
      if (topicId == null) continue;
      final (correct, seen) = byTopic[topicId] ?? (0, 0);
      byTopic[topicId] = (correct + state.timesCorrect, seen + state.timesSeen);
    }
    return {
      for (final MapEntry(key: topicId, value: (correct, seen))
          in byTopic.entries)
        if (correct / seen < accuracyThreshold) topicId,
    };
  }

  /// The questions selected — never empty (see [select]'s doc comment),
  /// never containing a duplicate [Question.id], in a stable,
  /// deterministic order unless an explicit random source was supplied.
  final List<Question> questions;

  /// What was originally asked for — compare against `questions.length`
  /// to detect a small-pool result that returned fewer.
  final int requestedCount;

  final PracticeFocus focus;
}

/// The `maxCount` to pass to [PracticeGenerator.select] for today's
/// free-tier practice limit, or `null` for no limit at all (an
/// entitlement that [Entitlement.isActiveAt] `now`).
///
/// [answeredToday] must come from real, persisted attempt history (e.g.
/// practice-type entries in `ProgressRepository.answerAttemptsForExam`,
/// filtered by the caller to today) — never an in-memory or easily-reset
/// counter; per this architecture's Section 22, "Daily usage is
/// calculated from persisted attempts, not an easily reset widget
/// counter."
///
/// Never negative: a free user who has already answered at or beyond
/// [dailyLimit] today gets `0` — a real, hard "no more today" signal to
/// [PracticeGenerator.select] — not a negative number.
int? maxFreePracticeQuestionsToday({
  required Entitlement entitlement,
  required DateTime now,
  required int answeredToday,
  required int dailyLimit,
}) {
  if (entitlement.isActiveAt(now)) return null;
  final int remaining = dailyLimit - answeredToday;
  return remaining < 0 ? 0 : remaining;
}

/// How many of [attempts] count toward today's free-tier practice limit —
/// the `answeredToday` input [maxFreePracticeQuestionsToday] needs.
///
/// Only [AttemptSessionType.practice] attempts count: a diagnostic or mock
/// exam attempt exercises a question too, but neither is the thing this
/// specific daily cap governs.
///
/// **Product decision (PREP-667): the daily reset is a UTC calendar day,
/// not the user's local calendar day.** The ticket did not specify
/// either explicitly, so this was decided deliberately rather than
/// defaulted into, for two concrete reasons:
///
/// 1. Every persisted timestamp in this app — including
///    [AnswerAttempt.answeredAt] itself — is documented and stored as
///    UTC; a local-day reset would need to convert back to a *device's
///    current* timezone every time this runs, silently changing meaning
///    if the user travels or the device's timezone setting changes
///    between attempts, which a UTC boundary is immune to.
/// 2. It keeps this pure function, and its tests, fully deterministic:
///    a local-day boundary would make the very same `attempts`/`now`
///    inputs count differently depending on the *test runner's* system
///    timezone, not just the simulated user's — a real source of CI
///    flakiness this design avoids entirely.
///
/// The tradeoff, accepted knowingly: a free user near a local midnight
/// far from UTC (e.g. UTC-8 or UTC+8) sees their daily allowance reset
/// several hours before or after their own local midnight. If product
/// feedback later shows this is confusing, switching to a local-day
/// boundary is a contained, single-function change — but it should be
/// re-evaluated deliberately, not slipped in as a side effect of an
/// unrelated change, given the CI-determinism cost above.
///
/// "Today" is computed as a UTC calendar-day comparison ([DateTime.toUtc]'s
/// year/month/day against [now]'s).
int practiceAttemptsAnsweredToday({
  required List<AnswerAttempt> attempts,
  required DateTime now,
}) {
  final DateTime today = now.toUtc();
  bool isToday(DateTime t) {
    final DateTime utc = t.toUtc();
    return utc.year == today.year &&
        utc.month == today.month &&
        utc.day == today.day;
  }

  return attempts
      .where((a) =>
          a.sessionType == AttemptSessionType.practice && isToday(a.answeredAt))
      .length;
}
