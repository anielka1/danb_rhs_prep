import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'migration_fixture_v1.dart';
import 'migration_fixture_v2.dart';

/// Complements `app_database_test.dart`'s "migration safety net" group
/// (which proves an *undefined* upgrade throws loudly) with proof that a
/// *defined* upgrade — the `Migrator.addColumn` shape
/// `AppDatabase.migration`'s doc comment tells a future author to use —
/// actually preserves pre-existing rows, using the fixture schema pair in
/// `migration_fixture.dart` (see that file's own doc comment for why a
/// fixture, not `AppDatabase` itself, since no real schema 2 exists yet).
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('app_database_migration');
    dbFile = File('${tempDir.path}/notes.sqlite');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test(
      'upgrading from schema 1 to 2 preserves every pre-existing row, '
      'with the new column at its declared default', () async {
    final NotesDatabaseV1 v1 = NotesDatabaseV1(NativeDatabase(dbFile));
    await v1.into(v1.notes).insert(
          NotesCompanion.insert(id: 'note-1', body: 'written under schema 1'),
        );
    await v1.close();

    final NotesDatabaseV2 v2 = NotesDatabaseV2(NativeDatabase(dbFile));
    addTearDown(v2.close);

    final rows = await v2.select(v2.notesV2).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, 'note-1');
    expect(rows.single.body, 'written under schema 1');
    expect(rows.single.pinned, isFalse,
        reason: 'the new column must take its declared default for rows '
            'written before it existed, never null/a crash');
  });

  test('a fresh install at schema 2 never runs onUpgrade at all', () async {
    final NotesDatabaseV2 v2 = NotesDatabaseV2(NativeDatabase(dbFile));
    addTearDown(v2.close);

    await v2
        .into(v2.notesV2)
        .insert(NotesV2Companion.insert(id: 'note-1', body: 'fresh install'));

    final rows = await v2.select(v2.notesV2).get();
    expect(rows, hasLength(1));
    expect(rows.single.pinned, isFalse);
  });
}
