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
      DateTime Function() now = DateTime.now})
      : _now = now;

  final Entitlement? entitlement;
  final MockExamBlueprint blueprint;
  final ProgressRepository repository;
  final DateTime Function() _now;
  MockAttempt? _attempt;
  List<Question>? _restoredQuestions;
  bool _busy = false;
  bool _loaded = false;
  final Set<String> _usedIds = {};

  MockAttempt? get attempt => _attempt;
  List<Question> get questions => _restoredQuestions ?? blueprint.questions;
  int get currentIndex => _attempt?.currentQuestionIndex ?? 0;
  Question get currentQuestion => questions[currentIndex];
  int get unansweredCount => questions.length - (_attempt?.answeredCount ?? 0);
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
        var sequence = 1;
        String id;
        do {
          id = '${blueprint.package.exam.id}-mock-${sequence++}';
        } while (_usedIds.contains(id));
        final previous =
            await repository.mockAttemptsForExam(blueprint.package.exam.id);
        if (entitlement != null &&
            !entitlement!.isActiveAt(_now()) &&
            previous.length >=
                blueprint.package.exam.freeTier.includedMockExams) {
          throw const MockExamUnavailable(
              'Your included mock exam allowance has been used.');
        }
        final seen =
            (await repository.answerAttemptsForExam(blueprint.package.exam.id))
                .map((a) => a.questionId)
                .toSet();
        for (final attempt in previous) {
          seen.addAll(attempt.answers.keys);
        }
        var selection = blueprint.questions;
        final reserved = await effectiveMockReserve(
            repository: repository,
            package: blueprint.package,
            entitlement:
                entitlement ?? Entitlement.free(lastVerifiedAt: _now()),
            now: _now());
        if (reserved.isNotEmpty) {
          selection = MockExamBlueprint.fromPackage(blueprint.package,
                  preferredQuestionIds: reserved)
              .questions;
        }
        final next = MockAttempt(
            id: id,
            examId: blueprint.package.exam.id,
            questionIds: selection.map((q) => q.id).toList(),
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
        _restoredQuestions = selection;
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
        _requireActive();
        final correct = questions
            .where((q) => _attempt!.answers[q.id] == q.correctAnswerId)
            .length;
        final now = _now().toUtc();
        final end =
            now.isBefore(_attempt!.startedAt) ? _attempt!.startedAt : now;
        await _save(_attempt!.copyWith(
            status: MockAttemptStatus.completed,
            completedAt: end,
            correctCount: correct));
      });

  MockExamResult get result => blueprint.resultFor(_attempt!);

  void _requireActive() {
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
