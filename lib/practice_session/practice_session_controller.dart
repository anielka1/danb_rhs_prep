import '../study_plan/study_plan.dart';
import '../data/local/id_generator.dart';
import '../domain/models/answer_attempt.dart';
import '../domain/models/answer_feedback.dart';
import '../domain/models/practice_session.dart';
import '../domain/models/question_state.dart';
import '../domain/repositories/progress_repository.dart';
import '../features/questions/domain/question.dart';
import 'practice_persistence.dart';

/// Drives one practice session's question-by-question flow: which
/// question is current, what's been answered so far (and whether it was
/// correct), and the running score/elapsed time — the single source of
/// truth [PracticeQuestionScreen]/[AnswerExplanationScreen]/
/// [PracticeSummaryScreen] render, so none of them ever hardcodes a
/// counter, timer, or score.
///
/// A plain mutable holder, not a `ChangeNotifier` — mirroring
/// `BootstrapSessionController`. Every question transition is a fresh
/// screen push (`Navigator.pushReplacement`) that reads this controller's
/// state at build time, so nothing here needs to *notify* a still-mounted
/// widget of a change.
///
/// [progressRepository] is optional for session-only previews. When a
/// repository write fails, the interactive result stays available and
/// [hasUnsavedChanges] exposes the retained writes for [retrySaving].
/// The retry queue lives only as long as this controller.
class PracticeSessionController {
  late final PracticePersistence _persistence =
      PracticePersistence(progressRepository);
  bool get hasUnsavedChanges => _persistence.hasUnsavedChanges;
  Future<void> retrySaving() => _persistence.retry();
  Future<void> saveSession() => _persistence.saveSession(_session);
  PracticeSessionController({
    required PracticeSession session,
    required List<Question> questions,
    this.progressRepository,
    DateTime Function() now = DateTime.now,
    IdGenerator idGenerator = const IdGenerator(),
  })  : _session = session,
        questions = List.unmodifiable(questions),
        _now = now,
        _idGenerator = idGenerator {
    assert(
      questions.length == session.questionIds.length &&
          _sameOrder(questions, session.questionIds),
      'questions must resolve session.questionIds, in the same order.',
    );
  }

  static bool _sameOrder(List<Question> questions, List<String> ids) {
    for (var i = 0; i < questions.length; i++) {
      if (questions[i].id != ids[i]) return false;
    }
    return true;
  }

