import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/answer_attempt.dart';
import '../../domain/models/mock_attempt.dart';
import '../../domain/models/practice_session.dart';
import '../../domain/models/question_state.dart';
import '../../domain/models/readiness_band.dart';
import '../../domain/models/readiness_snapshot.dart';
import '../../domain/repositories/progress_repository.dart';
import '../local/app_database.dart';

/// The real, Drift/SQLite-backed [ProgressRepository] (PREP-661) — the
/// first production implementation; no adapter existed before this (every
/// caller — `PracticeSessionController`, `MockExamController`, `HomeScreen`,
/// `ProgressScreen` — was already built against the interface and treats a
/// missing repository as "no history yet", so wiring this in is the only
/// change needed to make their data genuinely persist).
///
/// Every [DateTime] is normalized to UTC on the way in and out, and every
/// enum is stored by its stable `.name`. [recordAnswerAttempt] is a true
/// `INSERT` (via [AnswerAttempts.id]'s primary-key constraint, never an
/// upsert) — see `IdGenerator`'s doc comment for why a caller must give
/// each attempt a genuinely unique id, not a value derived from
/// session+question that collides the moment the same question is
/// answered twice in one session.
class DriftProgressRepository implements ProgressRepository {
  DriftProgressRepository(this._db);

  final AppDatabase _db;

  // ---- Answer attempts (append-only) ----

  @override
  Future<void> recordAnswerAttempt(AnswerAttempt attempt) async {
    await _db.into(_db.answerAttempts).insert(
          AnswerAttemptsCompanion.insert(
            id: attempt.id,
            examId: attempt.examId,
            questionId: attempt.questionId,
            domainId: attempt.domainId,
            topicId: attempt.topicId,
            difficulty: attempt.difficulty,
            sessionId: attempt.sessionId,
            sessionType: attempt.sessionType.name,
            selectedAnswerId: attempt.selectedAnswerId,
            isCorrect: attempt.isCorrect,
            answeredAt: attempt.answeredAt.toUtc(),
          ),
        );
  }

  @override
  Future<List<AnswerAttempt>> answerAttemptsForExam(String examId) async {
    final rows = await (_db.select(_db.answerAttempts)
          ..where((t) => t.examId.equals(examId)))
        .get();
    return rows.map(_attemptToDomain).toList(growable: false);
  }

  AnswerAttempt _attemptToDomain(AnswerAttemptRow row) {
    return AnswerAttempt(
      id: row.id,
      examId: row.examId,
      questionId: row.questionId,
      domainId: row.domainId,
      topicId: row.topicId,
      difficulty: row.difficulty,
      sessionId: row.sessionId,
      sessionType: AttemptSessionType.values.firstWhere(
        (value) => value.name == row.sessionType,
        orElse: () => AttemptSessionType.practice,
      ),
      selectedAnswerId: row.selectedAnswerId,
      isCorrect: row.isCorrect,
      answeredAt: row.answeredAt.toUtc(),
    );
  }

  // ---- Question state ----

  @override
  Future<QuestionState> questionState(String examId, String questionId) async {
    final QuestionStateRow? row = await (_db.select(_db.questionStates)
          ..where(
              (t) => t.examId.equals(examId) & t.questionId.equals(questionId)))
        .getSingleOrNull();
    if (row == null) {
      return QuestionState.unseen(examId: examId, questionId: questionId);
    }
    return QuestionState(
      examId: row.examId,
      questionId: row.questionId,
      bookmarked: row.bookmarked,
      timesSeen: row.timesSeen,
      timesCorrect: row.timesCorrect,
      timesIncorrect: row.timesIncorrect,
      consecutiveCorrect: row.consecutiveCorrect,
      lastAnsweredAt: row.lastAnsweredAt?.toUtc(),
    );
  }

  @override
  Future<void> saveQuestionState(QuestionState state) async {
    await _db.into(_db.questionStates).insertOnConflictUpdate(
          QuestionStatesCompanion.insert(
            examId: state.examId,
            questionId: state.questionId,
            bookmarked: Value(state.bookmarked),
            timesSeen: Value(state.timesSeen),
            timesCorrect: Value(state.timesCorrect),
            timesIncorrect: Value(state.timesIncorrect),
            consecutiveCorrect: Value(state.consecutiveCorrect),
            lastAnsweredAt: Value(state.lastAnsweredAt?.toUtc()),
          ),
        );
  }

  @override
  Future<List<QuestionState>> questionStatesForExam(String examId) async {
    final rows = await (_db.select(_db.questionStates)
          ..where((t) => t.examId.equals(examId)))
        .get();
    return rows
        .map((row) => QuestionState(
              examId: row.examId,
              questionId: row.questionId,
              bookmarked: row.bookmarked,
              timesSeen: row.timesSeen,
              timesCorrect: row.timesCorrect,
              timesIncorrect: row.timesIncorrect,
              consecutiveCorrect: row.consecutiveCorrect,
              lastAnsweredAt: row.lastAnsweredAt?.toUtc(),
            ))
        .toList(growable: false);
  }

  // ---- Practice sessions ----

  @override
  Future<void> savePracticeSession(PracticeSession session) async {
    await _db.into(_db.practiceSessions).insertOnConflictUpdate(
          PracticeSessionsCompanion.insert(
            id: session.id,
            examId: session.examId,
            mode: session.mode.name,
            questionIdsJson: jsonEncode(session.questionIds),
            status: session.status.name,
            startedAt: session.startedAt.toUtc(),
            completedAt: Value(session.completedAt?.toUtc()),
          ),
        );
  }

