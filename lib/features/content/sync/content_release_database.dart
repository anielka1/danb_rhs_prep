import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'content_release.dart';

part 'content_release_database.g.dart';

class CachedReleases extends Table {
  TextColumn get examId => text()();
  IntColumn get releaseVersion => integer()();
  TextColumn get recordJson => text()();
  BoolColumn get active => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {examId, releaseVersion};
}

/// Separate Drift database: this adapter cannot write to progress tables.
/// Append-only versions retain the last good bank and the active session bank.
@DriftDatabase(tables: [CachedReleases])
class ContentReleaseDatabase extends _$ContentReleaseDatabase {
  ContentReleaseDatabase()
      : super(
          LazyDatabase(() async {
            final directory = await getApplicationDocumentsDirectory();
            return NativeDatabase(
              File(p.join(directory.path, 'question_banks.sqlite')),
            );
          }),
        );
  ContentReleaseDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Future<List<CachedRelease>> releases(String examId) => (select(cachedReleases)
        ..where((r) => r.examId.equals(examId))
        ..orderBy([(r) => OrderingTerm.desc(r.releaseVersion)]))
      .get();

  Future<bool> install(ContentRelease release) => transaction(() async {
        final existing = await releases(release.examId);
        if (existing.any((row) => row.releaseVersion >= release.version)) {
          return false;
        }
        // contentVersion identifies a session snapshot: never reuse it with a new bank.
        if (existing.any(
          (row) =>
              (jsonDecode(row.recordJson) as Map)['content_version'] ==
              release.package.contentVersion,
        )) {
          throw const FormatException(
            'Content version must be unique per release.',
          );
        }
        await into(cachedReleases).insert(
          CachedReleasesCompanion.insert(
            examId: release.examId,
            releaseVersion: release.version,
            recordJson: release.recordJson,
          ),
        );
        return true;
      });

  Future<void> activate(CachedRelease release) => transaction(() async {
        await (update(cachedReleases)
              ..where((r) => r.examId.equals(release.examId)))
            .write(const CachedReleasesCompanion(active: Value(false)));
        await (update(cachedReleases)
              ..where(
                (r) =>
                    r.examId.equals(release.examId) &
                    r.releaseVersion.equals(release.releaseVersion),
              ))
            .write(const CachedReleasesCompanion(active: Value(true)));
      });
}