  /// Builds a controller for [session] with its per-question
  /// answered/correct state restored from [progressRepository]'s
  /// already-recorded [AnswerAttempt]s for it (PREP-665).
  ///
  /// The plain constructor always starts with an empty [_feedback] map —
  /// correct for a session that is genuinely starting now, but wrong for
  /// one restored from [ProgressRepository.inProgressPracticeSession]
  /// after a restart: the database layer already survives a restart
  /// correctly (attempts, question state, and the session's own row are
  /// all still there — see
  /// `test/practice_session/practice_session_restart_test.dart`), but a
  /// freshly constructed controller alone has no way to know what was
  /// already answered, since that map is pure in-memory state. Use this
  /// constructor instead of the plain one whenever [session] might
  /// already be in progress; use the plain one only for a session that
  /// is verifiably brand new (nothing to restore, and nothing to query
  /// for).
  ///
  /// Only an [AnswerAttempt] whose [AnswerAttempt.sessionId] equals
  /// [session]'s own id, *and* whose [AnswerAttempt.questionId] is
  /// actually one of [PracticeSession.questionIds], is restored — a
  /// record matching the session id but naming a foreign or corrupted
  /// question id can never inflate [answeredCount]/[correctCount] or be
  /// shown as this session's feedback. This controller-level check does
  /// not, by itself, guarantee every id in [PracticeSession.questionIds]
  /// still resolves to a real [Question] in [questions] — a question
  /// retired from the active content package after this session was
  /// created is a separate, known gap handled (as a crash guard, not a
  /// full resolution) at `ExamOverviewScreen._startOrResumePractice`'s
  /// own `questionsById` lookup, not here.
  ///
  /// Best-effort, matching every other read/write here: a failing
  /// [progressRepository] returns a controller with an empty (not
  /// crashed) answered map — the interactive flow must still work,
  /// exactly as [submitAnswer]'s own failures never block it.
  ///
  /// Only the *latest* attempt per question is restored — via
  /// [ProgressRepository.answerAttemptsForExam]'s documented return
  /// order, not by comparing [AnswerAttempt.answeredAt] values, which can
  /// tie (see that field's own doc comment on storage precision) — so a
  /// question answered more than once in this session (changed via
  /// `moveTo`-ing back) resumes showing its most recent answer, matching
  /// what actually determines [QuestionState] today. [_currentIndex]
  /// resumes at the first not-yet-answered question (or the last
  /// question, if every question already has an answer), so a resumed
  /// session lands somewhere consistent with its own restored answered
  /// map, not back at question one.
  static Future<PracticeSessionController> resume({
    required PracticeSession session,
    required List<Question> questions,
    required ProgressRepository progressRepository,
    DateTime Function() now = DateTime.now,
    IdGenerator idGenerator = const IdGenerator(),
  }) async {
    final PracticeSessionController controller = PracticeSessionController(
      session: session,
      questions: questions,
      progressRepository: progressRepository,
      now: now,
      idGenerator: idGenerator,
    );

    try {
      final List<AnswerAttempt> attempts =
          await progressRepository.answerAttemptsForExam(session.examId);
      // Last-one-in-the-list wins, not a comparison of answeredAt values
      // — two attempts can carry the *identical* answeredAt (Drift's
      // storage truncates to whole seconds, see canonicalizeAnswerAttempt;
      // two submissions within the same second are ordinary, not
      // exceptional) with no other field able to break that tie, so
      // [ProgressRepository.answerAttemptsForExam]'s own return order is
      // relied on as the true chronological order instead — both
      // implementations return attempts in the order they were recorded.
      final Set<String> sessionQuestionIds = session.questionIds.toSet();
      final Map<String, AnswerAttempt> latestBySession = {};
      for (final attempt in attempts) {
        if (attempt.sessionId != session.id) continue;
        // A record sharing this sessionId but naming a questionId that
        // isn't actually part of this session (foreign data mixed in by
        // an id collision, or a corrupted/hand-edited row) must never
        // inflate answeredCount/correctCount or be shown as this
        // session's own feedback — sessionId alone is not sufficient
        // proof of membership.
        if (!sessionQuestionIds.contains(attempt.questionId)) continue;
        latestBySession[attempt.questionId] = attempt;
      }
      for (final attempt in latestBySession.values) {
        // Rebuilt entirely from what this *attempt* itself persisted —
        // never from `questions`/`currentQuestion` — so a resumed
        // session's feedback is the exact same snapshot the original
        // submitAnswer call evaluated, even if the question's content
        // has since changed (e.g. a content update corrected its
        // explanation or correct answer). See AnswerFeedback's and
        // AnswerAttempt.questionVersion's own doc comments.
        //
        // An attempt recorded before schema 3 (PREP-668) has none of
        // these three columns — there is no historical snapshot to
        // recover for it, so it's skipped here rather than falling back
        // to today's `Question` (which is exactly the bug this method
        // used to have: silently mixing a historical isCorrect verdict
        // with a possibly-different current explanation/correctAnswerId).
        // This is a real, accepted gap for installs upgrading from
        // schema < 3 only — every attempt recorded from schema 3 onward
        // always has this data.
        final int? questionVersion = attempt.questionVersion;
        final String? correctAnswerId = attempt.correctAnswerId;
        final String? explanation = attempt.explanation;
        if (questionVersion == null ||
            correctAnswerId == null ||
            explanation == null) {
          continue;
        }
        controller._feedback[attempt.questionId] = AnswerFeedback(
          questionId: attempt.questionId,
          questionVersion: questionVersion,
          selectedAnswerId: attempt.selectedAnswerId,
          correctAnswerId: correctAnswerId,
          isCorrect: attempt.isCorrect,
          explanation: explanation,
          answeredAt: attempt.answeredAt,
          contentVersion: attempt.contentVersion,
        );
      }

      final int firstUnanswered = questions
          .indexWhere((question) => !controller.isAnswered(question.id));
      controller._currentIndex =
          firstUnanswered == -1 ? questions.length - 1 : firstUnanswered;
      controller._furthestIndex = controller._currentIndex;
    } catch (_) {
      // Best-effort: see this method's own doc comment. The controller
      // returned above (with an empty answered map, at question one) is
      // still fully usable.
    }

    return controller;
  }

  final ProgressRepository? progressRepository;
  final List<Question> questions;
  final DateTime Function() _now;
  final IdGenerator _idGenerator;

