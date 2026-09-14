// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_release_database.dart';

// ignore_for_file: type=lint
class $CachedReleasesTable extends CachedReleases
    with TableInfo<$CachedReleasesTable, CachedRelease> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedReleasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
    'exam_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _releaseVersionMeta = const VerificationMeta(
    'releaseVersion',
  );
  @override
  late final GeneratedColumn<int> releaseVersion = GeneratedColumn<int>(
    'release_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordJsonMeta = const VerificationMeta(
    'recordJson',
  );
  @override
  late final GeneratedColumn<String> recordJson = GeneratedColumn<String>(
    'record_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
        examId,
        releaseVersion,
        recordJson,
        active,
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_releases';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedRelease> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('release_version')) {
      context.handle(
        _releaseVersionMeta,
        releaseVersion.isAcceptableOrUnknown(
          data['release_version']!,
          _releaseVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_releaseVersionMeta);
    }
    if (data.containsKey('record_json')) {
      context.handle(
        _recordJsonMeta,
        recordJson.isAcceptableOrUnknown(data['record_json']!, _recordJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_recordJsonMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {examId, releaseVersion};
  @override
  CachedRelease map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRelease(
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_id'],
      )!,
      releaseVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_version'],
      )!,
      recordJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_json'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $CachedReleasesTable createAlias(String alias) {
    return $CachedReleasesTable(attachedDatabase, alias);
  }
}

class CachedRelease extends DataClass implements Insertable<CachedRelease> {
  final String examId;
  final int releaseVersion;
  final String recordJson;
  final bool active;
  const CachedRelease({
    required this.examId,
    required this.releaseVersion,
    required this.recordJson,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exam_id'] = Variable<String>(examId);
    map['release_version'] = Variable<int>(releaseVersion);
    map['record_json'] = Variable<String>(recordJson);
    map['active'] = Variable<bool>(active);
    return map;
  }

  CachedReleasesCompanion toCompanion(bool nullToAbsent) {
    return CachedReleasesCompanion(
      examId: Value(examId),
      releaseVersion: Value(releaseVersion),
      recordJson: Value(recordJson),
      active: Value(active),
    );
  }

  factory CachedRelease.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRelease(
      examId: serializer.fromJson<String>(json['examId']),
      releaseVersion: serializer.fromJson<int>(json['releaseVersion']),
      recordJson: serializer.fromJson<String>(json['recordJson']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'examId': serializer.toJson<String>(examId),
      'releaseVersion': serializer.toJson<int>(releaseVersion),
      'recordJson': serializer.toJson<String>(recordJson),
      'active': serializer.toJson<bool>(active),
    };
  }

  CachedRelease copyWith({
    String? examId,
    int? releaseVersion,
    String? recordJson,
    bool? active,
  }) =>
      CachedRelease(
        examId: examId ?? this.examId,
        releaseVersion: releaseVersion ?? this.releaseVersion,
        recordJson: recordJson ?? this.recordJson,
        active: active ?? this.active,
      );
  CachedRelease copyWithCompanion(CachedReleasesCompanion data) {
    return CachedRelease(
      examId: data.examId.present ? data.examId.value : this.examId,
      releaseVersion: data.releaseVersion.present
          ? data.releaseVersion.value
          : this.releaseVersion,
      recordJson:
          data.recordJson.present ? data.recordJson.value : this.recordJson,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRelease(')
          ..write('examId: $examId, ')
          ..write('releaseVersion: $releaseVersion, ')
          ..write('recordJson: $recordJson, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(examId, releaseVersion, recordJson, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRelease &&
          other.examId == this.examId &&
          other.releaseVersion == this.releaseVersion &&
          other.recordJson == this.recordJson &&
          other.active == this.active);
}

class CachedReleasesCompanion extends UpdateCompanion<CachedRelease> {
  final Value<String> examId;
  final Value<int> releaseVersion;
  final Value<String> recordJson;
  final Value<bool> active;
  final Value<int> rowid;
  const CachedReleasesCompanion({
    this.examId = const Value.absent(),
    this.releaseVersion = const Value.absent(),
    this.recordJson = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedReleasesCompanion.insert({
    required String examId,
    required int releaseVersion,
    required String recordJson,
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : examId = Value(examId),
        releaseVersion = Value(releaseVersion),
        recordJson = Value(recordJson);
  static Insertable<CachedRelease> custom({
    Expression<String>? examId,
    Expression<int>? releaseVersion,
    Expression<String>? recordJson,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (examId != null) 'exam_id': examId,
      if (releaseVersion != null) 'release_version': releaseVersion,
      if (recordJson != null) 'record_json': recordJson,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedReleasesCompanion copyWith({
    Value<String>? examId,
    Value<int>? releaseVersion,
    Value<String>? recordJson,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return CachedReleasesCompanion(
      examId: examId ?? this.examId,
      releaseVersion: releaseVersion ?? this.releaseVersion,
      recordJson: recordJson ?? this.recordJson,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (releaseVersion.present) {
      map['release_version'] = Variable<int>(releaseVersion.value);
    }
    if (recordJson.present) {
      map['record_json'] = Variable<String>(recordJson.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedReleasesCompanion(')
          ..write('examId: $examId, ')
          ..write('releaseVersion: $releaseVersion, ')
          ..write('recordJson: $recordJson, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ContentReleaseDatabase extends GeneratedDatabase {
  _$ContentReleaseDatabase(QueryExecutor e) : super(e);
  $ContentReleaseDatabaseManager get managers =>
      $ContentReleaseDatabaseManager(this);
  late final $CachedReleasesTable cachedReleases = $CachedReleasesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cachedReleases];
}

typedef $$CachedReleasesTableCreateCompanionBuilder = CachedReleasesCompanion
    Function({
  required String examId,
  required int releaseVersion,
  required String recordJson,
  Value<bool> active,
  Value<int> rowid,
});
typedef $$CachedReleasesTableUpdateCompanionBuilder = CachedReleasesCompanion
    Function({
  Value<String> examId,
  Value<int> releaseVersion,
  Value<String> recordJson,
  Value<bool> active,
  Value<int> rowid,
});

class $$CachedReleasesTableFilterComposer
    extends Composer<_$ContentReleaseDatabase, $CachedReleasesTable> {
  $$CachedReleasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get examId => $composableBuilder(
        column: $table.examId,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<int> get releaseVersion => $composableBuilder(
        column: $table.releaseVersion,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<String> get recordJson => $composableBuilder(
        column: $table.recordJson,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<bool> get active => $composableBuilder(
        column: $table.active,
        builder: (column) => ColumnFilters(column),
      );
}

class $$CachedReleasesTableOrderingComposer
    extends Composer<_$ContentReleaseDatabase, $CachedReleasesTable> {
  $$CachedReleasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get examId => $composableBuilder(
        column: $table.examId,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<int> get releaseVersion => $composableBuilder(
        column: $table.releaseVersion,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get recordJson => $composableBuilder(
        column: $table.recordJson,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<bool> get active => $composableBuilder(
        column: $table.active,
        builder: (column) => ColumnOrderings(column),
      );
}

class $$CachedReleasesTableAnnotationComposer
    extends Composer<_$ContentReleaseDatabase, $CachedReleasesTable> {
  $$CachedReleasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get examId =>
      $composableBuilder(column: $table.examId, builder: (column) => column);

  GeneratedColumn<int> get releaseVersion => $composableBuilder(
        column: $table.releaseVersion,
        builder: (column) => column,
      );

  GeneratedColumn<String> get recordJson => $composableBuilder(
        column: $table.recordJson,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$CachedReleasesTableTableManager extends RootTableManager<
    _$ContentReleaseDatabase,
    $CachedReleasesTable,
    CachedRelease,
    $$CachedReleasesTableFilterComposer,
    $$CachedReleasesTableOrderingComposer,
    $$CachedReleasesTableAnnotationComposer,
    $$CachedReleasesTableCreateCompanionBuilder,
    $$CachedReleasesTableUpdateCompanionBuilder,
    (
      CachedRelease,
      BaseReferences<_$ContentReleaseDatabase, $CachedReleasesTable,
          CachedRelease>,
    ),
    CachedRelease,
    PrefetchHooks Function()> {
  $$CachedReleasesTableTableManager(
    _$ContentReleaseDatabase db,
    $CachedReleasesTable table,
  ) : super(
          TableManagerState(
            db: db,
            table: table,
            createFilteringComposer: () =>
                $$CachedReleasesTableFilterComposer($db: db, $table: table),
            createOrderingComposer: () =>
                $$CachedReleasesTableOrderingComposer($db: db, $table: table),
            createComputedFieldComposer: () =>
                $$CachedReleasesTableAnnotationComposer($db: db, $table: table),
            updateCompanionCallback: ({
              Value<String> examId = const Value.absent(),
              Value<int> releaseVersion = const Value.absent(),
              Value<String> recordJson = const Value.absent(),
              Value<bool> active = const Value.absent(),
              Value<int> rowid = const Value.absent(),
            }) =>
                CachedReleasesCompanion(
              examId: examId,
              releaseVersion: releaseVersion,
              recordJson: recordJson,
              active: active,
              rowid: rowid,
            ),
            createCompanionCallback: ({
              required String examId,
              required int releaseVersion,
              required String recordJson,
              Value<bool> active = const Value.absent(),
              Value<int> rowid = const Value.absent(),
            }) =>
                CachedReleasesCompanion.insert(
              examId: examId,
              releaseVersion: releaseVersion,
              recordJson: recordJson,
              active: active,
              rowid: rowid,
            ),
            withReferenceMapper: (p0) => p0
                .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
                .toList(),
            prefetchHooksCallback: null,
          ),
        );
}

typedef $$CachedReleasesTableProcessedTableManager = ProcessedTableManager<
    _$ContentReleaseDatabase,
    $CachedReleasesTable,
    CachedRelease,
    $$CachedReleasesTableFilterComposer,
    $$CachedReleasesTableOrderingComposer,
    $$CachedReleasesTableAnnotationComposer,
    $$CachedReleasesTableCreateCompanionBuilder,
    $$CachedReleasesTableUpdateCompanionBuilder,
    (
      CachedRelease,
      BaseReferences<_$ContentReleaseDatabase, $CachedReleasesTable,
          CachedRelease>,
    ),
    CachedRelease,
    PrefetchHooks Function()>;

class $ContentReleaseDatabaseManager {
  final _$ContentReleaseDatabase _db;
  $ContentReleaseDatabaseManager(this._db);
  $$CachedReleasesTableTableManager get cachedReleases =>
      $$CachedReleasesTableTableManager(_db, _db.cachedReleases);
}
