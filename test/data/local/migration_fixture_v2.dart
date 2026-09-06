import 'package:drift/drift.dart';

part 'migration_fixture_v2.g.dart';

/// Version 2 of the schema pair started in `migration_fixture_v1.dart` —
/// see that file's doc comment for why this is a separate library and
/// what this fixture is (and isn't) evidence of.
@DataClassName('NoteRowV2')
class NotesV2 extends Table {
  TextColumn get id => text()();
  TextColumn get body => text()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  // Physical table name must stay 'notes' — matching `Notes` in
  // migration_fixture_v1.dart — since this is the *same* table across
  // schema versions; without this, drift's default (derived from the
  // Dart class name `NotesV2`) would migrate a table named "notes_v2"
  // instead of the real "notes" table the v1 database created.
  @override
  String get tableName => 'notes';

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [NotesV2])
class NotesDatabaseV2 extends _$NotesDatabaseV2 {
  NotesDatabaseV2(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from == 1 && to == 2) {
            await m.addColumn(notesV2, notesV2.pinned);
            return;
          }
          throw StateError('Unhandled migration $from -> $to');
        },
      );
}