  PracticeSession _session;
  PracticeSession get session => _session;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  /// The furthest index ever reached in this session (PREP-460) — either
  /// by genuinely advancing forward (submitting an answer and moving to
  /// the next question) or by wherever a resumed session picked back up.
  /// [canGoToNext] is gated on this, not on [isAnswered]: after using
  /// Previous to browse back into already-answered history from a
  /// not-yet-answered "current" question, Next must still be able to
  /// return you to that exact position — it was never itself answered,
  /// but you were already there, and gating on [isAnswered] alone left
  /// Next permanently disabled the moment you stepped back from it (a
  /// real, confirmed bug, not the intended "never skip ahead to fresh
  /// content" restriction).
  int _furthestIndex = 0;
  int get totalQuestions => questions.length;
  Question get currentQuestion => questions[_currentIndex];
  bool get isLastQuestion => _currentIndex == questions.length - 1;
  bool get canGoToPrevious => _currentIndex > 0;

  /// Lets "Next" return to any position already reached this session
  /// (browsing back into answered history, or back to the not-yet-
  /// answered question you most recently came from) — but never skip
  /// ahead to genuinely fresh content past [_furthestIndex]; that still
  /// requires submitting an answer, never a bare navigation tap.
  bool get canGoToNext =>
      _currentIndex < questions.length - 1 &&
      _currentIndex + 1 <= _furthestIndex;

  final Map<String, AnswerFeedback> _feedback = {};

  String? selectedAnswerFor(String questionId) =>
      _feedback[questionId]?.selectedAnswerId;
  bool isAnswered(String questionId) => _feedback.containsKey(questionId);
  bool? isCorrectFor(String questionId) => _feedback[questionId]?.isCorrect;

  /// The immutable evaluation result for [questionId], if it's been
  /// answered — see [AnswerFeedback]'s own doc comment for why
  /// `AnswerExplanationScreen`/`PracticeQuestionScreen` read the correct
  /// answer, explanation, and correct/incorrect state from this rather
  /// than independently re-reading them from [questions] at render time.
  AnswerFeedback? feedbackFor(String questionId) => _feedback[questionId];

  int get answeredCount => _feedback.length;
  int get correctCount =>
      _feedback.values.where((feedback) => feedback.isCorrect).length;

  /// Locally-cached bookmark state (PREP-460), keyed by questionId —
  /// unlike [_feedback], [QuestionState.bookmarked] is not session-scoped
  /// (a question stays bookmarked across every future session), so this
  /// cache exists purely to avoid re-reading [progressRepository] on
  /// every rebuild; the real, durable value always lives in
  /// [QuestionState] via [progressRepository].
  final Map<String, bool> _bookmarked = {};

  /// Whether [questionId] is currently bookmarked. Defaults to `false`
  /// until [loadBookmark] resolves — never a guess, just the same
  /// "unseen" default [QuestionState.unseen] itself uses.
  bool isBookmarked(String questionId) => _bookmarked[questionId] ?? false;

  /// Best-effort loads [questionId]'s persisted bookmark state into the
  /// cache [isBookmarked] reads, if not already loaded (or toggled) this
  /// session. A null [progressRepository] or a failing read leaves the
  /// cache at its default (`false`) rather than blocking the screen —
  /// matching this controller's established best-effort persistence
  /// philosophy (see [submitAnswer]'s own doc comment).
  Future<void> loadBookmark(String questionId) async {
    if (_bookmarked.containsKey(questionId)) return;
    final ProgressRepository? repo = progressRepository;
    if (repo == null) return;
    try {
      final QuestionState state =
          await repo.questionState(session.examId, questionId);
      // Re-checked after the await, not just before: a concurrent
      // toggleBookmarkLocally can race ahead of this read (the screen
      // fires this load as soon as it's built, and a user can tap the
      // toggle before a real disk read completes) and populate the
      // cache first. Without this second check, the stale value this
      // load started with would land *after* the user's toggle and
      // silently revert it — the toggle would flip the icon/color for
      // a moment and then undo itself, with no error and no visible
      // cause.
      if (_bookmarked.containsKey(questionId)) return;
      _bookmarked[questionId] = state.bookmarked;
    } catch (_) {
      // Best-effort — see doc comment above.
    }
  }

  /// Flips [questionId]'s bookmark in the local cache and returns the
  /// new value — synchronous, so a caller can update its UI immediately
  /// without waiting on persistence. Call [persistBookmark] afterward
  /// (typically right after, in the same handler) to actually save it.
  bool toggleBookmarkLocally(String questionId) {
    final bool newValue = !isBookmarked(questionId);
    _bookmarked[questionId] = newValue;
    return newValue;
  }

  /// Persists the optimistic bookmark value. A failed write remains in
  /// the session's retry queue; rapid changes keep the latest desired value.
  Future<void> persistBookmark(String questionId, bool value) =>
      _persistence.saveBookmark(session.examId, questionId, value);

  Duration get elapsed =>
      (_session.completedAt ?? _now().toUtc()).difference(_session.startedAt);

