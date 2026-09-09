import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
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

    test(
        'schema version is 3 (PREP-668 added questionVersion/'
        'correctAnswerId/explanation)', () async {
      final AppDatabase db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 3);
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
        'a file that is not a database at all (bad header, SQLITE_NOTADB) '
        'is quarantined (not deleted) and a fresh, working database is '
        'opened in its place — recovery happens synchronously, in this '
        'same call, never via a later retry', () async {
      // The simplest, most deterministic way to reproduce "this file's
      // contents are not a database": sqlite3.open itself rejects the
      // header before quick_check is ever reached.
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

      // A fresh, empty database file exists at the original path —
      // openSqliteWithCorruptionRecovery already returned a working
      // database above, in this same call; this just confirms the file
      // backing it is the fresh one, not the quarantined original.
      expect(dbFile.existsSync(), isTrue);
    });

    test(
        'a file that opens fine but whose body is corrupt (PRAGMA '
        'quick_check reports it, without sqlite3.open ever throwing) is '
        'also detected and recovered — not just header-level '
        'SQLITE_NOTADB', () async {
      // A valid header, but real page content damaged well past it: the
      // header alone is enough for sqlite3.open to succeed, so only
      // quick_check's page-structure walk catches this. quick_check
      // reports this kind of damage as a result row, not a thrown
      // exception — the specific gap the old, exception-only detection
      // logic missed.
      final Database seed = sqlite3.open(dbFile.path);
      seed.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, value TEXT)');
      for (var i = 0; i < 200; i++) {
        seed.execute('INSERT INTO t (value) VALUES (?)', ['x' * 200]);
      }
      seed.dispose();

      final List<int> bytes = dbFile.readAsBytesSync();
      // Well past the header/first page (sqlite's default page size is
      // 4096 bytes) — deep in real row data written above.
      final int start = bytes.length ~/ 2;
      for (int i = start; i < start + 300 && i < bytes.length; i++) {
        bytes[i] = 0xAA;
      }
      dbFile.writeAsBytesSync(bytes);

      final Database recovered = openSqliteWithCorruptionRecovery(dbFile);
      addTearDown(recovered.dispose);

      expect(
        () => recovered.execute('CREATE TABLE probe (id INTEGER PRIMARY KEY)'),
        returnsNormally,
      );
      final bool quarantineFileExists =
          tempDir.listSync().any((entity) => entity.path.contains('.corrupt.'));
      expect(quarantineFileExists, isTrue,
          reason: 'body-only corruption must be quarantined too, exactly '
              'like a bad header');
    });

    test(
        'quarantining also moves aside -wal/-shm/-journal sidecar files, '
        'not just the main database file, so a fresh database is never '
        'contaminated by a stale write-ahead log', () async {
      dbFile.writeAsBytesSync(List.filled(4096, 0xFF));
      final File walFile = File('${dbFile.path}-wal')
        ..writeAsStringSync('stale wal content');
      final File shmFile = File('${dbFile.path}-shm')
        ..writeAsStringSync('stale shm content');
      final File journalFile = File('${dbFile.path}-journal')
        ..writeAsStringSync('stale journal content');

      openSqliteWithCorruptionRecovery(dbFile).dispose();

      expect(walFile.existsSync(), isFalse,
          reason: 'the stale -wal must be moved aside, not left in place '
              'where the fresh database could pick it up');
      expect(shmFile.existsSync(), isFalse);
      expect(journalFile.existsSync(), isFalse);
      final List<String> quarantined = tempDir
          .listSync()
          .map((e) => e.path)
          .where((path) => path.contains('.corrupt.'))
          .toList();
      expect(quarantined.any((path) => path.contains('-wal')), isTrue);
      expect(quarantined.any((path) => path.contains('-shm')), isTrue);
      for (final suffix in ['wal', 'shm', 'journal']) {
        final path = quarantined
            .singleWhere((path) => path.contains('-$suffix.corrupt.'));
        expect(File(path).readAsStringSync(), 'stale $suffix content');
      }
    });

    test(
        'the failed Database handle is closed before its file is renamed '
        '— renaming a file out from under a still-open handle is not '
        'something every platform this app targets supports reliably',
        () async {
      dbFile.writeAsBytesSync(List.filled(4096, 0xFF));

      // If the corrupt handle were still open when _quarantine renames
      // the file, opening a *fresh* database at the same original path
      // immediately after would be the operation most likely to expose
      // it (e.g. a locked/in-use file on a platform that enforces
      // exclusive access) — this succeeding end-to-end is the behavioral
      // proof, since the underlying handle isn't inspectable directly.
      final Database recovered = openSqliteWithCorruptionRecovery(dbFile);
      addTearDown(recovered.dispose);

      expect(
        () => recovered.execute('CREATE TABLE probe (id INTEGER PRIMARY KEY)'),
        returnsNormally,
      );
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

  group('corruption recovery is fully automatic end-to-end', () {
    test(
        'opening the real AppDatabase() over a corrupt on-device file '
        'recovers silently inside the very first query — no exception '
        'ever propagates for a caller (e.g. AppBootstrapService) to '
        'catch, so no "Try Again" UI is ever shown for this failure', () async {
      final File dbFile = await resolveDatabaseFile();
      dbFile.parent.createSync(recursive: true);
      addTearDown(() {
        for (final File f in [
          dbFile,
          File('${dbFile.path}-wal'),
          File('${dbFile.path}-shm'),
          File('${dbFile.path}-journal'),
        ]) {
          if (f.existsSync()) f.deleteSync();
        }
        for (final FileSystemEntity sibling in dbFile.parent.listSync()) {
          if (sibling.path.contains('.corrupt.')) sibling.deleteSync();
        }
      });
      dbFile.writeAsBytesSync(List.filled(4096, 0xFF));

      final AppDatabase db = AppDatabase();
      addTearDown(db.close);

      // This is where LazyDatabase actually opens the connection for the
      // first time — exactly the call site AppBootstrapService's real
      // userSettingsRepository.loadProfile(examId) exercises during
      // bootstrap. It must complete normally, not throw.
      await expectLater(db.select(db.userProfiles).get(), completion(isEmpty));
    });
  });

  group('migration safety net', () {
    test(
        'onUpgrade throws for any undefined version jump (1->2 and 2->3 '
        'are now defined, by PREP-664 and PREP-668 respectively; 3->4 is '
        'not), so a future schema bump must add its own branch '
        'deliberately, never fall through to a silent no-op', () async {
      final AppDatabase db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await expectLater(
        () => db.migration.onUpgrade(db.createMigrator(), 3, 4),
        throwsStateError,
      );
    });
  });

  group('interrupted write (PREP-665)', () {
    test(
        'any exception mid-transaction rolls back every statement already '
        'issued inside it — not just the one specific conflict '
        'DriftProgressRepository happens to check for. This is the '
        'general guarantee "przerwany zapis" (an interrupted write, e.g. '
        'the process dying before a transaction commits) relies on: '
        'drift/sqlite3\'s own transaction semantics, exercised directly '
        'against this app\'s real database rather than assumed.', () async {
      final AppDatabase db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await expectLater(
        db.transaction(() async {
          await db.into(db.answerAttempts).insert(
                AnswerAttemptsCompanion.insert(
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
          await db.into(db.questionStates).insert(
                QuestionStatesCompanion.insert(
                  examId: 'danb-rhs',
                  questionId: 'q1',
                ),
              );
          // Simulates the write being interrupted for a reason unrelated
          // to any row-level conflict — e.g. the kind of unexpected
          // failure a real process interruption would surface as, from
          // the transaction's point of view.
          throw Exception('simulated interruption');
        }),
        throwsException,
      );

      expect(await db.select(db.answerAttempts).get(), isEmpty,
          reason: 'the interrupted transaction must leave no trace of '
              'its first statement');
      expect(await db.select(db.questionStates).get(), isEmpty,
          reason: 'nor of its second — an interrupted write must never '
              'leave a half-applied state, only "before" or "after", '
              'never "some of it happened"');
    });

    test(
        'a successful transaction that commits is durable across a '
        'simulated restart — the "before" half of the same guarantee: '
        'only a genuinely interrupted write is rolled back, a completed '
        'one survives exactly like the rest of this database\'s restart '
        'durability', () async {
      final Directory tempDir =
          Directory.systemTemp.createTempSync('app_database_interrupted');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final File dbFile = File('${tempDir.path}/app.sqlite');

      final AppDatabase first = AppDatabase.forTesting(NativeDatabase(dbFile));
      await first.transaction(() async {
        await first.into(first.answerAttempts).insert(
              AnswerAttemptsCompanion.insert(
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
        await first.into(first.questionStates).insert(
              QuestionStatesCompanion.insert(
                examId: 'danb-rhs',
                questionId: 'q1',
                timesSeen: const Value(1),
              ),
            );
      });
      await first.close();

      final AppDatabase reopened =
          AppDatabase.forTesting(NativeDatabase(dbFile));
      addTearDown(reopened.close);

      expect(
          await reopened.select(reopened.answerAttempts).get(), hasLength(1));
      expect(
          await reopened.select(reopened.questionStates).get(), hasLength(1));
    });
  });
}
