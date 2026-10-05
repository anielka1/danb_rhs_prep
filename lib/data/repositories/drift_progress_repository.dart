import '../../domain/models/answer_order.dart';
import '../../domain/models/study_schedule.dart';
import '../../domain/repositories/study_schedule_repository.dart';
import '../../domain/repositories/progress_reset_repository.dart';
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
/// enum is stored by its stable `.name`. [recordAnswerAttempt] is genuinely
/// idempotent (PREP-664) — see that method's own doc comment — never a
/// plain `INSERT` that fails on any id collision regardless of content.
class DriftProgressRepository
    implements
        ProgressRepository,
        ProgressResetRepository,
        StudyScheduleRepository {
  DriftProgressRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> resetProgressForExam(String examId) {
    if (examId.trim().isEmpty) throw ArgumentError.value(examId, 'examId');
    return _db.transaction(() async {
      await (_db.delete(_db.studySchedules)
            ..where((t) => t.examId.equals(examId)))
          .go();
      await (_db.delete(_db.answerAttempts)
            ..where((t) => t.examId.equals(examId)))
          .go();
      await (_db.delete(_db.questionStates)
            ..where((t) => t.examId.equals(examId)))
          .go();
      await (_db.delete(_db.practiceSessions)
            ..where((t) => t.examId.equals(examId)))
          .go();
      await (_db.delete(_db.mockAttempts)
            ..where((t) => t.examId.equals(examId)))
          .go();
      await (_db.delete(_db.readinessSnapshots)
            ..where((t) => t.examId.equals(examId)))
          .go();
    });
  }

  // ---- Answer attempts (append-only) ----

  @override
  Future<void> recordAnswerAttempt(AnswerAttempt attempt) {
    // Canonicalized once, up front — see canonicalizeAnswerAttempt's doc
    // comment for why: Drift's DateTimeColumn storage silently truncates
    // answeredAt to whole seconds, so comparing an existing (already
    // truncated) row against a caller's still-millisecond/microsecond-
    // precise attempt would misjudge a genuine resubmission as a
    // conflicting different one. `canonical.answeredAt` is already UTC.
    final AnswerAttempt canonical = canonicalizeAnswerAttempt(attempt);
    return _db.transaction(() async {
      final AnswerAttemptRow? existingRow =
          await (_db.select(_db.answerAttempts)
                ..where((t) => t.id.equals(canonical.id)))
              .getSingleOrNull();

      if (existingRow != null) {
        if (_attemptToDomain(existingRow) == canonical) {
          // Genuinely idempotent: re-recording the exact same attempt
          // (same id, same everything else) is a safe no-op — not an
          // error, and critically, does NOT re-run the question-state
          // update below, which already applied the first time this id
          // was recorded. A caller (or a future retry/sync path) that
          // isn't sure whether an earlier call actually completed can
          // safely call this again with the identical attempt.
          return;
        }
        // Same id, different content: never silently overwrite a
        // different attempt's history — this is corruption, not a retry,
        // and must fail loudly.
        throw StateError(
          'An answer attempt with id "${canonical.id}" already exists '
          'with different content.',
        );
      }

      await _db.into(_db.answerAttempts).insert(
            AnswerAttemptsCompanion.insert(
              id: canonical.id,
              examId: canonical.examId,
              questionId: canonical.questionId,
              domainId: canonical.domainId,
              topicId: canonical.topicId,
              difficulty: canonical.difficulty,
              sessionId: canonical.sessionId,
              sessionType: canonical.sessionType.name,
              selectedAnswerId: canonical.selectedAnswerId,
              isCorrect: canonical.isCorrect,
              answeredAt: canonical.answeredAt,
              contentVersion: Value(canonical.contentVersion),
              questionVersion: Value(canonical.questionVersion),
              correctAnswerId: Value(canonical.correctAnswerId),
              explanation: Value(canonical.explanation),
              confident: Value(canonical.confident),
              activeDurationSeconds: Value(canonical.activeDurationSeconds),
              localAnsweredDate: Value(canonical.localAnsweredDate),
            ),
          );
      // Reuses questionState/saveQuestionState below rather than
      // duplicating their row<->domain mapping — Drift routes queries
      // made on `_db` during a `transaction()` callback through that same
      // transaction automatically, so this participates in the one above,
      // not a separate implicit one of its own. If the insert above had
      // failed, execution would never reach here at all.
      final QuestionState prior =
          await questionState(canonical.examId, canonical.questionId);
      await saveQuestionState(prior.withAttempt(
        isCorrect: canonical.isCorrect,
        answeredAt: canonical.answeredAt,
      ));
    });
  }

  @override
  Future<List<AnswerAttempt>> answerAttemptsForExam(String examId) async {
    // Ordered explicitly by SQLite's own `rowid` (PREP-665) to satisfy
    // this interface method's own "recorded order" contract — NOT by
    // `answeredAt`: two attempts can carry the identical `answeredAt`
    // (storage truncates it to whole seconds — see
    // canonicalizeAnswerAttempt), so ordering by that column alone
    // cannot break the tie, and would leave the actual order
    // implementation-defined for tied rows. `rowid` is the one value an
    // ordinary (not `WITHOUT ROWID`) SQLite table genuinely assigns in
    // insertion order, which is why this reaches for raw SQL: drift's
    // typed query builder has no way to reference that implicit column.
    //
    // This is only a true insertion-order guarantee as long as two
    // things hold — both true today, and load-bearing for it:
    // * this table is genuinely append-only (see [AnswerAttempts]'s own
    //   doc comment) — nothing ever updates or re-inserts a row, which
    //   would assign it a new rowid unrelated to when it was first
    //   recorded;
    // * this database is never `VACUUM`ed — a `VACUUM` rebuilds the
    //   table and reassigns every rowid in whatever order the vacuum
    //   visits rows, severing rowid from insertion order entirely.
    //   Nothing in this codebase runs `VACUUM` today. If that ever
    //   changes, this guarantee — and `PracticeSessionController.resume`'s
    //   reliance on it to find each question's *latest* attempt in a
    //   session — would need a real, persisted sequence column instead,
    //   added via its own migration.
    final String table = _db.answerAttempts.actualTableName;
    final String examIdColumn = _db.answerAttempts.examId.name;
    final List<QueryRow> rows = await _db.customSelect(
      'SELECT * FROM $table WHERE $examIdColumn = ? ORDER BY rowid ASC',
      variables: [Variable<String>(examId)],
      readsFrom: {_db.answerAttempts},
    ).get();
    return rows
        .map((row) => _attemptToDomain(_db.answerAttempts.map(row.data)))
        .toList(growable: false);
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
      contentVersion: row.contentVersion,
      questionVersion: row.questionVersion,
      correctAnswerId: row.correctAnswerId,
      explanation: row.explanation,
      confident: row.confident,
      activeDurationSeconds: row.activeDurationSeconds,
      localAnsweredDate: row.localAnsweredDate,
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
            planDate: Value(session.planDate),
            reviewQuestionIdsJson: Value(jsonEncode(session.reviewQuestionIds)),
            questionIdsJson: jsonEncode(session.questionIds),
            answerOrderJson: Value(session.answerOrder == null
                ? null
                : jsonEncode(session.answerOrder)),
            status: session.status.name,
            startedAt: session.startedAt.toUtc(),
            completedAt: Value(session.completedAt?.toUtc()),
            contentVersion: Value(session.contentVersion),
          ),
        );
  }

  @override
  Future<PracticeSession?> inProgressPracticeSession(String examId) async {
    final PracticeSessionRow? row = await (_db.select(_db.practiceSessions)
          ..where((t) =>
              t.examId.equals(examId) &
              t.status.equals(SessionStatus.inProgress.name))
          ..orderBy([
            (t) => OrderingTerm.desc(t.startedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return _sessionToDomain(row);
  }

  PracticeSession _sessionToDomain(PracticeSessionRow row) => PracticeSession(
        id: row.id,
        examId: row.examId,
        mode: PracticeMode.values.firstWhere(
          (value) => value.name == row.mode,
          orElse: () => PracticeMode.quickPractice,
        ),
        planDate: row.planDate,
        reviewQuestionIds: row.reviewQuestionIdsJson == null
            ? const []
            : List<String>.from(jsonDecode(row.reviewQuestionIdsJson!) as List),
        questionIds: List<String>.from(jsonDecode(row.questionIdsJson) as List),
        answerOrder: AnswerOrder.decode(row.answerOrderJson == null
            ? null
            : jsonDecode(row.answerOrderJson!)),
        status: SessionStatus.values.firstWhere(
          (value) => value.name == row.status,
          orElse: () => SessionStatus.inProgress,
        ),
        startedAt: row.startedAt.toUtc(),
        completedAt: row.completedAt?.toUtc(),
        contentVersion: row.contentVersion,
      );

  @override
  Future<List<PracticeSession>> practiceSessionsForExam(String examId) async =>
      (await (_db.select(_db.practiceSessions)
                ..where((t) => t.examId.equals(examId)))
              .get())
          .map(_sessionToDomain)
          .toList();

  @override
  Future<List<StudyScheduleEntry>> studySchedule(String examId) async =>
      (await (_db.select(_db.studySchedules)
                ..where((t) => t.examId.equals(examId)))
              .get())
          .map((r) => StudyScheduleEntry(
              examId: r.examId,
              date: r.date,
              kind: r.kind,
              minutes: r.minutes,
              reservedQuestionIds: List<String>.from(
                  jsonDecode(r.reservedQuestionIdsJson) as List)))
          .toList();

  @override
  Future<void> saveStudySchedule(
          String examId, List<StudyScheduleEntry> entries) =>
      _db.transaction(() async {
        if (entries.any((e) => e.examId != examId)) {
          throw ArgumentError('Wrong exam');
        }
        await (_db.delete(_db.studySchedules)
              ..where((t) => t.examId.equals(examId)))
            .go();
        for (final e in entries) {
          await _db.into(_db.studySchedules).insert(
              StudySchedulesCompanion.insert(
                  examId: e.examId,
                  date: e.date,
                  kind: e.kind,
                  minutes: Value(e.minutes),
                  reservedQuestionIdsJson: jsonEncode(e.reservedQuestionIds)));
        }
      });

  // ---- Mock attempts ----

  @override
  Future<void> saveMockAttempt(MockAttempt attempt) async {
    await _db.into(_db.mockAttempts).insertOnConflictUpdate(
          MockAttemptsCompanion.insert(
            id: attempt.id,
            examId: attempt.examId,
            questionIdsJson: jsonEncode(attempt.questionIds),
            answerOrderJson: Value(attempt.answerOrder == null
                ? null
                : jsonEncode(attempt.answerOrder)),
            answersJson: jsonEncode(attempt.answers),
            flaggedQuestionIdsJson:
                jsonEncode(attempt.flaggedQuestionIds.toList()),
            status: attempt.status.name,
            startedAt: attempt.startedAt.toUtc(),
            durationMinutes: attempt.durationMinutes,
            seenBeforeStartCount: Value(attempt.seenBeforeStartCount),
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
      answerOrder: AnswerOrder.decode(row.answerOrderJson == null
          ? null
          : jsonDecode(row.answerOrderJson!)),
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
      seenBeforeStartCount: row.seenBeforeStartCount,
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
