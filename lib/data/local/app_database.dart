import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

part 'app_database.g.dart';

/// A single, append-only record of a user answering one question. Mirrors
/// [AnswerAttempt][] — see that class for field meaning; this table only
/// adds the storage shape (a `TEXT` primary key so an accidental
/// duplicate insert with the same id fails loudly instead of silently
/// overwriting a prior attempt).
///
/// [AnswerAttempt]: ../../domain/models/answer_attempt.dart
@DataClassName('AnswerAttemptRow')
class AnswerAttempts extends Table {
  TextColumn get id => text()();
  TextColumn get examId => text()();
  TextColumn get questionId => text()();
  TextColumn get domainId => text()();
  TextColumn get topicId => text()();
  IntColumn get difficulty => integer()();
  TextColumn get sessionId => text()();
  TextColumn get sessionType => text()();
  TextColumn get selectedAnswerId => text()();
  BoolColumn get isCorrect => boolean()();

  /// Always UTC — see `AppDatabase`'s doc comment for how that's enforced
  /// uniformly across every `DateTimeColumn` in this database.
  DateTimeColumn get answeredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Aggregated, per-question progress. Mirrors [QuestionState][] —
/// composite-keyed by (examId, questionId), matching that class's own
/// identity.
///
/// [QuestionState]: ../../domain/models/question_state.dart
@DataClassName('QuestionStateRow')
class QuestionStates extends Table {
  TextColumn get examId => text()();
  TextColumn get questionId => text()();
  BoolColumn get bookmarked => boolean().withDefault(const Constant(false))();
  IntColumn get timesSeen => integer().withDefault(const Constant(0))();
  IntColumn get timesCorrect => integer().withDefault(const Constant(0))();
  IntColumn get timesIncorrect => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveCorrect =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAnsweredAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {examId, questionId};
}

/// One practice (including diagnostic) session. Mirrors [PracticeSession][].
/// [questionIds] is stored as a JSON-encoded array: it's read/written as a
/// whole (never queried column-by-column), so a normalized child table
/// would add join complexity this app has no present use for.
///
/// [PracticeSession]: ../../domain/models/practice_session.dart
@DataClassName('PracticeSessionRow')
class PracticeSessions extends Table {
  TextColumn get id => text()();
  TextColumn get examId => text()();
  TextColumn get mode => text()();
  TextColumn get questionIdsJson => text()();
  TextColumn get status => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One mock exam attempt. Mirrors [MockAttempt][]. [questionIdsJson]/
/// [answersJson]/[flaggedQuestionIdsJson] are JSON-encoded, for the same
/// reason as `PracticeSessions.questionIdsJson` above.
///
/// [MockAttempt]: ../../domain/models/mock_attempt.dart
@DataClassName('MockAttemptRow')
class MockAttempts extends Table {
  TextColumn get id => text()();
  TextColumn get examId => text()();
  TextColumn get questionIdsJson => text()();
  TextColumn get answersJson => text()();
  TextColumn get flaggedQuestionIdsJson => text()();
  TextColumn get status => text()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get durationMinutes => integer()();
  IntColumn get currentQuestionIndex =>
      integer().withDefault(const Constant(0))();
  TextColumn get contentVersion => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get correctCount => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One calculated readiness result. Mirrors [ReadinessSnapshot][].
///
/// [ReadinessSnapshot]: ../../domain/models/readiness_snapshot.dart
@DataClassName('ReadinessSnapshotRow')
class ReadinessSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get examId => text()();
  DateTimeColumn get calculatedAt => dateTime()();
  RealColumn get overallScore => real()();
  TextColumn get band => text()();
  RealColumn get recentAccuracyComponent => real()();
  RealColumn get domainMasteryComponent => real()();
  RealColumn get mockPerformanceComponent => real()();
  RealColumn get repeatedMasteryComponent => real()();
  RealColumn get coverageComponent => real()();
  RealColumn get evidenceConfidence => real()();
  IntColumn get uniqueQuestionsAnswered => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local onboarding, study, and preference state for one exam. Mirrors
/// [UserProfile][] — one row per exam id, matching
/// `UserSettingsRepository.loadProfile(examId)`.
///
/// [UserProfile]: ../../domain/models/user_profile.dart
@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  TextColumn get examId => text()();
  TextColumn get experienceLevel => text()();
  TextColumn get examDatePrecision => text()();
  DateTimeColumn get examDate => dateTime().nullable()();
  IntColumn get dailyGoalQuestions => integer()();
  BoolColumn get notificationsEnabled => boolean()();
  TextColumn get themePreference => text()();
  BoolColumn get onboardingComplete => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {examId};
}

/// This app's one local database (PREP-661): every table above, versioned
/// from schema 1, opened independently of any network connection, with a
/// controlled recovery path for both migration and file-level corruption
/// failures.
///
/// **UTC timestamps**: every `DateTimeColumn` is declared with
/// `.withDefault`-free `dateTime()` and drift's default
/// `DateTimeAsTextOption`-free (epoch-based) storage; the *discipline* that
/// keeps every stored value UTC lives in the repository layer
/// (`DriftProgressRepository`/`DriftUserSettingsRepository`), which never
/// writes a `DateTime` without calling `.toUtc()` first and never reads
/// one back without re-asserting `.toUtc()` — belt-and-braces against a
/// caller ever passing local time in, since a raw epoch-millis column
/// itself can't enforce that on its own.
///
/// **Stable UUIDs**: `AnswerAttempts`/`MockAttempts`/`ReadinessSnapshots`
/// declare `id` as their primary key precisely so a caller-supplied,
/// non-unique id (e.g. a duplicate) fails the insert loudly instead of
/// silently overwriting history — see `IdGenerator`'s own doc comment for
/// the id-collision bug this replaced.
///
/// **Offline-independent**: opening this database is pure local file I/O
/// (`path_provider` + `sqlite3`) — nothing here ever awaits a network
/// call, directly or transitively.
///
/// **Controlled recovery path**: [_openConnection] never lets a fresh
/// install, a normal reopen, or a genuinely corrupt database file crash
/// the app. Corruption specifically is recovered from *automatically and
/// silently* — see [openSqliteWithCorruptionRecovery]'s own doc comment —
/// so it never reaches `AppBootstrapService`'s error path or
/// `SplashScreen`'s "Try Again" UI at all; that UI only ever appears for a
/// genuinely different failure (an undefined [migration] step, a disk
/// that's actually full or unwritable, or corruption recovery itself
/// failing to complete).
@DriftDatabase(tables: [
  AnswerAttempts,
  QuestionStates,
  PracticeSessions,
  MockAttempts,
  ReadinessSnapshots,
  UserProfiles,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For tests only: an isolated database over an arbitrary
  /// [QueryExecutor] (typically [NativeDatabase.memory] or a temp-file
  /// [NativeDatabase]), so tests never touch this app's real on-device
  /// database file.
  // ignore: use_super_parameters
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  /// Schema version 1 — the first version. Bumping this requires adding a
  /// matching branch to [migration]'s `onUpgrade` (see its doc comment)
  /// and a test proving the upgrade preserves existing rows; see
  /// `test/data/local/app_database_migration_test.dart`.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) => m.createAll(),
      // No schema version beyond 1 exists yet, so there is intentionally
      // no upgrade branch to write today. This still throws (rather than
      // being a silent no-op) so that the day a future schema bump adds
      // schemaVersion 2 without also adding its migration step here, that
      // mistake fails loudly during the upgrade itself — never a
      // half-migrated database masquerading as a successful one. Adding a
      // real migration: `if (from == 1 && to == 2) { await m.addColumn(...); }`
      // (or `m.createTable(...)`/`m.alterTable(...)` as needed), and a
      // test that seeds a v1 database, opens it as v2, and asserts every
      // pre-existing row survived untouched.
      onUpgrade: (Migrator m, int from, int to) async {
        throw StateError(
          'No migration path is defined from schema $from to $to. Add one '
          'to AppDatabase.migration before bumping schemaVersion.',
        );
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

/// The on-device file this database lives in, inside the app's documents
/// directory (never a location iOS/Android treat as cache-and-purgeable —
/// this is durable user progress, not a cache).
Future<File> resolveDatabaseFile() async {
  final Directory directory = await getApplicationDocumentsDirectory();
  return File(p.join(directory.path, 'danb_rhs_prep.sqlite'));
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final File file = await resolveDatabaseFile();
    final Database raw = openSqliteWithCorruptionRecovery(file);
    return NativeDatabase.opened(raw);
  });
}

/// SQLite result codes that mean "this file's contents are not a valid
/// (or no longer valid) SQLite database" — as opposed to, say, a disk-full
/// or permission error, which this deliberately does *not* treat as
/// corruption (recreating the database would not fix either of those, and
/// would needlessly destroy progress while doing so).
/// See https://sqlite.org/rescode.html.
const Set<int> _corruptionResultCodes = {
  11, // SQLITE_CORRUPT
  26, // SQLITE_NOTADB
};

/// Opens the SQLite file at [file], with a fully automatic, silent
/// recovery path for genuine file-level corruption specifically (a
/// damaged file from a prior crash/full disk/OS-level issue — not a code
/// bug, and not something re-opening the same bytes could ever fix on its
/// own). Recovery happens synchronously inside this call: a caller that
/// starts from a corrupt file gets back a fresh, working, empty database
/// from this very call, never an exception — there is deliberately no
/// user-visible "Try Again" step for this specific failure, since one
/// isn't needed and retrying would just repeat the same recovery.
/// [AppBootstrapService]'s existing error UI remains reachable, but only
/// for a genuinely different failure: an undefined [AppDatabase.migration]
/// step, a disk that's actually full/unwritable, or (see below) this
/// recovery itself failing to complete.
///
/// Detection is two-layered: `sqlite3.open` only validates the file
/// header (catching e.g. a file that's simply not a database at all —
/// `SQLITE_NOTADB`), so `PRAGMA quick_check` is also run to force the
/// page structure to actually be read. Critically, `quick_check` reports
/// most structural problems as *result rows* saying so (anything other
/// than the single row `ok`), not as a thrown exception — code that only
/// watches for a `SqliteException` (as an earlier version of this
/// function did) would silently let that corruption through unnoticed.
///
/// On detecting corruption either way, the failed [Database] handle is
/// disposed first (a corrupt file cannot be renamed out from under a
/// still-open handle on every platform this app targets), then the main
/// file *and* its `-wal`/`-shm`/`-journal` sidecar files (whichever
/// exist) are quarantined together — renamed aside with a shared
/// timestamp suffix, never deleted outright, so the bytes remain
/// available for support/debugging — before a fresh database is opened in
/// their place. This does lose that specific file's progress (a truly
/// corrupt file has already lost it at the storage level; there is no
/// data left to preserve), and it is attempted exactly once: if the fresh
/// open+validate immediately after quarantining *also* detects
/// corruption, that is a genuinely different, unrecoverable problem (e.g.
/// the directory itself is unwritable) and is allowed to propagate rather
/// than looping forever — this is what would, in that rare case, actually
/// reach `AppBootstrapService`'s error path and `SplashScreen`'s "Try
/// Again".
///
/// Any other failure (disk full, permissions, ...) is deliberately
/// rethrown rather than "recovered" from by deleting a possibly-healthy
/// file — the opposite of `Nie kasuj postepu przy bledzie`.
Database openSqliteWithCorruptionRecovery(File file) {
  try {
    return _openAndValidate(file);
  } on _CorruptDatabaseException {
    _quarantine(file);
    // Deliberately not wrapped in another try/catch: a second failure
    // right after quarantining means recovery itself didn't work, which
    // must propagate as a real, unrecoverable error rather than retrying
    // forever against a directory that's apparently unwritable.
    return _openAndValidate(file);
  }
}

class _CorruptDatabaseException implements Exception {
  _CorruptDatabaseException(this.message);
  final String message;

  @override
  String toString() => 'Corrupt database file: $message';
}

/// Opens [file] and validates it, throwing [_CorruptDatabaseException] —
/// never leaving a dangling open [Database] handle behind — for both ways
/// corruption can surface (see [openSqliteWithCorruptionRecovery]'s doc
/// comment). Any other exception is rethrown as-is.
Database _openAndValidate(File file) {
  Database? database;
  try {
    database = sqlite3.open(file.path);
    final ResultSet result = database.select('PRAGMA quick_check');
    final String status =
        result.isEmpty ? 'ok' : result.first.values.first as String;
    if (status != 'ok') {
      throw _CorruptDatabaseException('PRAGMA quick_check reported: $status');
    }
    return database;
  } on SqliteException catch (error) {
    database?.dispose();
    if (_corruptionResultCodes.contains(error.resultCode)) {
      throw _CorruptDatabaseException(error.toString());
    }
    rethrow;
  } on _CorruptDatabaseException {
    database?.dispose();
    rethrow;
  }
}

/// Every file that makes up [file]'s on-disk state: the main database
/// file plus its write-ahead-log, shared-memory, and rollback-journal
/// sidecar files. A quarantine that only renamed the main file would
/// leave a stale `-wal`/`-shm` behind at the original path — SQLite would
/// then try to replay that stale WAL against the *new*, freshly-created
/// database the moment it's opened, which is exactly the kind of
/// silent-data-mixing a corruption recovery path must never risk.
Iterable<File> _databaseFileAndSidecars(File file) sync* {
  yield file;
  yield File('${file.path}-wal');
  yield File('${file.path}-shm');
  yield File('${file.path}-journal');
}

void _quarantine(File file) {
  final String timestamp =
      DateTime.now().toUtc().millisecondsSinceEpoch.toString();
  for (final File entry in _databaseFileAndSidecars(file)) {
    if (!entry.existsSync()) continue;
    entry.renameSync('${entry.path}.corrupt.$timestamp');
  }
}
