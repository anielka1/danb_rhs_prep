import 'dart:convert';
import '../domain/models/answer_attempt.dart';
import '../domain/repositories/mock_completion_repository.dart';
import 'dart:math';
import '../domain/models/answer_order.dart';
import '../domain/models/entitlement.dart';
import '../study_plan/study_schedule_service.dart';
import '../domain/models/mock_attempt.dart';
import '../domain/repositories/progress_repository.dart';
import '../features/questions/domain/question.dart';
import 'mock_exam_blueprint.dart';

/// One mutable holder, following BootstrapSessionController's pattern.
/// Writes commit atomically through the repository before changing visible state.
/// Widgets own rendering and navigation; this class owns exam state and scoring.
class MockExamController {
  MockExamController(
      {required this.blueprint,
      required this.repository,
      this.entitlement,
      DateTime Function() now = DateTime.now,
      Random? random})
      : _now = now,
        _random = random ?? Random();

  final Entitlement? entitlement;
  final MockExamBlueprint blueprint;
  final ProgressRepository repository;
  final DateTime Function() _now;
  final Random _random;
  MockAttempt? _attempt;
  List<Question>? _restoredQuestions;
  MockAttempt? _pendingCompletion;
  List<AnswerAttempt>? _pendingGrades;
  bool _busy = false;
  bool _loaded = false;
  final Set<String> _usedIds = {};

  MockAttempt? get attempt => _attempt;
  List<Question> get questions => _restoredQuestions ?? blueprint.questions;
  int get currentIndex => _attempt?.currentQuestionIndex ?? 0;
  Question get currentQuestion => questions[currentIndex];
  int get unansweredCount => questions.length - (_attempt?.answeredCount ?? 0);
  bool get completionPending => _pendingCompletion != null;
  bool get inProgress => _attempt?.status == MockAttemptStatus.inProgress;
  bool get isExpired =>
      blueprint.config.timed && _attempt != null && remaining == Duration.zero;
  Duration get remaining {
    final start = _attempt?.startedAt;
    final duration = Duration(minutes: blueprint.config.durationMinutes);
    if (start == null) return duration;
    final elapsed = _now().toUtc().difference(start);
    if (elapsed.isNegative) return duration;
    return elapsed >= duration ? Duration.zero : duration - elapsed;
  }

  Future<void> load() => _exclusive(() async {
        final saved =
            await repository.mockAttemptsForExam(blueprint.package.exam.id);
        _usedIds.addAll(saved.map((a) => a.id));
        final active = saved
            .where((a) => a.status == MockAttemptStatus.inProgress)
            .toList();
        if (active.length > 1) {
          throw const FormatException('Multiple active mock exams.');
        }
        if (active.isNotEmpty) {
          final questions = blueprint.resolve(active.single);
          _restoredQuestions = questions;
          _attempt = active.single;
        }
        _loaded = true;
      });

  Future<void> start() => _exclusive(() async {
        if (!_loaded) throw StateError('Load the repository before starting.');
        if (inProgress) return;
        final previous =
            await repository.mockAttemptsForExam(blueprint.package.exam.id);
        _usedIds.addAll(previous.map((a) => a.id));
        var sequence = 1;
        String id;
        do {
          id = '${blueprint.package.exam.id}-mock-${sequence++}';
        } while (_usedIds.contains(id));
        final active = previous
            .where((a) => a.status == MockAttemptStatus.inProgress)
            .toList();
        if (active.length > 1) {
          throw const FormatException('Multiple active mock exams.');
        }
        if (active.isNotEmpty) {
          final restored = blueprint.resolve(active.single);
          _attempt = active.single;
          _restoredQuestions = restored;
          _usedIds.add(active.single.id);
          return;
        }
        if (entitlement != null &&
            !entitlement!.isActiveAt(_now()) &&
            previous.length >=
                blueprint.package.exam.freeTier.includedMockExams) {
          throw const MockExamUnavailable(
              'Your included mock exam allowance has been used.');
        }
        final history =
            await repository.answerAttemptsForExam(blueprint.package.exam.id);
        final seen = history.map((a) => a.questionId).toSet();
        final exposures = <String, int>{};
        // Each practice/diagnostic attempt counts once. Mock selections count
        // once even if unanswered, avoiding the same abandoned exam on retake.
        // Exclude matching mock answer rows to avoid double-counting.
        final mockIds = previous.map((a) => a.id).toSet();
        for (final a in history) {
          if (!mockIds.contains(a.sessionId)) {
            exposures.update(a.questionId, (n) => n + 1, ifAbsent: () => 1);
          }
        }
        for (final a in previous) {
          for (final id in a.questionIds) {
            exposures.update(id, (n) => n + 1, ifAbsent: () => 1);
          }
        }
        for (final attempt in previous) {
          seen.addAll(attempt.answers.keys);
        }
        final reserved = await effectiveMockReserve(
            repository: repository,
            package: blueprint.package,
            entitlement:
                entitlement ?? Entitlement.free(lastVerifiedAt: _now()),
            now: _now());
        final selection = MockExamBlueprint.fromPackage(blueprint.package,
                preferredQuestionIds: reserved,
                exposureCounts: exposures,
                random: _random)
            .questions;
        final next = MockAttempt(
            id: id,
            examId: blueprint.package.exam.id,
            questionIds: selection.map((q) => q.id).toList(),
            answerOrder: AnswerOrder.shuffled(selection, _random),
            seenBeforeStartCount:
                selection.where((q) => seen.contains(q.id)).length,
            answers: const {},
            flaggedQuestionIds: const {},
            status: MockAttemptStatus.inProgress,
            startedAt: _now().toUtc(),
            durationMinutes: blueprint.config.durationMinutes,
            contentVersion: blueprint.package.contentVersion);
        await _save(next);
        _usedIds.add(id);
        _restoredQuestions = blueprint.resolve(next);
      });