  /// Moves to [index] without any bounds/sequencing guard — callers
  /// (typically after checking [canGoToPrevious]/[canGoToNext], or right
  /// after [submitAnswer] to reveal the question just answered) own that
  /// decision. Also advances [_furthestIndex] when [index] is further
  /// than any position reached before — moving backward (Previous) never
  /// shrinks it, so [canGoToNext] can still return to wherever this
  /// session has genuinely been.
  void moveTo(int index) {
    assert(index >= 0 && index < questions.length);
    _currentIndex = index;
    if (index > _furthestIndex) _furthestIndex = index;
  }

  /// A submission already in flight, if any — a rapid double-tap on
  /// Submit (before the UI's own guard disables the button, or from any
  /// other caller with no guard of its own) reuses this result instead of
  /// recording a second attempt for one logical submission. Cleared once
  /// the in-flight call finishes, successfully or not, so the *next*
  /// distinct submission (a genuinely new tap, e.g. after `moveTo`-ing
  /// back to change an earlier answer) always starts fresh.
  Future<AnswerFeedback>? _pendingSubmit;

  /// Evaluates [answerId] against [currentQuestion] exactly once (PREP-668)
  /// — guarded by [_pendingSubmit] against a concurrent double-submit the
  /// same way this always has been — persists an [AnswerAttempt], and
  /// returns the immutable [AnswerFeedback] built from that same
  /// evaluation. A failed write retains this exact attempt for retry and
  /// never prevents the interactive result from being returned.
  Future<AnswerFeedback> submitAnswer(String answerId,
      {bool? confident, int? activeDurationSeconds}) {
    final Future<AnswerFeedback>? pending = _pendingSubmit;
    if (pending != null) return pending;
    final Future<AnswerFeedback> result =
        _submitAnswer(answerId, confident, activeDurationSeconds);
    _pendingSubmit = result;
    return result.whenComplete(() => _pendingSubmit = null);
  }

  Future<AnswerFeedback> _submitAnswer(
      String answerId, bool? confident, int? activeDurationSeconds) async {
    final Question question = currentQuestion;
    final bool correct = answerId == question.correctAnswerId;
    // Read once and reused for both the returned feedback and the
    // persisted attempt below — not two separate `_now()` calls, which
    // could (with a real clock) tick forward between them and give the
    // "same evaluation" two different timestamps.
    final DateTime localNow = _now();
    final DateTime answeredAt = localNow.toUtc();

    // Built once, from this single `question` read above — see
    // AnswerFeedback's own doc comment for why the UI must read the
    // correct answer/explanation/version from this returned snapshot
    // rather than a later, independent read of `questions`.
    final AnswerFeedback feedback = AnswerFeedback(
      questionId: question.id,
      questionVersion: question.version,
      selectedAnswerId: answerId,
      correctAnswerId: question.correctAnswerId,
      isCorrect: correct,
      explanation: question.explanation,
      answeredAt: answeredAt,
      contentVersion: session.contentVersion,
    );
    _feedback[question.id] = feedback;

    final ProgressRepository? repo = progressRepository;
    if (repo != null) {
      await _persistence.saveAttempt(
        AnswerAttempt(
          // A fresh, unique id per attempt — not a value derived from
          // session+question, which would collide (and, against a real
          // database's primary key, fail or silently overwrite) the
          // moment the same question is answered more than once in the
          // same session, e.g. after `moveTo`-ing back to change an
          // earlier answer.
          id: _idGenerator.generate(),
          examId: session.examId,
          questionId: question.id,
          domainId: question.domainId,
          topicId: question.topicId,
          difficulty: question.difficulty,
          sessionId: session.id,
          sessionType: session.mode == PracticeMode.diagnostic
              ? AttemptSessionType.diagnostic
              : AttemptSessionType.practice,
          confident: confident,
          activeDurationSeconds: activeDurationSeconds,
          localAnsweredDate: dateKey(localNow),
          selectedAnswerId: answerId,
          isCorrect: correct,
          answeredAt: answeredAt,
          contentVersion: session.contentVersion,
          // Persisted redundantly alongside the attempt (PREP-668) so a
          // later resume() can rebuild this exact AnswerFeedback from
          // the attempt itself — see AnswerAttempt.questionVersion's
          // own doc comment for why.
          questionVersion: question.version,
          correctAnswerId: question.correctAnswerId,
          explanation: question.explanation,
        ),
      );
    }
    return feedback;
  }

  /// Marks the session finished and retains its timestamp if saving needs retry.
  Future<void> complete() async {
    _session = _session.copyWith(
      status: SessionStatus.completed,
      completedAt: _session.completedAt ?? _now().toUtc(),
    );
    await saveSession();
  }
}
