import '../data/local/id_generator.dart';
import '../domain/models/answer_attempt.dart';
import '../domain/models/practice_session.dart';
import '../domain/repositories/progress_repository.dart';
import '../features/questions/domain/question.dart';

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
/// [progressRepository] is optional: recording attempts/question-state and
/// persisting the session are best-effort and silently skipped (or
/// swallowed on failure) when it's null or a write fails, since — like
/// `HomeScreen`'s progress card — the interactive flow itself must work
/// with no backing store at all (always true in production today).
class PracticeSessionController {
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

  final ProgressRepository? progressRepository;
  final List<Question> questions;
  final DateTime Function() _now;
  final IdGenerator _idGenerator;

  PracticeSession _session;
  PracticeSession get session => _session;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  int get totalQuestions => questions.length;
  Question get currentQuestion => questions[_currentIndex];
  bool get isLastQuestion => _currentIndex == questions.length - 1;
  bool get canGoToPrevious => _currentIndex > 0;

  /// Only lets "Next" browse back into already-answered territory —
  /// advancing past the current unanswered question requires submitting
  /// an answer, never a bare navigation tap.
  bool get canGoToNext =>
      _currentIndex < questions.length - 1 &&
      isAnswered(questions[_currentIndex + 1].id);

  final Map<String, String> _selectedAnswerIds = {};
  final Map<String, bool> _isCorrect = {};

  String? selectedAnswerFor(String questionId) =>
      _selectedAnswerIds[questionId];
  bool isAnswered(String questionId) =>
      _selectedAnswerIds.containsKey(questionId);
  bool? isCorrectFor(String questionId) => _isCorrect[questionId];

  int get answeredCount => _selectedAnswerIds.length;
  int get correctCount => _isCorrect.values.where((correct) => correct).length;

  Duration get elapsed =>
      (_session.completedAt ?? _now().toUtc()).difference(_session.startedAt);

  /// Moves to [index] without any bounds/sequencing guard — callers
  /// (typically after checking [canGoToPrevious]/[canGoToNext], or right
  /// after [submitAnswer] to reveal the question just answered) own that
  /// decision.
  void moveTo(int index) {
    assert(index >= 0 && index < questions.length);
    _currentIndex = index;
  }

  /// A submission already in flight, if any — a rapid double-tap on
  /// Submit (before the UI's own guard disables the button, or from any
  /// other caller with no guard of its own) reuses this result instead of
  /// recording a second attempt for one logical submission. Cleared once
  /// the in-flight call finishes, successfully or not, so the *next*
  /// distinct submission (a genuinely new tap, e.g. after `moveTo`-ing
  /// back to change an earlier answer) always starts fresh.
  Future<bool>? _pendingSubmit;

  /// Records the answer for [currentQuestion] and returns whether it was
  /// correct. Best-effort persistence: a missing or failing
  /// [progressRepository] never prevents the interactive result from
  /// being returned. Resilient to a double-submit — see [_pendingSubmit].
  Future<bool> submitAnswer(String answerId) {
    final Future<bool>? pending = _pendingSubmit;
    if (pending != null) return pending;
    final Future<bool> result = _submitAnswer(answerId);
    _pendingSubmit = result;
    return result.whenComplete(() => _pendingSubmit = null);
  }

  Future<bool> _submitAnswer(String answerId) async {
    final Question question = currentQuestion;
    final bool correct = answerId == question.correctAnswerId;
    _selectedAnswerIds[question.id] = answerId;
    _isCorrect[question.id] = correct;

    final ProgressRepository? repo = progressRepository;
    if (repo != null) {
      try {
        await repo.recordAnswerAttempt(
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
            sessionType: AttemptSessionType.practice,
            selectedAnswerId: answerId,
            isCorrect: correct,
            answeredAt: _now().toUtc(),
            contentVersion: session.contentVersion,
          ),
        );
      } catch (_) {
        // Recording history must never block the interactive result above.
      }
    }
    return correct;
  }

  /// Marks the session finished. Best-effort persistence, same reasoning
  /// as [submitAnswer].
  Future<void> complete() async {
    _session = _session.copyWith(
      status: SessionStatus.completed,
      completedAt: _now().toUtc(),
    );
    final ProgressRepository? repo = progressRepository;
    if (repo == null) return;
    try {
      await repo.savePracticeSession(_session);
    } catch (_) {
      // Same best-effort reasoning as submitAnswer.
    }
  }
}