  Future<void> answer(String answerId) => _exclusive(() async {
        _requireActive();
        if (isExpired) throw StateError('Time has expired.');
        if (!currentQuestion.answers.any((a) => a.id == answerId)) {
          throw ArgumentError.value(answerId, 'answerId');
        }
        await _save(_attempt!.copyWith(
            answers: {..._attempt!.answers, currentQuestion.id: answerId}));
      });

  Future<void> toggleFlag() => _exclusive(() async {
        _requireActive();
        final flags = {..._attempt!.flaggedQuestionIds};
        if (!flags.remove(currentQuestion.id)) flags.add(currentQuestion.id);
        await _save(_attempt!.copyWith(flaggedQuestionIds: flags));
      });

  bool canMoveTo(int index) =>
      inProgress &&
      index >= 0 &&
      index < questions.length &&
      index != currentIndex &&
      (blueprint.config.allowsBackNavigation || index > currentIndex);

  Future<void> moveTo(int index) => _exclusive(() async {
        _requireActive();
        if (!canMoveTo(index)) throw ArgumentError.value(index, 'index');
        await _save(_attempt!.copyWith(currentQuestionIndex: index));
      });

  Future<void> finish() => _exclusive(() async {
        _requireActive(finishing: true);
        final storage = repository;
        if (storage is! MockCompletionRepository) {
          throw UnsupportedError('Atomic mock completion unavailable');
        }
        if (_pendingCompletion == null) {
          final now = _now();
          final end = now.toUtc().isBefore(_attempt!.startedAt)
              ? _attempt!.startedAt
              : now.toUtc();
          final local = end.toLocal();
          final day = '${local.year.toString().padLeft(4, '0')}-'
              '${local.month.toString().padLeft(2, '0')}-'
              '${local.day.toString().padLeft(2, '0')}';
          final grades = [
            for (final q in questions)
              if (_attempt!.answers.containsKey(q.id))
                AnswerAttempt(
                    id: 'mock-final:${jsonEncode([_attempt!.id, q.id])}',
                    examId: _attempt!.examId,
                    questionId: q.id,
                    domainId: q.domainId,
                    topicId: q.topicId,
                    difficulty: q.difficulty,
                    sessionId: _attempt!.id,
                    sessionType: AttemptSessionType.mock,
                    selectedAnswerId: _attempt!.answers[q.id]!,
                    isCorrect: _attempt!.answers[q.id] == q.correctAnswerId,
                    answeredAt: end,
                    localAnsweredDate: day,
                    contentVersion: _attempt!.contentVersion,
                    questionVersion: q.version,
                    correctAnswerId: q.correctAnswerId,
                    explanation: q.explanation),
          ];
          _pendingCompletion = _attempt!.copyWith(
              status: MockAttemptStatus.completed,
              completedAt: end,
              correctCount: grades.where((a) => a.isCorrect).length);
          _pendingGrades = List.unmodifiable(grades);
        }
        // Keep this exact payload after an ambiguous write failure. Retry must
        // not change the timestamp, final choices, or question-state counters.
        await (storage as MockCompletionRepository)
            .completeMockAttempt(_pendingCompletion!, _pendingGrades!);
        _attempt = _pendingCompletion;
        _pendingCompletion = null;
        _pendingGrades = null;
      });

  MockExamResult get result => blueprint.resultFor(_attempt!);

  void _requireActive({bool finishing = false}) {
    if (!finishing && _pendingCompletion != null) {
      throw StateError('Retry saving the completed exam first.');
    }
    if (!inProgress) throw StateError('No active mock exam.');
  }

  Future<void> _save(MockAttempt next) async {
    await repository.saveMockAttempt(next);
    _attempt = next;
  }

  Future<void> _exclusive(Future<void> Function() operation) async {
    if (_busy) throw StateError('A mock exam operation is already pending.');
    _busy = true;
    try {
      await operation();
    } finally {
      _busy = false;
    }
  }
}
