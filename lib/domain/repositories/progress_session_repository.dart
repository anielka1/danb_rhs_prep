import 'mock_completion_repository.dart';
import '../models/study_schedule.dart';
import 'study_schedule_repository.dart';
import '../models/answer_attempt.dart';
import '../models/mock_attempt.dart';
import '../models/practice_session.dart';
import '../models/question_state.dart';
import '../models/readiness_snapshot.dart';
import 'progress_repository.dart';
import 'progress_reset_repository.dart';

/// A repository lease for one live UI generation. Reset drains accepted writes,
/// blocks new ones, then permanently retires this lease after successful deletion.
/// Old controllers therefore cannot recreate deleted progress, even after retry.
class ProgressSessionRepository
    implements
        ProgressRepository,
        StudyScheduleRepository,
        MockCompletionRepository {
  ProgressSessionRepository(this._storage);
  final ProgressRepository _storage;
  Future<void> _writes = Future.value();
  bool _resetting = false;
  bool _retired = false;

  bool get supportsReset => _storage is ProgressResetRepository;

  void _checkActive() {
    if (_retired || _resetting) {
      throw StateError('Study session is unavailable.');
    }
  }

  Future<void> _write(Future<void> Function() action) {
    try {
      _checkActive();
    } catch (error, stack) {
      return Future.error(error, stack);
    }
    final operation = _writes.then((_) => action());
    _writes =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  Future<T> _read<T>(Future<T> Function() action) async {
    _checkActive();
    return action();
  }

  Future<ProgressSessionRepository> reset(String examId) async {
    _checkActive();
    final storage = _storage;
    if (storage is! ProgressResetRepository) {
      throw UnsupportedError('Progress reset is unavailable.');
    }
    _resetting = true;
    try {
      await _writes;
      await (storage as ProgressResetRepository).resetProgressForExam(examId);
      _retired = true;
      return ProgressSessionRepository(_storage);
    } finally {
      _resetting = false;
    }
  }

  @override
  Future<List<StudyScheduleEntry>> studySchedule(String examId) =>
      _read(() async => _storage is StudyScheduleRepository
          ? await (_storage as StudyScheduleRepository).studySchedule(examId)
          : const []);
  @override
  Future<List<PracticeSession>> practiceSessionsForExam(String examId) =>
      _read(() async => _storage is StudyScheduleRepository
          ? await (_storage as StudyScheduleRepository)
              .practiceSessionsForExam(examId)
          : const []);
  @override
  Future<void> saveStudySchedule(
          String examId, List<StudyScheduleEntry> entries) =>
      _write(() async {
        if (_storage is! StudyScheduleRepository) {
          throw UnsupportedError('Calendar storage unavailable');
        }
        await (_storage as StudyScheduleRepository)
            .saveStudySchedule(examId, entries);
      });

  @override
  Future<void> recordAnswerAttempt(AnswerAttempt value) =>
      _write(() => _storage.recordAnswerAttempt(value));
  @override
  Future<void> saveQuestionState(QuestionState value) =>
      _write(() => _storage.saveQuestionState(value));
  @override
  Future<void> savePracticeSession(PracticeSession value) =>
      _write(() => _storage.savePracticeSession(value));
  @override
  Future<void> completeMockAttempt(
          MockAttempt attempt, List<AnswerAttempt> answers) =>
      _write(() async {
        final storage = _storage;
        if (storage is! MockCompletionRepository) {
          throw UnsupportedError('Atomic mock completion unavailable');
        }
        await (storage as MockCompletionRepository)
            .completeMockAttempt(attempt, answers);
      });

  @override
  Future<void> saveMockAttempt(MockAttempt value) =>
      _write(() => _storage.saveMockAttempt(value));
  @override
  Future<void> saveReadinessSnapshot(ReadinessSnapshot value) =>
      _write(() => _storage.saveReadinessSnapshot(value));
  @override
  Future<List<AnswerAttempt>> answerAttemptsForExam(String id) =>
      _read(() => _storage.answerAttemptsForExam(id));
  @override
  Future<QuestionState> questionState(String exam, String question) =>
      _read(() => _storage.questionState(exam, question));
  @override
  Future<List<QuestionState>> questionStatesForExam(String id) =>
      _read(() => _storage.questionStatesForExam(id));
  @override
  Future<PracticeSession?> inProgressPracticeSession(String id) =>
      _read(() => _storage.inProgressPracticeSession(id));
  @override
  Future<MockAttempt?> mockAttempt(String id) =>
      _read(() => _storage.mockAttempt(id));
  @override
  Future<List<MockAttempt>> mockAttemptsForExam(String id) =>
      _read(() => _storage.mockAttemptsForExam(id));
  @override
  Future<ReadinessSnapshot?> latestReadinessSnapshot(String id) =>
      _read(() => _storage.latestReadinessSnapshot(id));
  @override
  Future<List<ReadinessSnapshot>> readinessSnapshotsForExam(String id) =>
      _read(() => _storage.readinessSnapshotsForExam(id));
}
