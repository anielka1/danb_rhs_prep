// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'migration_fixture_v2.dart';

// ignore_for_file: type=lint
class $NotesV2Table extends NotesV2 with TableInfo<$NotesV2Table, NoteRowV2> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesV2Table(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
      'pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [id, body, pinned];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(Insertable<NoteRowV2> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('pinned')) {
      context.handle(_pinnedMeta,
          pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRowV2 map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRowV2(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      pinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pinned'])!,
    );
  }

  @override
  $NotesV2Table createAlias(String alias) {
    return $NotesV2Table(attachedDatabase, alias);
  }
}

class NoteRowV2 extends DataClass implements Insertable<NoteRowV2> {
  final String id;
  final String body;
  final bool pinned;
  const NoteRowV2({required this.id, required this.body, required this.pinned});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['body'] = Variable<String>(body);
    map['pinned'] = Variable<bool>(pinned);
    return map;
  }

  NotesV2Companion toCompanion(bool nullToAbsent) {
    return NotesV2Companion(
      id: Value(id),
      body: Value(body),
      pinned: Value(pinned),
    );
  }

  factory NoteRowV2.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRowV2(
      id: serializer.fromJson<String>(json['id']),
      body: serializer.fromJson<String>(json['body']),
      pinned: serializer.fromJson<bool>(json['pinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'body': serializer.toJson<String>(body),
      'pinned': serializer.toJson<bool>(pinned),
    };
  }

  NoteRowV2 copyWith({String? id, String? body, bool? pinned}) => NoteRowV2(
        id: id ?? this.id,
        body: body ?? this.body,
        pinned: pinned ?? this.pinned,
      );
  NoteRowV2 copyWithCompanion(NotesV2Companion data) {
    return NoteRowV2(
      id: data.id.present ? data.id.value : this.id,
      body: data.body.present ? data.body.value : this.body,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRowV2(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('pinned: $pinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, body, pinned);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRowV2 &&
          other.id == this.id &&
          other.body == this.body &&
          other.pinned == this.pinned);
}

class NotesV2Companion extends UpdateCompanion<NoteRowV2> {
  final Value<String> id;
  final Value<String> body;
  final Value<bool> pinned;
  final Value<int> rowid;
  const NotesV2Companion({
    this.id = const Value.absent(),
    this.body = const Value.absent(),
    this.pinned = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesV2Companion.insert({
    required String id,
    required String body,
    this.pinned = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        body = Value(body);
  static Insertable<NoteRowV2> custom({
    Expression<String>? id,
    Expression<String>? body,
    Expression<bool>? pinned,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (body != null) 'body': body,
      if (pinned != null) 'pinned': pinned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesV2Companion copyWith(
      {Value<String>? id,
      Value<String>? body,
      Value<bool>? pinned,
      Value<int>? rowid}) {
    return NotesV2Companion(
      id: id ?? this.id,
      body: body ?? this.body,
      pinned: pinned ?? this.pinned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesV2Companion(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('pinned: $pinned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$NotesDatabaseV2 extends GeneratedDatabase {
  _$NotesDatabaseV2(QueryExecutor e) : super(e);
  $NotesDatabaseV2Manager get managers => $NotesDatabaseV2Manager(this);
  late final $NotesV2Table notesV2 = $NotesV2Table(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [notesV2];
}

typedef $$NotesV2TableCreateCompanionBuilder = NotesV2Companion Function({
  required String id,
  required String body,
  Value<bool> pinned,
  Value<int> rowid,
});
typedef $$NotesV2TableUpdateCompanionBuilder = NotesV2Companion Function({
  Value<String> id,
  Value<String> body,
  Value<bool> pinned,
  Value<int> rowid,
});

class $$NotesV2TableFilterComposer
    extends Composer<_$NotesDatabaseV2, $NotesV2Table> {
  $$NotesV2TableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnFilters(column));
}

class $$NotesV2TableOrderingComposer
    extends Composer<_$NotesDatabaseV2, $NotesV2Table> {
  $$NotesV2TableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnOrderings(column));
}

class $$NotesV2TableAnnotationComposer
    extends Composer<_$NotesDatabaseV2, $NotesV2Table> {
  $$NotesV2TableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);
}

class $$NotesV2TableTableManager extends RootTableManager<
    _$NotesDatabaseV2,
    $NotesV2Table,
    NoteRowV2,
    $$NotesV2TableFilterComposer,
    $$NotesV2TableOrderingComposer,
    $$NotesV2TableAnnotationComposer,
    $$NotesV2TableCreateCompanionBuilder,
    $$NotesV2TableUpdateCompanionBuilder,
    (NoteRowV2, BaseReferences<_$NotesDatabaseV2, $NotesV2Table, NoteRowV2>),
    NoteRowV2,
    PrefetchHooks Function()> {
  $$NotesV2TableTableManager(_$NotesDatabaseV2 db, $NotesV2Table table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesV2TableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesV2TableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesV2TableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotesV2Companion(
            id: id,
            body: body,
            pinned: pinned,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String body,
            Value<bool> pinned = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotesV2Companion.insert(
            id: id,
            body: body,
            pinned: pinned,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotesV2TableProcessedTableManager = ProcessedTableManager<
    _$NotesDatabaseV2,
    $NotesV2Table,
    NoteRowV2,
    $$NotesV2TableFilterComposer,
    $$NotesV2TableOrderingComposer,
    $$NotesV2TableAnnotationComposer,
    $$NotesV2TableCreateCompanionBuilder,
    $$NotesV2TableUpdateCompanionBuilder,
    (NoteRowV2, BaseReferences<_$NotesDatabaseV2, $NotesV2Table, NoteRowV2>),
    NoteRowV2,
    PrefetchHooks Function()>;

class $NotesDatabaseV2Manager {
  final _$NotesDatabaseV2 _db;
  $NotesDatabaseV2Manager(this._db);
  $$NotesV2TableTableManager get notesV2 =>
      $$NotesV2TableTableManager(_db, _db.notesV2);
}
