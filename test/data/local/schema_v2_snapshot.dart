import 'package:drift/drift.dart';

part 'schema_v2_snapshot.g.dart';

/// A frozen copy of every table `AppDatabase` declared at schema version
/// 2 (PREP-664), exactly as it was before PREP-668 added
/// `questionVersion`/`correctAnswerId`/`explanation` to `AnswerAttempts`.
/// Table/column names are identical to `lib/data/local/app_database.dart`'s
/// real tables on purpose, so a database created from this snapshot is
/// byte-for-byte what a real user's schema-2 install would be.
///
/// This must never be edited to track future schema changes — it is a
/// historical snapshot, not a second copy of the live schema. See
/// `schema_v1_snapshot.dart`'s own doc comment for the same rule at the
/// version before this one.
///
/// Used only by `app_database_migration_v3_test.dart`, to seed a
/// realistic schema-2 database file that the *real* `AppDatabase` (not a
/// parallel fixture database) then opens and migrates — proving the
/// actual production migration code, not a stand-in for it.
class AnswerAttemptsV2 extends Table {
  @override
  String get tableName => 'answer_attempts';

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
  DateTimeColumn get answeredAt => dateTime()();
  TextColumn get contentVersion => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class QuestionStatesV2 extends Table {
  @override
  String get tableName => 'question_states';

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

class PracticeSessionsV2 extends Table {
  @override
  String get tableName => 'practice_sessions';

  TextColumn get id => text()();
  TextColumn get examId => text()();
  TextColumn get mode => text()();
  TextColumn get questionIdsJson => text()();
  TextColumn get status => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get contentVersion => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MockAttemptsV2 extends Table {
  @override
  String get tableName => 'mock_attempts';

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

class ReadinessSnapshotsV2 extends Table {
  @override
  String get tableName => 'readiness_snapshots';

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

class UserProfilesV2 extends Table {
  @override
  String get tableName => 'user_profiles';

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

@DriftDatabase(tables: [
  AnswerAttemptsV2,
  QuestionStatesV2,
  PracticeSessionsV2,
  MockAttemptsV2,
  ReadinessSnapshotsV2,
  UserProfilesV2,
])
class SchemaV2Snapshot extends _$SchemaV2Snapshot {
  SchemaV2Snapshot(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}
