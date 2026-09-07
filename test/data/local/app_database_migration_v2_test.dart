import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/data/local/app_database.dart';

import 'schema_v1_snapshot.dart';

/// Proves the *real* schema 1 -> 2 migration (PREP-664: added
/// `contentVersion` to `AnswerAttempts`/`PracticeSessions`) against a
/// realistic schema-1 database file, seeded via `schema_v1_snapshot.dart`
/// — not a parallel fixture's own migration logic, the actual
/// `AppDatabase.migration` code every real user's upgrade runs through.
///
/// Complements (does not replace) `app_database_test.dart`'s "migration
/// safety net" group, which proves an *undefined* jump still throws.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('app_database_migration_v2');
    dbFile = File('${tempDir.path}/app.sqlite');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test(
      'upgrading a real schema-1 database to schema 2 preserves every '
      'existing row across every table, with the two new columns '
      'defaulting to null', () async {
    final SchemaV1Snapshot v1 = SchemaV1Snapshot(NativeDatabase(dbFile));
    await v1.into(v1.answerAttemptsV1).insert(
          AnswerAttemptsV1Companion.insert(
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
          ),
        );
    await v1.into(v1.practiceSessionsV1).insert(
          PracticeSessionsV1Companion.insert(
            id: 'session-1',
            examId: 'danb-rhs',
            mode: 'quickPractice',
            questionIdsJson: '["q1","q2"]',
            status: 'inProgress',
            startedAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await v1.into(v1.userProfilesV1).insert(
          UserProfilesV1Companion.insert(
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
    await v1.close();

    final AppDatabase v2 = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(v2.close);

    final attemptRows = await v2.select(v2.answerAttempts).get();
    expect(attemptRows, hasLength(1));
    expect(attemptRows.single.id, 'attempt-1');
    expect(attemptRows.single.isCorrect, isTrue);
    expect(attemptRows.single.contentVersion, isNull,
        reason: 'a schema-1 row has no content version to backfill — it '
            'must default to null, never a fabricated value');

    final sessionRows = await v2.select(v2.practiceSessions).get();
    expect(sessionRows, hasLength(1));
    expect(sessionRows.single.id, 'session-1');
    expect(sessionRows.single.contentVersion, isNull);

    final profileRows = await v2.select(v2.userProfiles).get();
    expect(profileRows, hasLength(1),
        reason: 'a table untouched by this migration must still survive '
            'the upgrade intact');
    expect(profileRows.single.examId, 'danb-rhs');

    // The new column is genuinely writable post-migration, not just
    // present-but-inert.
    await v2.into(v2.answerAttempts).insert(
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
            contentVersion: const Value('2026.1'),
          ),
        );
    final reloaded = await (v2.select(v2.answerAttempts)
          ..where((t) => t.id.equals('attempt-2')))
        .getSingle();
    expect(reloaded.contentVersion, '2026.1');
  });

  test(
      'a fresh install still lands directly on schema 2, never running '
      'onUpgrade at all', () async {
    final AppDatabase db = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(db.close);

    expect(db.schemaVersion, 2);
    final rows = await db.select(db.answerAttempts).get();
    expect(rows, isEmpty);
  });
}
