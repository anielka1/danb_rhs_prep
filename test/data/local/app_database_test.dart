import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:danb_rhs_prep/data/local/app_database.dart';

void main() {
  group('fresh install', () {
    test('creates every table with no error', () async {
      final AppDatabase db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      // A trivial select against each table proves it was actually
      // created by onCreate, not just declared in Dart.
      expect(await db.select(db.answerAttempts).get(), isEmpty);
      expect(await db.select(db.questionStates).get(), isEmpty);
      expect(await db.select(db.practiceSessions).get(), isEmpty);
      expect(await db.select(db.mockAttempts).get(), isEmpty);
      expect(await db.select(db.readinessSnapshots).get(), isEmpty);
      expect(await db.select(db.userProfiles).get(), isEmpty);
    });

    test('schema version is 1, the first version', () async {
      final AppDatabase db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 1);
    });
  });

  group('restart durability', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('app_database_test');
      dbFile = File('${tempDir.path}/app.sqlite');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test(
        'a row written before "process exit" is still there after '
        'reopening the same file — simulating an app restart', () async {
      final AppDatabase first = AppDatabase.forTesting(NativeDatabase(dbFile));
      await first.into(first.answerAttempts).insert(
            AnswerAttemptsCompanion.insert(
              id: 'attempt-1',
              examId: 'danb-rhs',
              questionId: 'q1',
              domainId: 'domain-1',
              topicId: 'topic-1',
              difficulty: 2,
              sessionId: 'session-1',
              sessionType: 'practice',
              selectedAnswerId: 'a',
              isCorrect: true,
              answeredAt: DateTime.utc(2026, 1, 1),
            ),
          );
      // Closing (not just letting it go out of scope) is what a real
      // process-restart implies: the connection is really gone.
      await first.close();

      final AppDatabase reopened =
          AppDatabase.forTesting(NativeDatabase(dbFile));
      addTearDown(reopened.close);

      final rows = await reopened.select(reopened.answerAttempts).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'attempt-1');
      expect(rows.single.isCorrect, isTrue);
    });
  });

  group('corruption recovery', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('app_database_corruption');
      dbFile = File('${tempDir.path}/app.sqlite');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test(
        'a genuinely corrupt file is quarantined (not deleted) and a '
        'fresh, working database is opened in its place', () async {
      // Not a valid SQLite file at all (SQLITE_NOTADB) — the simplest,
      // most deterministic way to reproduce "this file's contents are
      // not a database" without needing to hand-craft a page that trips
      // SQLITE_CORRUPT specifically.
      dbFile.writeAsBytesSync(List.filled(4096, 0xFF));

      final Database recovered = openSqliteWithCorruptionRecovery(dbFile);
      addTearDown(recovered.dispose);

      // The recovered database is genuinely usable, not a dangling handle
      // to nothing.
      expect(
        () => recovered.execute('CREATE TABLE probe (id INTEGER PRIMARY KEY)'),
        returnsNormally,
      );

      final List<FileSystemEntity> siblings = tempDir.listSync();
      final bool quarantineFileExists = siblings.any(
        (entity) => entity.path.contains('.corrupt.'),
      );
      expect(quarantineFileExists, isTrue,
          reason: 'the original corrupt bytes must be preserved under a '
              '.corrupt.<timestamp> name, never silently discarded');

      // A fresh, empty database file exists at the original path — this
      // is what lets AppDatabase's LazyDatabase (and therefore a user's
      // "Try Again" tap after a bootstrap failure) succeed on retry
      // instead of hitting the exact same corruption again.
      expect(dbFile.existsSync(), isTrue);
    });

    test('a healthy, valid database is opened as-is, not quarantined', () {
      final Database seed = sqlite3.open(dbFile.path);
      seed.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)');
      seed.dispose();

      final Database opened = openSqliteWithCorruptionRecovery(dbFile);
      addTearDown(opened.dispose);

      final result = opened.select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='t'");
      expect(result, hasLength(1));

      final bool quarantineFileExists =
          tempDir.listSync().any((entity) => entity.path.contains('.corrupt.'));
      expect(quarantineFileExists, isFalse,
          reason: 'a healthy database must never be quarantined');
    });
  });

  group('migration safety net', () {
    test(
        'onUpgrade throws for any version jump, since no real migration '
        'exists yet — a future schema bump must add one deliberately, '
        'never fall through to a silent no-op', () async {
      final AppDatabase db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await expectLater(
        () => db.migration.onUpgrade(db.createMigrator(), 1, 2),
        throwsStateError,
      );
    });
  });
}