  @override
  Future<PracticeSession?> inProgressPracticeSession(String examId) async {
    final PracticeSessionRow? row = await (_db.select(_db.practiceSessions)
          ..where((t) =>
              t.examId.equals(examId) &
              t.status.equals(SessionStatus.inProgress.name)))
        .getSingleOrNull();
    if (row == null) return null;
    return PracticeSession(
      id: row.id,
      examId: row.examId,
      mode: PracticeMode.values.firstWhere(
        (value) => value.name == row.mode,
        orElse: () => PracticeMode.quickPractice,
      ),
      questionIds: List<String>.from(jsonDecode(row.questionIdsJson) as List),
      status: SessionStatus.values.firstWhere(
        (value) => value.name == row.status,
        orElse: () => SessionStatus.inProgress,
      ),
      startedAt: row.startedAt.toUtc(),
      completedAt: row.completedAt?.toUtc(),
    );
  }

  // ---- Mock attempts ----

  @override
  Future<void> saveMockAttempt(MockAttempt attempt) async {
    await _db.into(_db.mockAttempts).insertOnConflictUpdate(
          MockAttemptsCompanion.insert(
            id: attempt.id,
            examId: attempt.examId,
            questionIdsJson: jsonEncode(attempt.questionIds),
            answersJson: jsonEncode(attempt.answers),
            flaggedQuestionIdsJson:
                jsonEncode(attempt.flaggedQuestionIds.toList()),
            status: attempt.status.name,
            startedAt: attempt.startedAt.toUtc(),
            durationMinutes: attempt.durationMinutes,
            currentQuestionIndex: Value(attempt.currentQuestionIndex),
            contentVersion: Value(attempt.contentVersion),
            completedAt: Value(attempt.completedAt?.toUtc()),
            correctCount: Value(attempt.correctCount),
          ),
        );
  }

  @override
  Future<MockAttempt?> mockAttempt(String attemptId) async {
    final MockAttemptRow? row = await (_db.select(_db.mockAttempts)
          ..where((t) => t.id.equals(attemptId)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mockAttemptToDomain(row);
  }

  @override
  Future<List<MockAttempt>> mockAttemptsForExam(String examId) async {
    final rows = await (_db.select(_db.mockAttempts)
          ..where((t) => t.examId.equals(examId)))
        .get();
    return rows.map(_mockAttemptToDomain).toList(growable: false);
  }

  MockAttempt _mockAttemptToDomain(MockAttemptRow row) {
    return MockAttempt(
      id: row.id,
      examId: row.examId,
      questionIds: List<String>.from(jsonDecode(row.questionIdsJson) as List),
      answers: Map<String, String>.from(
          jsonDecode(row.answersJson) as Map<String, Object?>),
      flaggedQuestionIds:
          Set<String>.from(jsonDecode(row.flaggedQuestionIdsJson) as List),
      status: MockAttemptStatus.values.firstWhere(
        (value) => value.name == row.status,
        orElse: () => MockAttemptStatus.inProgress,
      ),
      startedAt: row.startedAt.toUtc(),
      durationMinutes: row.durationMinutes,
      currentQuestionIndex: row.currentQuestionIndex,
      contentVersion: row.contentVersion,
      completedAt: row.completedAt?.toUtc(),
      correctCount: row.correctCount,
    );
  }

  // ---- Readiness snapshots (append-only) ----

  @override
  Future<void> saveReadinessSnapshot(ReadinessSnapshot snapshot) async {
    await _db.into(_db.readinessSnapshots).insert(
          ReadinessSnapshotsCompanion.insert(
            id: snapshot.id,
            examId: snapshot.examId,
            calculatedAt: snapshot.calculatedAt.toUtc(),
            overallScore: snapshot.overallScore,
            band: snapshot.band.name,
            recentAccuracyComponent: snapshot.recentAccuracyComponent,
            domainMasteryComponent: snapshot.domainMasteryComponent,
            mockPerformanceComponent: snapshot.mockPerformanceComponent,
            repeatedMasteryComponent: snapshot.repeatedMasteryComponent,
            coverageComponent: snapshot.coverageComponent,
            evidenceConfidence: snapshot.evidenceConfidence,
            uniqueQuestionsAnswered: snapshot.uniqueQuestionsAnswered,
          ),
        );
  }

  @override
  Future<ReadinessSnapshot?> latestReadinessSnapshot(String examId) async {
    final ReadinessSnapshotRow? row = await (_db.select(_db.readinessSnapshots)
          ..where((t) => t.examId.equals(examId))
          ..orderBy([(t) => OrderingTerm.desc(t.calculatedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _readinessToDomain(row);
  }

  @override
  Future<List<ReadinessSnapshot>> readinessSnapshotsForExam(
    String examId,
  ) async {
    final rows = await (_db.select(_db.readinessSnapshots)
          ..where((t) => t.examId.equals(examId)))
        .get();
    return rows.map(_readinessToDomain).toList(growable: false);
  }

  ReadinessSnapshot _readinessToDomain(ReadinessSnapshotRow row) {
    return ReadinessSnapshot(
      id: row.id,
      examId: row.examId,
      calculatedAt: row.calculatedAt.toUtc(),
      overallScore: row.overallScore,
      band: ReadinessBand.values.firstWhere(
        (value) => value.name == row.band,
        orElse: () => ReadinessBand.starting,
      ),
      recentAccuracyComponent: row.recentAccuracyComponent,
      domainMasteryComponent: row.domainMasteryComponent,
      mockPerformanceComponent: row.mockPerformanceComponent,
      repeatedMasteryComponent: row.repeatedMasteryComponent,
      coverageComponent: row.coverageComponent,
      evidenceConfidence: row.evidenceConfidence,
      uniqueQuestionsAnswered: row.uniqueQuestionsAnswered,
    );
  }
}
