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
/// the app before it can show a recoverable error. See
/// [openSqliteWithCorruptionRecovery]'s own doc comment for exactly what
/// "controlled" means for corruption specifically, and this class's
/// [migration] for schema upgrades.
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

/// Opens the SQLite file at [path], with a controlled recovery path for
/// genuine file-level corruption specifically (a damaged file from a
/// prior crash/full disk/OS-level issue — not a code bug, and not
/// something a "Try Again" retry could ever fix on its own, since the
/// same corrupt bytes would just fail identically every time).
///
/// On a corruption result code, the corrupt file is quarantined —
/// renamed aside with a timestamp suffix, never deleted outright, so the
/// bytes remain available for support/debugging — and a fresh database is
/// opened in its place. This does lose that specific file's progress
/// (a truly corrupt file has already lost it at the storage level; there
/// is no data left to preserve), but it is the only way "Try Again"
/// (`SplashScreen`'s existing retry, since any exception from opening
/// this database while `AppBootstrapService` bootstraps surfaces through
/// its existing `BootstrapUnexpectedFailure` path) can ever actually
/// succeed after corruption, rather than failing identically forever.
///
/// Any other failure (disk full, permissions, ...) is deliberately
/// rethrown rather than "recovered" from by deleting a possibly-healthy
/// file — the opposite of `Nie kasuj postepu przy bledzie`.
Database openSqliteWithCorruptionRecovery(File file) {
  Database openFresh() {
    final Database database = sqlite3.open(file.path);
    // `sqlite3.open` only validates the file header; a quick_check forces
    // the page structure to actually be read, so a corrupt body (not just
    // a corrupt header) is caught here too, before this app ever writes
    // to (and potentially further damages) the file.
    database.select('PRAGMA quick_check');
    return database;
  }

  try {
    return openFresh();
  } on SqliteException catch (error) {
    if (!_corruptionResultCodes.contains(error.resultCode)) rethrow;
    _quarantine(file);
    return openFresh();
  }
}

void _quarantine(File file) {
  if (!file.existsSync()) return;
  final String timestamp =
      DateTime.now().toUtc().millisecondsSinceEpoch.toString();
  file.renameSync('${file.path}.corrupt.$timestamp');
}
