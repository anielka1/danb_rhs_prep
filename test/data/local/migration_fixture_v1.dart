import 'package:drift/drift.dart';

part 'migration_fixture_v1.g.dart';

/// A minimal, test-only schema pair (this file: version 1; version 2 in
/// `migration_fixture_v2.dart` — split across two files because drift's
/// codegen for [NotesV2] pinning its table name back to `notes` collides,
/// within a single library, with this file's own `notes` table) proving
/// the *mechanism* this app's real migrations will rely on — `onUpgrade`
/// adding a column via `Migrator.addColumn` — actually preserves
/// pre-existing rows when run against this repo's pinned drift/sqlite3
/// versions.
///
/// `AppDatabase` (schema 1, `lib/data/local/app_database.dart`) has no
/// real schema 2 yet to migrate to or from, so there is nothing genuine
/// to seed/upgrade/assert against there today. This fixture is not a
/// stand-in for that future test — when a real column/table is added to
/// `AppDatabase`, *that* change needs its own upgrade test seeding real
/// production rows. It exists so "upgrade" in PREP-661's test plan has
/// concrete, passing evidence now, of the same primitives
/// `AppDatabase.migration`'s `onUpgrade` doc comment already tells a
/// future author to use.
@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get body => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Notes])
class NotesDatabaseV1 extends _$NotesDatabaseV1 {
  NotesDatabaseV1(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}
