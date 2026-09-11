import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/data/local/app_database.dart';

import 'schema_v2_snapshot.dart';

/// Proves the *real* schema 2 -> 3 migration (PREP-668: added
/// `questionVersion`/`correctAnswerId`/`explanation` to `AnswerAttempts`,
/// so `PracticeSessionController.resume` can rebuild the exact
/// `AnswerFeedback` an attempt was originally evaluated against, instead
/// of reconstructing it from whatever `Question` content happens to be
/// loaded when the app is reopened) against a realistic schema-2
/// database file, seeded via `schema_v2_snapshot.dart` — not a parallel
/// fixture's own migration logic, the actual `AppDatabase.migration`
/// code every real user's upgrade runs through.
///
/// Complements (does not replace) `app_database_test.dart`'s "migration
/// safety net" group, which proves an *undefined* jump still throws.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('app_database_migration_v3');
    dbFile = File('${tempDir.path}/app.sqlite');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test(
      'upgrading a real schema-2 database to schema 3 preserves every '
      'existing row across every table, with the three new columns '
      'defaulting to null', () async {
    final SchemaV2Snapshot v2 = SchemaV2Snapshot(NativeDatabase(dbFile));
    await v2.into(v2.answerAttemptsV2).insert(
          AnswerAttemptsV2Companion.insert(
            id: 'attempt-1',
            examId: 'danb-rhs',
            questionId: 'q1',
            domainId: 'radiation-protection',
            topicId: 'shielding',
            difficulty: 2,
            sessionId: 'session-1',
            sessionType: 'practice',
            selectedAnswerId: 'a1',
            isCorrect: true,
            answeredAt: DateTime.utc(2026, 1, 1),
            contentVersion: const Value('2026.1'),
          ),
        );
    await v2.into(v2.practiceSessionsV2).insert(
          PracticeSessionsV2Companion.insert(
            id: 'session-1',
            examId: 'danb-rhs',
            mode: 'quickPractice',
            questionIdsJson: '["q1","q2"]',
            status: 'inProgress',
            startedAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await v2.into(v2.userProfilesV2).insert(
          UserProfilesV2Companion.insert(
            examId: 'danb-rhs',
            experienceLevel: 'justStarting',
            examDatePrecision: 'notScheduled',
            dailyGoalQuestions: 10,
            notificationsEnabled: false,
            themePreference: 'system',
            onboardingComplete: true,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await v2.into(v2.questionStatesV2).insert(
          QuestionStatesV2Companion.insert(
            examId: 'danb-rhs',
            questionId: 'q1',
            timesSeen: const Value(3),
            timesCorrect: const Value(2),
            timesIncorrect: const Value(1),
          ),
        );
    await v2.into(v2.mockAttemptsV2).insert(
          MockAttemptsV2Companion.insert(
            id: 'mock-1',
            examId: 'danb-rhs',
            questionIdsJson: '["q1","q2"]',
            answersJson: '{"q1":"a1"}',
            flaggedQuestionIdsJson: '[]',
            status: 'inProgress',
            startedAt: DateTime.utc(2026, 1, 1),
            durationMinutes: 90,
          ),
        );
    await v2.into(v2.readinessSnapshotsV2).insert(
          ReadinessSnapshotsV2Companion.insert(
            id: 'readiness-1',
            examId: 'danb-rhs',
            calculatedAt: DateTime.utc(2026, 1, 1),
            overallScore: 42.0,
            band: 'developing',
            recentAccuracyComponent: 0.5,
            domainMasteryComponent: 0.5,
            mockPerformanceComponent: 0.5,
            repeatedMasteryComponent: 0.5,
            coverageComponent: 0.5,
            evidenceConfidence: 0.5,
            uniqueQuestionsAnswered: 5,
          ),
        );
    await v2.close();

    final AppDatabase v3 = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(v3.close);

    final attemptRows = await v3.select(v3.answerAttempts).get();
    expect(attemptRows, hasLength(1));
    expect(attemptRows.single.id, 'attempt-1');
    expect(attemptRows.single.isCorrect, isTrue);
    expect(attemptRows.single.contentVersion, '2026.1',
        reason: 'a pre-existing schema-2 column must survive untouched');
    expect(attemptRows.single.questionVersion, isNull,
        reason: 'a schema-2 row has no question-version snapshot to '
            'backfill — it must default to null, never a fabricated '
            'value that could be mistaken for a genuine historical '
            'snapshot');
    expect(attemptRows.single.correctAnswerId, isNull);
    expect(attemptRows.single.explanation, isNull);

    final sessionRows = await v3.select(v3.practiceSessions).get();
    expect(sessionRows, hasLength(1));
    expect(sessionRows.single.id, 'session-1');

    final profileRows = await v3.select(v3.userProfiles).get();
    expect(profileRows, hasLength(1),
        reason: 'a table untouched by this migration must still survive '
            'the upgrade intact');
    expect(profileRows.single.examId, 'danb-rhs');

    // The three remaining tables this migration doesn't touch at all —
    // proven with real seeded rows, not asserted by name alone.
    final questionStateRows = await v3.select(v3.questionStates).get();
    expect(questionStateRows, hasLength(1));
    expect(questionStateRows.single.timesSeen, 3);

    final mockAttemptRows = await v3.select(v3.mockAttempts).get();
    expect(mockAttemptRows, hasLength(1));
    expect(mockAttemptRows.single.id, 'mock-1');

    final readinessRows = await v3.select(v3.readinessSnapshots).get();
    expect(readinessRows, hasLength(1));
    expect(readinessRows.single.id, 'readiness-1');

    // The three new columns are genuinely writable post-migration, not
    // just present-but-inert.
    await v3.into(v3.answerAttempts).insert(
          AnswerAttemptsCompanion.insert(
            id: 'attempt-2',
            examId: 'danb-rhs',
            questionId: 'q2',
            domainId: 'radiation-protection',
            topicId: 'shielding',
            difficulty: 2,
            sessionId: 'session-1',
            sessionType: 'practice',
            selectedAnswerId: 'a2',
            isCorrect: false,
            answeredAt: DateTime.utc(2026, 1, 2),
            questionVersion: const Value(3),
            correctAnswerId: const Value('a1'),
            explanation: const Value('Because reasons.'),
          ),
        );
    final reloaded = await (v3.select(v3.answerAttempts)
          ..where((t) => t.id.equals('attempt-2')))
        .getSingle();
    expect(reloaded.questionVersion, 3);
    expect(reloaded.correctAnswerId, 'a1');
    expect(reloaded.explanation, 'Because reasons.');
  });

  test(
      'a fresh install still lands directly on schema 3, never running '
      'onUpgrade at all', () async {
    final AppDatabase db = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(db.close);

    expect(db.schemaVersion, 5);
    final rows = await db.select(db.answerAttempts).get();
    expect(rows, isEmpty);
  });
}
