// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AnswerAttemptsTable extends AnswerAttempts
    with TableInfo<$AnswerAttemptsTable, AnswerAttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnswerAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _confidentMeta =
      const VerificationMeta('confident');
  @override
  late final GeneratedColumn<bool> confident = GeneratedColumn<bool>(
      'confident', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("confident" IN (0, 1))'));
  static const VerificationMeta _activeDurationSecondsMeta =
      const VerificationMeta('activeDurationSeconds');
  @override
  late final GeneratedColumn<int> activeDurationSeconds = GeneratedColumn<int>(
      'active_duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _localAnsweredDateMeta =
      const VerificationMeta('localAnsweredDate');
  @override
  late final GeneratedColumn<String> localAnsweredDate =
      GeneratedColumn<String>('local_answered_date', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
      'exam_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _domainIdMeta =
      const VerificationMeta('domainId');
  @override
  late final GeneratedColumn<String> domainId = GeneratedColumn<String>(
      'domain_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _topicIdMeta =
      const VerificationMeta('topicId');
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
      'topic_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionTypeMeta =
      const VerificationMeta('sessionType');
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
      'session_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _selectedAnswerIdMeta =
      const VerificationMeta('selectedAnswerId');
  @override
  late final GeneratedColumn<String> selectedAnswerId = GeneratedColumn<String>(
      'selected_answer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCorrectMeta =
      const VerificationMeta('isCorrect');
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
      'is_correct', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_correct" IN (0, 1))'));
  static const VerificationMeta _answeredAtMeta =
      const VerificationMeta('answeredAt');
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
      'answered_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _contentVersionMeta =
      const VerificationMeta('contentVersion');
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
      'content_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _questionVersionMeta =
      const VerificationMeta('questionVersion');
  @override
  late final GeneratedColumn<int> questionVersion = GeneratedColumn<int>(
      'question_version', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _correctAnswerIdMeta =
      const VerificationMeta('correctAnswerId');
  @override
  late final GeneratedColumn<String> correctAnswerId = GeneratedColumn<String>(
      'correct_answer_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _explanationMeta =
      const VerificationMeta('explanation');
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
      'explanation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        confident,
        activeDurationSeconds,
        localAnsweredDate,
        id,
        examId,
        questionId,
        domainId,
        topicId,
        difficulty,
        sessionId,
        sessionType,
        selectedAnswerId,
        isCorrect,
        answeredAt,
        contentVersion,
        questionVersion,
        correctAnswerId,
        explanation
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'answer_attempts';
  @override
  VerificationContext validateIntegrity(Insertable<AnswerAttemptRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('confident')) {
      context.handle(_confidentMeta,
          confident.isAcceptableOrUnknown(data['confident']!, _confidentMeta));
    }
    if (data.containsKey('active_duration_seconds')) {
      context.handle(
          _activeDurationSecondsMeta,
          activeDurationSeconds.isAcceptableOrUnknown(
              data['active_duration_seconds']!, _activeDurationSecondsMeta));
    }
    if (data.containsKey('local_answered_date')) {
      context.handle(
          _localAnsweredDateMeta,
          localAnsweredDate.isAcceptableOrUnknown(
              data['local_answered_date']!, _localAnsweredDateMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(_examIdMeta,
          examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta));
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('domain_id')) {
      context.handle(_domainIdMeta,
          domainId.isAcceptableOrUnknown(data['domain_id']!, _domainIdMeta));
    } else if (isInserting) {
      context.missing(_domainIdMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(_topicIdMeta,
          topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta));
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('session_type')) {
      context.handle(
          _sessionTypeMeta,
          sessionType.isAcceptableOrUnknown(
              data['session_type']!, _sessionTypeMeta));
    } else if (isInserting) {
      context.missing(_sessionTypeMeta);
    }
    if (data.containsKey('selected_answer_id')) {
      context.handle(
          _selectedAnswerIdMeta,
          selectedAnswerId.isAcceptableOrUnknown(
              data['selected_answer_id']!, _selectedAnswerIdMeta));
    } else if (isInserting) {
      context.missing(_selectedAnswerIdMeta);
    }
    if (data.containsKey('is_correct')) {
      context.handle(_isCorrectMeta,
          isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta));
    } else if (isInserting) {
      context.missing(_isCorrectMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
          _answeredAtMeta,
          answeredAt.isAcceptableOrUnknown(
              data['answered_at']!, _answeredAtMeta));
    } else if (isInserting) {
      context.missing(_answeredAtMeta);
    }
    if (data.containsKey('content_version')) {
      context.handle(
          _contentVersionMeta,
          contentVersion.isAcceptableOrUnknown(
              data['content_version']!, _contentVersionMeta));
    }
    if (data.containsKey('question_version')) {
      context.handle(
          _questionVersionMeta,
          questionVersion.isAcceptableOrUnknown(
              data['question_version']!, _questionVersionMeta));
    }
    if (data.containsKey('correct_answer_id')) {
      context.handle(
          _correctAnswerIdMeta,
          correctAnswerId.isAcceptableOrUnknown(
              data['correct_answer_id']!, _correctAnswerIdMeta));
    }
    if (data.containsKey('explanation')) {
      context.handle(
          _explanationMeta,
          explanation.isAcceptableOrUnknown(
              data['explanation']!, _explanationMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnswerAttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnswerAttemptRow(
      confident: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}confident']),
      activeDurationSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}active_duration_seconds']),
      localAnsweredDate: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}local_answered_date']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      examId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exam_id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      domainId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}domain_id'])!,
      topicId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}topic_id'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}difficulty'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      sessionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_type'])!,
      selectedAnswerId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}selected_answer_id'])!,
      isCorrect: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_correct'])!,
      answeredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}answered_at'])!,
      contentVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_version']),
      questionVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}question_version']),
      correctAnswerId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}correct_answer_id']),
      explanation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}explanation']),
    );
  }

  @override
  $AnswerAttemptsTable createAlias(String alias) {
    return $AnswerAttemptsTable(attachedDatabase, alias);
  }
}

class AnswerAttemptRow extends DataClass
    implements Insertable<AnswerAttemptRow> {
  final bool? confident;
  final int? activeDurationSeconds;
  final String? localAnsweredDate;
  final String id;
  final String examId;
  final String questionId;
  final String domainId;
  final String topicId;
  final int difficulty;
  final String sessionId;
  final String sessionType;
  final String selectedAnswerId;
  final bool isCorrect;

  /// Always UTC — see `AppDatabase`'s doc comment for how that's enforced
  /// uniformly across every `DateTimeColumn` in this database.
  final DateTime answeredAt;

  /// Added in schema 2 (PREP-664) — see [AnswerAttempt.contentVersion]'s
  /// doc comment. Nullable so every row from schema 1 remains valid
  /// after the upgrade, with no value to backfill it from.
  final String? contentVersion;

  /// Added in schema 3 (PREP-668) — see [AnswerAttempt.questionVersion]'s
  /// doc comment. Nullable so every row from schema < 3 remains valid
  /// after the upgrade, with no value to backfill it from;
  /// `PracticeSessionController.resume` treats a row missing any of
  /// these three new columns as having no reconstructable feedback
  /// snapshot, rather than fabricating one from today's content.
  final int? questionVersion;

  /// Added in schema 3 (PREP-668) — see
  /// [AnswerAttempt.correctAnswerId]'s doc comment.
  final String? correctAnswerId;

  /// Added in schema 3 (PREP-668) — see [AnswerAttempt.explanation]'s
  /// doc comment.
  final String? explanation;
  const AnswerAttemptRow(
      {this.confident,
      this.activeDurationSeconds,
      this.localAnsweredDate,
      required this.id,
      required this.examId,
      required this.questionId,
      required this.domainId,
      required this.topicId,
      required this.difficulty,
      required this.sessionId,
      required this.sessionType,
      required this.selectedAnswerId,
      required this.isCorrect,
      required this.answeredAt,
      this.contentVersion,
      this.questionVersion,
      this.correctAnswerId,
      this.explanation});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || confident != null) {
      map['confident'] = Variable<bool>(confident);
    }
    if (!nullToAbsent || activeDurationSeconds != null) {
      map['active_duration_seconds'] = Variable<int>(activeDurationSeconds);
    }
    if (!nullToAbsent || localAnsweredDate != null) {
      map['local_answered_date'] = Variable<String>(localAnsweredDate);
    }
    map['id'] = Variable<String>(id);
    map['exam_id'] = Variable<String>(examId);
    map['question_id'] = Variable<String>(questionId);
    map['domain_id'] = Variable<String>(domainId);
    map['topic_id'] = Variable<String>(topicId);
    map['difficulty'] = Variable<int>(difficulty);
    map['session_id'] = Variable<String>(sessionId);
    map['session_type'] = Variable<String>(sessionType);
    map['selected_answer_id'] = Variable<String>(selectedAnswerId);
    map['is_correct'] = Variable<bool>(isCorrect);
    map['answered_at'] = Variable<DateTime>(answeredAt);
    if (!nullToAbsent || contentVersion != null) {
      map['content_version'] = Variable<String>(contentVersion);
    }
    if (!nullToAbsent || questionVersion != null) {
      map['question_version'] = Variable<int>(questionVersion);
    }
    if (!nullToAbsent || correctAnswerId != null) {
      map['correct_answer_id'] = Variable<String>(correctAnswerId);
    }
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    return map;
  }

  AnswerAttemptsCompanion toCompanion(bool nullToAbsent) {
    return AnswerAttemptsCompanion(
      confident: confident == null && nullToAbsent
          ? const Value.absent()
          : Value(confident),
      activeDurationSeconds: activeDurationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(activeDurationSeconds),
      localAnsweredDate: localAnsweredDate == null && nullToAbsent
          ? const Value.absent()
          : Value(localAnsweredDate),
      id: Value(id),
      examId: Value(examId),
      questionId: Value(questionId),
      domainId: Value(domainId),
      topicId: Value(topicId),
      difficulty: Value(difficulty),
      sessionId: Value(sessionId),
      sessionType: Value(sessionType),
      selectedAnswerId: Value(selectedAnswerId),
      isCorrect: Value(isCorrect),
      answeredAt: Value(answeredAt),
      contentVersion: contentVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(contentVersion),
      questionVersion: questionVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(questionVersion),
      correctAnswerId: correctAnswerId == null && nullToAbsent
          ? const Value.absent()
          : Value(correctAnswerId),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
    );
  }

  factory AnswerAttemptRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnswerAttemptRow(
      confident: serializer.fromJson<bool?>(json['confident']),
      activeDurationSeconds:
          serializer.fromJson<int?>(json['activeDurationSeconds']),
      localAnsweredDate:
          serializer.fromJson<String?>(json['localAnsweredDate']),
      id: serializer.fromJson<String>(json['id']),
      examId: serializer.fromJson<String>(json['examId']),
      questionId: serializer.fromJson<String>(json['questionId']),
      domainId: serializer.fromJson<String>(json['domainId']),
      topicId: serializer.fromJson<String>(json['topicId']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      selectedAnswerId: serializer.fromJson<String>(json['selectedAnswerId']),
      isCorrect: serializer.fromJson<bool>(json['isCorrect']),
      answeredAt: serializer.fromJson<DateTime>(json['answeredAt']),
      contentVersion: serializer.fromJson<String?>(json['contentVersion']),
      questionVersion: serializer.fromJson<int?>(json['questionVersion']),
      correctAnswerId: serializer.fromJson<String?>(json['correctAnswerId']),
      explanation: serializer.fromJson<String?>(json['explanation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'confident': serializer.toJson<bool?>(confident),
      'activeDurationSeconds': serializer.toJson<int?>(activeDurationSeconds),
      'localAnsweredDate': serializer.toJson<String?>(localAnsweredDate),
      'id': serializer.toJson<String>(id),
      'examId': serializer.toJson<String>(examId),
      'questionId': serializer.toJson<String>(questionId),
      'domainId': serializer.toJson<String>(domainId),
      'topicId': serializer.toJson<String>(topicId),
      'difficulty': serializer.toJson<int>(difficulty),
      'sessionId': serializer.toJson<String>(sessionId),
      'sessionType': serializer.toJson<String>(sessionType),
      'selectedAnswerId': serializer.toJson<String>(selectedAnswerId),
      'isCorrect': serializer.toJson<bool>(isCorrect),
      'answeredAt': serializer.toJson<DateTime>(answeredAt),
      'contentVersion': serializer.toJson<String?>(contentVersion),
      'questionVersion': serializer.toJson<int?>(questionVersion),
      'correctAnswerId': serializer.toJson<String?>(correctAnswerId),
      'explanation': serializer.toJson<String?>(explanation),
    };
  }

  AnswerAttemptRow copyWith(
          {Value<bool?> confident = const Value.absent(),
          Value<int?> activeDurationSeconds = const Value.absent(),
          Value<String?> localAnsweredDate = const Value.absent(),
          String? id,
          String? examId,
          String? questionId,
          String? domainId,
          String? topicId,
          int? difficulty,
          String? sessionId,
          String? sessionType,
          String? selectedAnswerId,
          bool? isCorrect,
          DateTime? answeredAt,
          Value<String?> contentVersion = const Value.absent(),
          Value<int?> questionVersion = const Value.absent(),
          Value<String?> correctAnswerId = const Value.absent(),
          Value<String?> explanation = const Value.absent()}) =>
      AnswerAttemptRow(
        confident: confident.present ? confident.value : this.confident,
        activeDurationSeconds: activeDurationSeconds.present
            ? activeDurationSeconds.value
            : this.activeDurationSeconds,
        localAnsweredDate: localAnsweredDate.present
            ? localAnsweredDate.value
            : this.localAnsweredDate,
        id: id ?? this.id,
        examId: examId ?? this.examId,
        questionId: questionId ?? this.questionId,
        domainId: domainId ?? this.domainId,
        topicId: topicId ?? this.topicId,
        difficulty: difficulty ?? this.difficulty,
        sessionId: sessionId ?? this.sessionId,
        sessionType: sessionType ?? this.sessionType,
        selectedAnswerId: selectedAnswerId ?? this.selectedAnswerId,
        isCorrect: isCorrect ?? this.isCorrect,
        answeredAt: answeredAt ?? this.answeredAt,
        contentVersion:
            contentVersion.present ? contentVersion.value : this.contentVersion,
        questionVersion: questionVersion.present
            ? questionVersion.value
            : this.questionVersion,
        correctAnswerId: correctAnswerId.present
            ? correctAnswerId.value
            : this.correctAnswerId,
        explanation: explanation.present ? explanation.value : this.explanation,
      );
  AnswerAttemptRow copyWithCompanion(AnswerAttemptsCompanion data) {
    return AnswerAttemptRow(
      confident: data.confident.present ? data.confident.value : this.confident,
      activeDurationSeconds: data.activeDurationSeconds.present
          ? data.activeDurationSeconds.value
          : this.activeDurationSeconds,
      localAnsweredDate: data.localAnsweredDate.present
          ? data.localAnsweredDate.value
          : this.localAnsweredDate,
      id: data.id.present ? data.id.value : this.id,
      examId: data.examId.present ? data.examId.value : this.examId,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      domainId: data.domainId.present ? data.domainId.value : this.domainId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      sessionType:
          data.sessionType.present ? data.sessionType.value : this.sessionType,
      selectedAnswerId: data.selectedAnswerId.present
          ? data.selectedAnswerId.value
          : this.selectedAnswerId,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      answeredAt:
          data.answeredAt.present ? data.answeredAt.value : this.answeredAt,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      questionVersion: data.questionVersion.present
          ? data.questionVersion.value
          : this.questionVersion,
      correctAnswerId: data.correctAnswerId.present
          ? data.correctAnswerId.value
          : this.correctAnswerId,
      explanation:
          data.explanation.present ? data.explanation.value : this.explanation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnswerAttemptRow(')
          ..write('confident: $confident, ')
          ..write('activeDurationSeconds: $activeDurationSeconds, ')
          ..write('localAnsweredDate: $localAnsweredDate, ')
          ..write('id: $id, ')
          ..write('examId: $examId, ')
          ..write('questionId: $questionId, ')
          ..write('domainId: $domainId, ')
          ..write('topicId: $topicId, ')
          ..write('difficulty: $difficulty, ')
          ..write('sessionId: $sessionId, ')
          ..write('sessionType: $sessionType, ')
          ..write('selectedAnswerId: $selectedAnswerId, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('questionVersion: $questionVersion, ')
          ..write('correctAnswerId: $correctAnswerId, ')
          ..write('explanation: $explanation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      confident,
      activeDurationSeconds,
      localAnsweredDate,
      id,
      examId,
      questionId,
      domainId,
      topicId,
      difficulty,
      sessionId,
      sessionType,
      selectedAnswerId,
      isCorrect,
      answeredAt,
      contentVersion,
      questionVersion,
      correctAnswerId,
      explanation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnswerAttemptRow &&
          other.confident == this.confident &&
          other.activeDurationSeconds == this.activeDurationSeconds &&
          other.localAnsweredDate == this.localAnsweredDate &&
          other.id == this.id &&
          other.examId == this.examId &&
          other.questionId == this.questionId &&
          other.domainId == this.domainId &&
          other.topicId == this.topicId &&
          other.difficulty == this.difficulty &&
          other.sessionId == this.sessionId &&
          other.sessionType == this.sessionType &&
          other.selectedAnswerId == this.selectedAnswerId &&
          other.isCorrect == this.isCorrect &&
          other.answeredAt == this.answeredAt &&
          other.contentVersion == this.contentVersion &&
          other.questionVersion == this.questionVersion &&
          other.correctAnswerId == this.correctAnswerId &&
          other.explanation == this.explanation);
}

class AnswerAttemptsCompanion extends UpdateCompanion<AnswerAttemptRow> {
  final Value<bool?> confident;
  final Value<int?> activeDurationSeconds;
  final Value<String?> localAnsweredDate;
  final Value<String> id;
  final Value<String> examId;
  final Value<String> questionId;
  final Value<String> domainId;
  final Value<String> topicId;
  final Value<int> difficulty;
  final Value<String> sessionId;
  final Value<String> sessionType;
  final Value<String> selectedAnswerId;
  final Value<bool> isCorrect;
  final Value<DateTime> answeredAt;
  final Value<String?> contentVersion;
  final Value<int?> questionVersion;
  final Value<String?> correctAnswerId;
  final Value<String?> explanation;
  final Value<int> rowid;
  const AnswerAttemptsCompanion({
    this.confident = const Value.absent(),
    this.activeDurationSeconds = const Value.absent(),
    this.localAnsweredDate = const Value.absent(),
    this.id = const Value.absent(),
    this.examId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.domainId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.selectedAnswerId = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.questionVersion = const Value.absent(),
    this.correctAnswerId = const Value.absent(),
    this.explanation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnswerAttemptsCompanion.insert({
    this.confident = const Value.absent(),
    this.activeDurationSeconds = const Value.absent(),
    this.localAnsweredDate = const Value.absent(),
    required String id,
    required String examId,
    required String questionId,
    required String domainId,
    required String topicId,
    required int difficulty,
    required String sessionId,
    required String sessionType,
    required String selectedAnswerId,
    required bool isCorrect,
    required DateTime answeredAt,
    this.contentVersion = const Value.absent(),
    this.questionVersion = const Value.absent(),
    this.correctAnswerId = const Value.absent(),
    this.explanation = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        examId = Value(examId),
        questionId = Value(questionId),
        domainId = Value(domainId),
        topicId = Value(topicId),
        difficulty = Value(difficulty),
        sessionId = Value(sessionId),
        sessionType = Value(sessionType),
        selectedAnswerId = Value(selectedAnswerId),
        isCorrect = Value(isCorrect),
        answeredAt = Value(answeredAt);
  static Insertable<AnswerAttemptRow> custom({
    Expression<bool>? confident,
    Expression<int>? activeDurationSeconds,
    Expression<String>? localAnsweredDate,
    Expression<String>? id,
    Expression<String>? examId,
    Expression<String>? questionId,
    Expression<String>? domainId,
    Expression<String>? topicId,
    Expression<int>? difficulty,
    Expression<String>? sessionId,
    Expression<String>? sessionType,
    Expression<String>? selectedAnswerId,
    Expression<bool>? isCorrect,
    Expression<DateTime>? answeredAt,
    Expression<String>? contentVersion,
    Expression<int>? questionVersion,
    Expression<String>? correctAnswerId,
    Expression<String>? explanation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (confident != null) 'confident': confident,
      if (activeDurationSeconds != null)
        'active_duration_seconds': activeDurationSeconds,
      if (localAnsweredDate != null) 'local_answered_date': localAnsweredDate,
      if (id != null) 'id': id,
      if (examId != null) 'exam_id': examId,
      if (questionId != null) 'question_id': questionId,
      if (domainId != null) 'domain_id': domainId,
      if (topicId != null) 'topic_id': topicId,
      if (difficulty != null) 'difficulty': difficulty,
      if (sessionId != null) 'session_id': sessionId,
      if (sessionType != null) 'session_type': sessionType,
      if (selectedAnswerId != null) 'selected_answer_id': selectedAnswerId,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (contentVersion != null) 'content_version': contentVersion,
      if (questionVersion != null) 'question_version': questionVersion,
      if (correctAnswerId != null) 'correct_answer_id': correctAnswerId,
      if (explanation != null) 'explanation': explanation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnswerAttemptsCompanion copyWith(
      {Value<bool?>? confident,
      Value<int?>? activeDurationSeconds,
      Value<String?>? localAnsweredDate,
      Value<String>? id,
      Value<String>? examId,
      Value<String>? questionId,
      Value<String>? domainId,
      Value<String>? topicId,
      Value<int>? difficulty,
      Value<String>? sessionId,
      Value<String>? sessionType,
      Value<String>? selectedAnswerId,
      Value<bool>? isCorrect,
      Value<DateTime>? answeredAt,
      Value<String?>? contentVersion,
      Value<int?>? questionVersion,
      Value<String?>? correctAnswerId,
      Value<String?>? explanation,
      Value<int>? rowid}) {
    return AnswerAttemptsCompanion(
      confident: confident ?? this.confident,
      activeDurationSeconds:
          activeDurationSeconds ?? this.activeDurationSeconds,
      localAnsweredDate: localAnsweredDate ?? this.localAnsweredDate,
      id: id ?? this.id,
      examId: examId ?? this.examId,
      questionId: questionId ?? this.questionId,
      domainId: domainId ?? this.domainId,
      topicId: topicId ?? this.topicId,
      difficulty: difficulty ?? this.difficulty,
      sessionId: sessionId ?? this.sessionId,
      sessionType: sessionType ?? this.sessionType,
      selectedAnswerId: selectedAnswerId ?? this.selectedAnswerId,
      isCorrect: isCorrect ?? this.isCorrect,
      answeredAt: answeredAt ?? this.answeredAt,
      contentVersion: contentVersion ?? this.contentVersion,
      questionVersion: questionVersion ?? this.questionVersion,
      correctAnswerId: correctAnswerId ?? this.correctAnswerId,
      explanation: explanation ?? this.explanation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (confident.present) {
      map['confident'] = Variable<bool>(confident.value);
    }
    if (activeDurationSeconds.present) {
      map['active_duration_seconds'] =
          Variable<int>(activeDurationSeconds.value);
    }
    if (localAnsweredDate.present) {
      map['local_answered_date'] = Variable<String>(localAnsweredDate.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (domainId.present) {
      map['domain_id'] = Variable<String>(domainId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (selectedAnswerId.present) {
      map['selected_answer_id'] = Variable<String>(selectedAnswerId.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (questionVersion.present) {
      map['question_version'] = Variable<int>(questionVersion.value);
    }
    if (correctAnswerId.present) {
      map['correct_answer_id'] = Variable<String>(correctAnswerId.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnswerAttemptsCompanion(')
          ..write('confident: $confident, ')
          ..write('activeDurationSeconds: $activeDurationSeconds, ')
          ..write('localAnsweredDate: $localAnsweredDate, ')
          ..write('id: $id, ')
          ..write('examId: $examId, ')
          ..write('questionId: $questionId, ')
          ..write('domainId: $domainId, ')
          ..write('topicId: $topicId, ')
          ..write('difficulty: $difficulty, ')
          ..write('sessionId: $sessionId, ')
          ..write('sessionType: $sessionType, ')
          ..write('selectedAnswerId: $selectedAnswerId, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('questionVersion: $questionVersion, ')
          ..write('correctAnswerId: $correctAnswerId, ')
          ..write('explanation: $explanation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionStatesTable extends QuestionStates
    with TableInfo<$QuestionStatesTable, QuestionStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
      'exam_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookmarkedMeta =
      const VerificationMeta('bookmarked');
  @override
  late final GeneratedColumn<bool> bookmarked = GeneratedColumn<bool>(
      'bookmarked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("bookmarked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _timesSeenMeta =
      const VerificationMeta('timesSeen');
  @override
  late final GeneratedColumn<int> timesSeen = GeneratedColumn<int>(
      'times_seen', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _timesCorrectMeta =
      const VerificationMeta('timesCorrect');
  @override
  late final GeneratedColumn<int> timesCorrect = GeneratedColumn<int>(
      'times_correct', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _timesIncorrectMeta =
      const VerificationMeta('timesIncorrect');
  @override
  late final GeneratedColumn<int> timesIncorrect = GeneratedColumn<int>(
      'times_incorrect', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _consecutiveCorrectMeta =
      const VerificationMeta('consecutiveCorrect');
  @override
  late final GeneratedColumn<int> consecutiveCorrect = GeneratedColumn<int>(
      'consecutive_correct', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastAnsweredAtMeta =
      const VerificationMeta('lastAnsweredAt');
  @override
  late final GeneratedColumn<DateTime> lastAnsweredAt =
      GeneratedColumn<DateTime>('last_answered_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        examId,
        questionId,
        bookmarked,
        timesSeen,
        timesCorrect,
        timesIncorrect,
        consecutiveCorrect,
        lastAnsweredAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_states';
  @override
  VerificationContext validateIntegrity(Insertable<QuestionStateRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exam_id')) {
      context.handle(_examIdMeta,
          examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta));
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('bookmarked')) {
      context.handle(
          _bookmarkedMeta,
          bookmarked.isAcceptableOrUnknown(
              data['bookmarked']!, _bookmarkedMeta));
    }
    if (data.containsKey('times_seen')) {
      context.handle(_timesSeenMeta,
          timesSeen.isAcceptableOrUnknown(data['times_seen']!, _timesSeenMeta));
    }
    if (data.containsKey('times_correct')) {
      context.handle(
          _timesCorrectMeta,
          timesCorrect.isAcceptableOrUnknown(
              data['times_correct']!, _timesCorrectMeta));
    }
    if (data.containsKey('times_incorrect')) {
      context.handle(
          _timesIncorrectMeta,
          timesIncorrect.isAcceptableOrUnknown(
              data['times_incorrect']!, _timesIncorrectMeta));
    }
    if (data.containsKey('consecutive_correct')) {
      context.handle(
          _consecutiveCorrectMeta,
          consecutiveCorrect.isAcceptableOrUnknown(
              data['consecutive_correct']!, _consecutiveCorrectMeta));
    }
    if (data.containsKey('last_answered_at')) {
      context.handle(
          _lastAnsweredAtMeta,
          lastAnsweredAt.isAcceptableOrUnknown(
              data['last_answered_at']!, _lastAnsweredAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {examId, questionId};
  @override
  QuestionStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionStateRow(
      examId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exam_id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      bookmarked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}bookmarked'])!,
      timesSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}times_seen'])!,
      timesCorrect: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}times_correct'])!,
      timesIncorrect: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}times_incorrect'])!,
      consecutiveCorrect: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}consecutive_correct'])!,
      lastAnsweredAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_answered_at']),
    );
  }

  @override
  $QuestionStatesTable createAlias(String alias) {
    return $QuestionStatesTable(attachedDatabase, alias);
  }
}

class QuestionStateRow extends DataClass
    implements Insertable<QuestionStateRow> {
  final String examId;
  final String questionId;
  final bool bookmarked;
  final int timesSeen;
  final int timesCorrect;
  final int timesIncorrect;
  final int consecutiveCorrect;
  final DateTime? lastAnsweredAt;
  const QuestionStateRow(
      {required this.examId,
      required this.questionId,
      required this.bookmarked,
      required this.timesSeen,
      required this.timesCorrect,
      required this.timesIncorrect,
      required this.consecutiveCorrect,
      this.lastAnsweredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exam_id'] = Variable<String>(examId);
    map['question_id'] = Variable<String>(questionId);
    map['bookmarked'] = Variable<bool>(bookmarked);
    map['times_seen'] = Variable<int>(timesSeen);
    map['times_correct'] = Variable<int>(timesCorrect);
    map['times_incorrect'] = Variable<int>(timesIncorrect);
    map['consecutive_correct'] = Variable<int>(consecutiveCorrect);
    if (!nullToAbsent || lastAnsweredAt != null) {
      map['last_answered_at'] = Variable<DateTime>(lastAnsweredAt);
    }
    return map;
  }

  QuestionStatesCompanion toCompanion(bool nullToAbsent) {
    return QuestionStatesCompanion(
      examId: Value(examId),
      questionId: Value(questionId),
      bookmarked: Value(bookmarked),
      timesSeen: Value(timesSeen),
      timesCorrect: Value(timesCorrect),
      timesIncorrect: Value(timesIncorrect),
      consecutiveCorrect: Value(consecutiveCorrect),
      lastAnsweredAt: lastAnsweredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAnsweredAt),
    );
  }

  factory QuestionStateRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionStateRow(
      examId: serializer.fromJson<String>(json['examId']),
      questionId: serializer.fromJson<String>(json['questionId']),
      bookmarked: serializer.fromJson<bool>(json['bookmarked']),
      timesSeen: serializer.fromJson<int>(json['timesSeen']),
      timesCorrect: serializer.fromJson<int>(json['timesCorrect']),
      timesIncorrect: serializer.fromJson<int>(json['timesIncorrect']),
      consecutiveCorrect: serializer.fromJson<int>(json['consecutiveCorrect']),
      lastAnsweredAt: serializer.fromJson<DateTime?>(json['lastAnsweredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'examId': serializer.toJson<String>(examId),
      'questionId': serializer.toJson<String>(questionId),
      'bookmarked': serializer.toJson<bool>(bookmarked),
      'timesSeen': serializer.toJson<int>(timesSeen),
      'timesCorrect': serializer.toJson<int>(timesCorrect),
      'timesIncorrect': serializer.toJson<int>(timesIncorrect),
      'consecutiveCorrect': serializer.toJson<int>(consecutiveCorrect),
      'lastAnsweredAt': serializer.toJson<DateTime?>(lastAnsweredAt),
    };
  }

  QuestionStateRow copyWith(
          {String? examId,
          String? questionId,
          bool? bookmarked,
          int? timesSeen,
          int? timesCorrect,
          int? timesIncorrect,
          int? consecutiveCorrect,
          Value<DateTime?> lastAnsweredAt = const Value.absent()}) =>
      QuestionStateRow(
        examId: examId ?? this.examId,
        questionId: questionId ?? this.questionId,
        bookmarked: bookmarked ?? this.bookmarked,
        timesSeen: timesSeen ?? this.timesSeen,
        timesCorrect: timesCorrect ?? this.timesCorrect,
        timesIncorrect: timesIncorrect ?? this.timesIncorrect,
        consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
        lastAnsweredAt:
            lastAnsweredAt.present ? lastAnsweredAt.value : this.lastAnsweredAt,
      );
  QuestionStateRow copyWithCompanion(QuestionStatesCompanion data) {
    return QuestionStateRow(
      examId: data.examId.present ? data.examId.value : this.examId,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      bookmarked:
          data.bookmarked.present ? data.bookmarked.value : this.bookmarked,
      timesSeen: data.timesSeen.present ? data.timesSeen.value : this.timesSeen,
      timesCorrect: data.timesCorrect.present
          ? data.timesCorrect.value
          : this.timesCorrect,
      timesIncorrect: data.timesIncorrect.present
          ? data.timesIncorrect.value
          : this.timesIncorrect,
      consecutiveCorrect: data.consecutiveCorrect.present
          ? data.consecutiveCorrect.value
          : this.consecutiveCorrect,
      lastAnsweredAt: data.lastAnsweredAt.present
          ? data.lastAnsweredAt.value
          : this.lastAnsweredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionStateRow(')
          ..write('examId: $examId, ')
          ..write('questionId: $questionId, ')
          ..write('bookmarked: $bookmarked, ')
          ..write('timesSeen: $timesSeen, ')
          ..write('timesCorrect: $timesCorrect, ')
          ..write('timesIncorrect: $timesIncorrect, ')
          ..write('consecutiveCorrect: $consecutiveCorrect, ')
          ..write('lastAnsweredAt: $lastAnsweredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(examId, questionId, bookmarked, timesSeen,
      timesCorrect, timesIncorrect, consecutiveCorrect, lastAnsweredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionStateRow &&
          other.examId == this.examId &&
          other.questionId == this.questionId &&
          other.bookmarked == this.bookmarked &&
          other.timesSeen == this.timesSeen &&
          other.timesCorrect == this.timesCorrect &&
          other.timesIncorrect == this.timesIncorrect &&
          other.consecutiveCorrect == this.consecutiveCorrect &&
          other.lastAnsweredAt == this.lastAnsweredAt);
}

class QuestionStatesCompanion extends UpdateCompanion<QuestionStateRow> {
  final Value<String> examId;
  final Value<String> questionId;
  final Value<bool> bookmarked;
  final Value<int> timesSeen;
  final Value<int> timesCorrect;
  final Value<int> timesIncorrect;
  final Value<int> consecutiveCorrect;
  final Value<DateTime?> lastAnsweredAt;
  final Value<int> rowid;
  const QuestionStatesCompanion({
    this.examId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.bookmarked = const Value.absent(),
    this.timesSeen = const Value.absent(),
    this.timesCorrect = const Value.absent(),
    this.timesIncorrect = const Value.absent(),
    this.consecutiveCorrect = const Value.absent(),
    this.lastAnsweredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionStatesCompanion.insert({
    required String examId,
    required String questionId,
    this.bookmarked = const Value.absent(),
    this.timesSeen = const Value.absent(),
    this.timesCorrect = const Value.absent(),
    this.timesIncorrect = const Value.absent(),
    this.consecutiveCorrect = const Value.absent(),
    this.lastAnsweredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : examId = Value(examId),
        questionId = Value(questionId);
  static Insertable<QuestionStateRow> custom({
    Expression<String>? examId,
    Expression<String>? questionId,
    Expression<bool>? bookmarked,
    Expression<int>? timesSeen,
    Expression<int>? timesCorrect,
    Expression<int>? timesIncorrect,
    Expression<int>? consecutiveCorrect,
    Expression<DateTime>? lastAnsweredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (examId != null) 'exam_id': examId,
      if (questionId != null) 'question_id': questionId,
      if (bookmarked != null) 'bookmarked': bookmarked,
      if (timesSeen != null) 'times_seen': timesSeen,
      if (timesCorrect != null) 'times_correct': timesCorrect,
      if (timesIncorrect != null) 'times_incorrect': timesIncorrect,
      if (consecutiveCorrect != null) 'consecutive_correct': consecutiveCorrect,
      if (lastAnsweredAt != null) 'last_answered_at': lastAnsweredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionStatesCompanion copyWith(
      {Value<String>? examId,
      Value<String>? questionId,
      Value<bool>? bookmarked,
      Value<int>? timesSeen,
      Value<int>? timesCorrect,
      Value<int>? timesIncorrect,
      Value<int>? consecutiveCorrect,
      Value<DateTime?>? lastAnsweredAt,
      Value<int>? rowid}) {
    return QuestionStatesCompanion(
      examId: examId ?? this.examId,
      questionId: questionId ?? this.questionId,
      bookmarked: bookmarked ?? this.bookmarked,
      timesSeen: timesSeen ?? this.timesSeen,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      timesIncorrect: timesIncorrect ?? this.timesIncorrect,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      lastAnsweredAt: lastAnsweredAt ?? this.lastAnsweredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (bookmarked.present) {
      map['bookmarked'] = Variable<bool>(bookmarked.value);
    }
    if (timesSeen.present) {
      map['times_seen'] = Variable<int>(timesSeen.value);
    }
    if (timesCorrect.present) {
      map['times_correct'] = Variable<int>(timesCorrect.value);
    }
    if (timesIncorrect.present) {
      map['times_incorrect'] = Variable<int>(timesIncorrect.value);
    }
    if (consecutiveCorrect.present) {
      map['consecutive_correct'] = Variable<int>(consecutiveCorrect.value);
    }
    if (lastAnsweredAt.present) {
      map['last_answered_at'] = Variable<DateTime>(lastAnsweredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionStatesCompanion(')
          ..write('examId: $examId, ')
          ..write('questionId: $questionId, ')
          ..write('bookmarked: $bookmarked, ')
          ..write('timesSeen: $timesSeen, ')
          ..write('timesCorrect: $timesCorrect, ')
          ..write('timesIncorrect: $timesIncorrect, ')
          ..write('consecutiveCorrect: $consecutiveCorrect, ')
          ..write('lastAnsweredAt: $lastAnsweredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeSessionsTable extends PracticeSessions
    with TableInfo<$PracticeSessionsTable, PracticeSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _planDateMeta =
      const VerificationMeta('planDate');
  @override
  late final GeneratedColumn<String> planDate = GeneratedColumn<String>(
      'plan_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reviewQuestionIdsJsonMeta =
      const VerificationMeta('reviewQuestionIdsJson');
  @override
  late final GeneratedColumn<String> reviewQuestionIdsJson =
      GeneratedColumn<String>('review_question_ids_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
      'exam_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
      'mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionIdsJsonMeta =
      const VerificationMeta('questionIdsJson');
  @override
  late final GeneratedColumn<String> questionIdsJson = GeneratedColumn<String>(
      'question_ids_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answerOrderJsonMeta =
      const VerificationMeta('answerOrderJson');
  @override
  late final GeneratedColumn<String> answerOrderJson = GeneratedColumn<String>(
      'answer_order_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _contentVersionMeta =
      const VerificationMeta('contentVersion');
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
      'content_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        planDate,
        reviewQuestionIdsJson,
        id,
        examId,
        mode,
        questionIdsJson,
        answerOrderJson,
        status,
        startedAt,
        completedAt,
        contentVersion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<PracticeSessionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plan_date')) {
      context.handle(_planDateMeta,
          planDate.isAcceptableOrUnknown(data['plan_date']!, _planDateMeta));
    }
    if (data.containsKey('review_question_ids_json')) {
      context.handle(
          _reviewQuestionIdsJsonMeta,
          reviewQuestionIdsJson.isAcceptableOrUnknown(
              data['review_question_ids_json']!, _reviewQuestionIdsJsonMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(_examIdMeta,
          examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta));
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('question_ids_json')) {
      context.handle(
          _questionIdsJsonMeta,
          questionIdsJson.isAcceptableOrUnknown(
              data['question_ids_json']!, _questionIdsJsonMeta));
    } else if (isInserting) {
      context.missing(_questionIdsJsonMeta);
    }
    if (data.containsKey('answer_order_json')) {
      context.handle(
          _answerOrderJsonMeta,
          answerOrderJson.isAcceptableOrUnknown(
              data['answer_order_json']!, _answerOrderJsonMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('content_version')) {
      context.handle(
          _contentVersionMeta,
          contentVersion.isAcceptableOrUnknown(
              data['content_version']!, _contentVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeSessionRow(
      planDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_date']),
      reviewQuestionIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}review_question_ids_json']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      examId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exam_id'])!,
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!,
      questionIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}question_ids_json'])!,
      answerOrderJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}answer_order_json']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      contentVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_version']),
    );
  }

  @override
  $PracticeSessionsTable createAlias(String alias) {
    return $PracticeSessionsTable(attachedDatabase, alias);
  }
}

class PracticeSessionRow extends DataClass
    implements Insertable<PracticeSessionRow> {
  final String? planDate;
  final String? reviewQuestionIdsJson;
  final String id;
  final String examId;
  final String mode;
  final String questionIdsJson;
  final String? answerOrderJson;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;

  /// Added in schema 2 (PREP-664) — see
  /// [PracticeSession.contentVersion]'s doc comment. Nullable so every
  /// row from schema 1 remains valid after the upgrade, with no value to
  /// backfill it from.
  final String? contentVersion;
  const PracticeSessionRow(
      {this.planDate,
      this.reviewQuestionIdsJson,
      required this.id,
      required this.examId,
      required this.mode,
      required this.questionIdsJson,
      this.answerOrderJson,
      required this.status,
      required this.startedAt,
      this.completedAt,
      this.contentVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || planDate != null) {
      map['plan_date'] = Variable<String>(planDate);
    }
    if (!nullToAbsent || reviewQuestionIdsJson != null) {
      map['review_question_ids_json'] = Variable<String>(reviewQuestionIdsJson);
    }
    map['id'] = Variable<String>(id);
    map['exam_id'] = Variable<String>(examId);
    map['mode'] = Variable<String>(mode);
    map['question_ids_json'] = Variable<String>(questionIdsJson);
    if (!nullToAbsent || answerOrderJson != null) {
      map['answer_order_json'] = Variable<String>(answerOrderJson);
    }
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || contentVersion != null) {
      map['content_version'] = Variable<String>(contentVersion);
    }
    return map;
  }

  PracticeSessionsCompanion toCompanion(bool nullToAbsent) {
    return PracticeSessionsCompanion(
      planDate: planDate == null && nullToAbsent
          ? const Value.absent()
          : Value(planDate),
      reviewQuestionIdsJson: reviewQuestionIdsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewQuestionIdsJson),
      id: Value(id),
      examId: Value(examId),
      mode: Value(mode),
      questionIdsJson: Value(questionIdsJson),
      answerOrderJson: answerOrderJson == null && nullToAbsent
          ? const Value.absent()
          : Value(answerOrderJson),
      status: Value(status),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      contentVersion: contentVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(contentVersion),
    );
  }

  factory PracticeSessionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeSessionRow(
      planDate: serializer.fromJson<String?>(json['planDate']),
      reviewQuestionIdsJson:
          serializer.fromJson<String?>(json['reviewQuestionIdsJson']),
      id: serializer.fromJson<String>(json['id']),
      examId: serializer.fromJson<String>(json['examId']),
      mode: serializer.fromJson<String>(json['mode']),
      questionIdsJson: serializer.fromJson<String>(json['questionIdsJson']),
      answerOrderJson: serializer.fromJson<String?>(json['answerOrderJson']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      contentVersion: serializer.fromJson<String?>(json['contentVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'planDate': serializer.toJson<String?>(planDate),
      'reviewQuestionIdsJson':
          serializer.toJson<String?>(reviewQuestionIdsJson),
      'id': serializer.toJson<String>(id),
      'examId': serializer.toJson<String>(examId),
      'mode': serializer.toJson<String>(mode),
      'questionIdsJson': serializer.toJson<String>(questionIdsJson),
      'answerOrderJson': serializer.toJson<String?>(answerOrderJson),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'contentVersion': serializer.toJson<String?>(contentVersion),
    };
  }

  PracticeSessionRow copyWith(
          {Value<String?> planDate = const Value.absent(),
          Value<String?> reviewQuestionIdsJson = const Value.absent(),
          String? id,
          String? examId,
          String? mode,
          String? questionIdsJson,
          Value<String?> answerOrderJson = const Value.absent(),
          String? status,
          DateTime? startedAt,
          Value<DateTime?> completedAt = const Value.absent(),
          Value<String?> contentVersion = const Value.absent()}) =>
      PracticeSessionRow(
        planDate: planDate.present ? planDate.value : this.planDate,
        reviewQuestionIdsJson: reviewQuestionIdsJson.present
            ? reviewQuestionIdsJson.value
            : this.reviewQuestionIdsJson,
        id: id ?? this.id,
        examId: examId ?? this.examId,
        mode: mode ?? this.mode,
        questionIdsJson: questionIdsJson ?? this.questionIdsJson,
        answerOrderJson: answerOrderJson.present
            ? answerOrderJson.value
            : this.answerOrderJson,
        status: status ?? this.status,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        contentVersion:
            contentVersion.present ? contentVersion.value : this.contentVersion,
      );
  PracticeSessionRow copyWithCompanion(PracticeSessionsCompanion data) {
    return PracticeSessionRow(
      planDate: data.planDate.present ? data.planDate.value : this.planDate,
      reviewQuestionIdsJson: data.reviewQuestionIdsJson.present
          ? data.reviewQuestionIdsJson.value
          : this.reviewQuestionIdsJson,
      id: data.id.present ? data.id.value : this.id,
      examId: data.examId.present ? data.examId.value : this.examId,
      mode: data.mode.present ? data.mode.value : this.mode,
      questionIdsJson: data.questionIdsJson.present
          ? data.questionIdsJson.value
          : this.questionIdsJson,
      answerOrderJson: data.answerOrderJson.present
          ? data.answerOrderJson.value
          : this.answerOrderJson,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSessionRow(')
          ..write('planDate: $planDate, ')
          ..write('reviewQuestionIdsJson: $reviewQuestionIdsJson, ')
          ..write('id: $id, ')
          ..write('examId: $examId, ')
          ..write('mode: $mode, ')
          ..write('questionIdsJson: $questionIdsJson, ')
          ..write('answerOrderJson: $answerOrderJson, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('contentVersion: $contentVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      planDate,
      reviewQuestionIdsJson,
      id,
      examId,
      mode,
      questionIdsJson,
      answerOrderJson,
      status,
      startedAt,
      completedAt,
      contentVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeSessionRow &&
          other.planDate == this.planDate &&
          other.reviewQuestionIdsJson == this.reviewQuestionIdsJson &&
          other.id == this.id &&
          other.examId == this.examId &&
          other.mode == this.mode &&
          other.questionIdsJson == this.questionIdsJson &&
          other.answerOrderJson == this.answerOrderJson &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.contentVersion == this.contentVersion);
}

class PracticeSessionsCompanion extends UpdateCompanion<PracticeSessionRow> {
  final Value<String?> planDate;
  final Value<String?> reviewQuestionIdsJson;
  final Value<String> id;
  final Value<String> examId;
  final Value<String> mode;
  final Value<String> questionIdsJson;
  final Value<String?> answerOrderJson;
  final Value<String> status;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> contentVersion;
  final Value<int> rowid;
  const PracticeSessionsCompanion({
    this.planDate = const Value.absent(),
    this.reviewQuestionIdsJson = const Value.absent(),
    this.id = const Value.absent(),
    this.examId = const Value.absent(),
    this.mode = const Value.absent(),
    this.questionIdsJson = const Value.absent(),
    this.answerOrderJson = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeSessionsCompanion.insert({
    this.planDate = const Value.absent(),
    this.reviewQuestionIdsJson = const Value.absent(),
    required String id,
    required String examId,
    required String mode,
    required String questionIdsJson,
    this.answerOrderJson = const Value.absent(),
    required String status,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        examId = Value(examId),
        mode = Value(mode),
        questionIdsJson = Value(questionIdsJson),
        status = Value(status),
        startedAt = Value(startedAt);
  static Insertable<PracticeSessionRow> custom({
    Expression<String>? planDate,
    Expression<String>? reviewQuestionIdsJson,
    Expression<String>? id,
    Expression<String>? examId,
    Expression<String>? mode,
    Expression<String>? questionIdsJson,
    Expression<String>? answerOrderJson,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? contentVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (planDate != null) 'plan_date': planDate,
      if (reviewQuestionIdsJson != null)
        'review_question_ids_json': reviewQuestionIdsJson,
      if (id != null) 'id': id,
      if (examId != null) 'exam_id': examId,
      if (mode != null) 'mode': mode,
      if (questionIdsJson != null) 'question_ids_json': questionIdsJson,
      if (answerOrderJson != null) 'answer_order_json': answerOrderJson,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (contentVersion != null) 'content_version': contentVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeSessionsCompanion copyWith(
      {Value<String?>? planDate,
      Value<String?>? reviewQuestionIdsJson,
      Value<String>? id,
      Value<String>? examId,
      Value<String>? mode,
      Value<String>? questionIdsJson,
      Value<String?>? answerOrderJson,
      Value<String>? status,
      Value<DateTime>? startedAt,
      Value<DateTime?>? completedAt,
      Value<String?>? contentVersion,
      Value<int>? rowid}) {
    return PracticeSessionsCompanion(
      planDate: planDate ?? this.planDate,
      reviewQuestionIdsJson:
          reviewQuestionIdsJson ?? this.reviewQuestionIdsJson,
      id: id ?? this.id,
      examId: examId ?? this.examId,
      mode: mode ?? this.mode,
      questionIdsJson: questionIdsJson ?? this.questionIdsJson,
      answerOrderJson: answerOrderJson ?? this.answerOrderJson,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      contentVersion: contentVersion ?? this.contentVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (planDate.present) {
      map['plan_date'] = Variable<String>(planDate.value);
    }
    if (reviewQuestionIdsJson.present) {
      map['review_question_ids_json'] =
          Variable<String>(reviewQuestionIdsJson.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (questionIdsJson.present) {
      map['question_ids_json'] = Variable<String>(questionIdsJson.value);
    }
    if (answerOrderJson.present) {
      map['answer_order_json'] = Variable<String>(answerOrderJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSessionsCompanion(')
          ..write('planDate: $planDate, ')
          ..write('reviewQuestionIdsJson: $reviewQuestionIdsJson, ')
          ..write('id: $id, ')
          ..write('examId: $examId, ')
          ..write('mode: $mode, ')
          ..write('questionIdsJson: $questionIdsJson, ')
          ..write('answerOrderJson: $answerOrderJson, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MockAttemptsTable extends MockAttempts
    with TableInfo<$MockAttemptsTable, MockAttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MockAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seenBeforeStartCountMeta =
      const VerificationMeta('seenBeforeStartCount');
  @override
  late final GeneratedColumn<int> seenBeforeStartCount = GeneratedColumn<int>(
      'seen_before_start_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
      'exam_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionIdsJsonMeta =
      const VerificationMeta('questionIdsJson');
  @override
  late final GeneratedColumn<String> questionIdsJson = GeneratedColumn<String>(
      'question_ids_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answerOrderJsonMeta =
      const VerificationMeta('answerOrderJson');
  @override
  late final GeneratedColumn<String> answerOrderJson = GeneratedColumn<String>(
      'answer_order_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _answersJsonMeta =
      const VerificationMeta('answersJson');
  @override
  late final GeneratedColumn<String> answersJson = GeneratedColumn<String>(
      'answers_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _flaggedQuestionIdsJsonMeta =
      const VerificationMeta('flaggedQuestionIdsJson');
  @override
  late final GeneratedColumn<String> flaggedQuestionIdsJson =
      GeneratedColumn<String>('flagged_question_ids_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currentQuestionIndexMeta =
      const VerificationMeta('currentQuestionIndex');
  @override
  late final GeneratedColumn<int> currentQuestionIndex = GeneratedColumn<int>(
      'current_question_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _contentVersionMeta =
      const VerificationMeta('contentVersion');
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
      'content_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _correctCountMeta =
      const VerificationMeta('correctCount');
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
      'correct_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        seenBeforeStartCount,
        id,
        examId,
        questionIdsJson,
        answerOrderJson,
        answersJson,
        flaggedQuestionIdsJson,
        status,
        startedAt,
        durationMinutes,
        currentQuestionIndex,
        contentVersion,
        completedAt,
        correctCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mock_attempts';
  @override
  VerificationContext validateIntegrity(Insertable<MockAttemptRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seen_before_start_count')) {
      context.handle(
          _seenBeforeStartCountMeta,
          seenBeforeStartCount.isAcceptableOrUnknown(
              data['seen_before_start_count']!, _seenBeforeStartCountMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(_examIdMeta,
          examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta));
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('question_ids_json')) {
      context.handle(
          _questionIdsJsonMeta,
          questionIdsJson.isAcceptableOrUnknown(
              data['question_ids_json']!, _questionIdsJsonMeta));
    } else if (isInserting) {
      context.missing(_questionIdsJsonMeta);
    }
    if (data.containsKey('answer_order_json')) {
      context.handle(
          _answerOrderJsonMeta,
          answerOrderJson.isAcceptableOrUnknown(
              data['answer_order_json']!, _answerOrderJsonMeta));
    }
    if (data.containsKey('answers_json')) {
      context.handle(
          _answersJsonMeta,
          answersJson.isAcceptableOrUnknown(
              data['answers_json']!, _answersJsonMeta));
    } else if (isInserting) {
      context.missing(_answersJsonMeta);
    }
    if (data.containsKey('flagged_question_ids_json')) {
      context.handle(
          _flaggedQuestionIdsJsonMeta,
          flaggedQuestionIdsJson.isAcceptableOrUnknown(
              data['flagged_question_ids_json']!, _flaggedQuestionIdsJsonMeta));
    } else if (isInserting) {
      context.missing(_flaggedQuestionIdsJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('current_question_index')) {
      context.handle(
          _currentQuestionIndexMeta,
          currentQuestionIndex.isAcceptableOrUnknown(
              data['current_question_index']!, _currentQuestionIndexMeta));
    }
    if (data.containsKey('content_version')) {
      context.handle(
          _contentVersionMeta,
          contentVersion.isAcceptableOrUnknown(
              data['content_version']!, _contentVersionMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('correct_count')) {
      context.handle(
          _correctCountMeta,
          correctCount.isAcceptableOrUnknown(
              data['correct_count']!, _correctCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MockAttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MockAttemptRow(
      seenBeforeStartCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}seen_before_start_count']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      examId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exam_id'])!,
      questionIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}question_ids_json'])!,
      answerOrderJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}answer_order_json']),
      answersJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answers_json'])!,
      flaggedQuestionIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}flagged_question_ids_json'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes'])!,
      currentQuestionIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_question_index'])!,
      contentVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_version']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      correctCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_count']),
    );
  }

  @override
  $MockAttemptsTable createAlias(String alias) {
    return $MockAttemptsTable(attachedDatabase, alias);
  }
}

class MockAttemptRow extends DataClass implements Insertable<MockAttemptRow> {
  final int? seenBeforeStartCount;
  final String id;
  final String examId;
  final String questionIdsJson;
  final String? answerOrderJson;
  final String answersJson;
  final String flaggedQuestionIdsJson;
  final String status;
  final DateTime startedAt;
  final int durationMinutes;
  final int currentQuestionIndex;
  final String? contentVersion;
  final DateTime? completedAt;
  final int? correctCount;
  const MockAttemptRow(
      {this.seenBeforeStartCount,
      required this.id,
      required this.examId,
      required this.questionIdsJson,
      this.answerOrderJson,
      required this.answersJson,
      required this.flaggedQuestionIdsJson,
      required this.status,
      required this.startedAt,
      required this.durationMinutes,
      required this.currentQuestionIndex,
      this.contentVersion,
      this.completedAt,
      this.correctCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || seenBeforeStartCount != null) {
      map['seen_before_start_count'] = Variable<int>(seenBeforeStartCount);
    }
    map['id'] = Variable<String>(id);
    map['exam_id'] = Variable<String>(examId);
    map['question_ids_json'] = Variable<String>(questionIdsJson);
    if (!nullToAbsent || answerOrderJson != null) {
      map['answer_order_json'] = Variable<String>(answerOrderJson);
    }
    map['answers_json'] = Variable<String>(answersJson);
    map['flagged_question_ids_json'] = Variable<String>(flaggedQuestionIdsJson);
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['current_question_index'] = Variable<int>(currentQuestionIndex);
    if (!nullToAbsent || contentVersion != null) {
      map['content_version'] = Variable<String>(contentVersion);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || correctCount != null) {
      map['correct_count'] = Variable<int>(correctCount);
    }
    return map;
  }

  MockAttemptsCompanion toCompanion(bool nullToAbsent) {
    return MockAttemptsCompanion(
      seenBeforeStartCount: seenBeforeStartCount == null && nullToAbsent
          ? const Value.absent()
          : Value(seenBeforeStartCount),
      id: Value(id),
      examId: Value(examId),
      questionIdsJson: Value(questionIdsJson),
      answerOrderJson: answerOrderJson == null && nullToAbsent
          ? const Value.absent()
          : Value(answerOrderJson),
      answersJson: Value(answersJson),
      flaggedQuestionIdsJson: Value(flaggedQuestionIdsJson),
      status: Value(status),
      startedAt: Value(startedAt),
      durationMinutes: Value(durationMinutes),
      currentQuestionIndex: Value(currentQuestionIndex),
      contentVersion: contentVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(contentVersion),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      correctCount: correctCount == null && nullToAbsent
          ? const Value.absent()
          : Value(correctCount),
    );
  }

  factory MockAttemptRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MockAttemptRow(
      seenBeforeStartCount:
          serializer.fromJson<int?>(json['seenBeforeStartCount']),
      id: serializer.fromJson<String>(json['id']),
      examId: serializer.fromJson<String>(json['examId']),
      questionIdsJson: serializer.fromJson<String>(json['questionIdsJson']),
      answerOrderJson: serializer.fromJson<String?>(json['answerOrderJson']),
      answersJson: serializer.fromJson<String>(json['answersJson']),
      flaggedQuestionIdsJson:
          serializer.fromJson<String>(json['flaggedQuestionIdsJson']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      currentQuestionIndex:
          serializer.fromJson<int>(json['currentQuestionIndex']),
      contentVersion: serializer.fromJson<String?>(json['contentVersion']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      correctCount: serializer.fromJson<int?>(json['correctCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seenBeforeStartCount': serializer.toJson<int?>(seenBeforeStartCount),
      'id': serializer.toJson<String>(id),
      'examId': serializer.toJson<String>(examId),
      'questionIdsJson': serializer.toJson<String>(questionIdsJson),
      'answerOrderJson': serializer.toJson<String?>(answerOrderJson),
      'answersJson': serializer.toJson<String>(answersJson),
      'flaggedQuestionIdsJson':
          serializer.toJson<String>(flaggedQuestionIdsJson),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'currentQuestionIndex': serializer.toJson<int>(currentQuestionIndex),
      'contentVersion': serializer.toJson<String?>(contentVersion),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'correctCount': serializer.toJson<int?>(correctCount),
    };
  }

  MockAttemptRow copyWith(
          {Value<int?> seenBeforeStartCount = const Value.absent(),
          String? id,
          String? examId,
          String? questionIdsJson,
          Value<String?> answerOrderJson = const Value.absent(),
          String? answersJson,
          String? flaggedQuestionIdsJson,
          String? status,
          DateTime? startedAt,
          int? durationMinutes,
          int? currentQuestionIndex,
          Value<String?> contentVersion = const Value.absent(),
          Value<DateTime?> completedAt = const Value.absent(),
          Value<int?> correctCount = const Value.absent()}) =>
      MockAttemptRow(
        seenBeforeStartCount: seenBeforeStartCount.present
            ? seenBeforeStartCount.value
            : this.seenBeforeStartCount,
        id: id ?? this.id,
        examId: examId ?? this.examId,
        questionIdsJson: questionIdsJson ?? this.questionIdsJson,
        answerOrderJson: answerOrderJson.present
            ? answerOrderJson.value
            : this.answerOrderJson,
        answersJson: answersJson ?? this.answersJson,
        flaggedQuestionIdsJson:
            flaggedQuestionIdsJson ?? this.flaggedQuestionIdsJson,
        status: status ?? this.status,
        startedAt: startedAt ?? this.startedAt,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
        contentVersion:
            contentVersion.present ? contentVersion.value : this.contentVersion,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        correctCount:
            correctCount.present ? correctCount.value : this.correctCount,
      );
  MockAttemptRow copyWithCompanion(MockAttemptsCompanion data) {
    return MockAttemptRow(
      seenBeforeStartCount: data.seenBeforeStartCount.present
          ? data.seenBeforeStartCount.value
          : this.seenBeforeStartCount,
      id: data.id.present ? data.id.value : this.id,
      examId: data.examId.present ? data.examId.value : this.examId,
      questionIdsJson: data.questionIdsJson.present
          ? data.questionIdsJson.value
          : this.questionIdsJson,
      answerOrderJson: data.answerOrderJson.present
          ? data.answerOrderJson.value
          : this.answerOrderJson,
      answersJson:
          data.answersJson.present ? data.answersJson.value : this.answersJson,
      flaggedQuestionIdsJson: data.flaggedQuestionIdsJson.present
          ? data.flaggedQuestionIdsJson.value
          : this.flaggedQuestionIdsJson,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      currentQuestionIndex: data.currentQuestionIndex.present
          ? data.currentQuestionIndex.value
          : this.currentQuestionIndex,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MockAttemptRow(')
          ..write('seenBeforeStartCount: $seenBeforeStartCount, ')
          ..write('id: $id, ')
          ..write('examId: $examId, ')
          ..write('questionIdsJson: $questionIdsJson, ')
          ..write('answerOrderJson: $answerOrderJson, ')
          ..write('answersJson: $answersJson, ')
          ..write('flaggedQuestionIdsJson: $flaggedQuestionIdsJson, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('currentQuestionIndex: $currentQuestionIndex, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('completedAt: $completedAt, ')
          ..write('correctCount: $correctCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      seenBeforeStartCount,
      id,
      examId,
      questionIdsJson,
      answerOrderJson,
      answersJson,
      flaggedQuestionIdsJson,
      status,
      startedAt,
      durationMinutes,
      currentQuestionIndex,
      contentVersion,
      completedAt,
      correctCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MockAttemptRow &&
          other.seenBeforeStartCount == this.seenBeforeStartCount &&
          other.id == this.id &&
          other.examId == this.examId &&
          other.questionIdsJson == this.questionIdsJson &&
          other.answerOrderJson == this.answerOrderJson &&
          other.answersJson == this.answersJson &&
          other.flaggedQuestionIdsJson == this.flaggedQuestionIdsJson &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.durationMinutes == this.durationMinutes &&
          other.currentQuestionIndex == this.currentQuestionIndex &&
          other.contentVersion == this.contentVersion &&
          other.completedAt == this.completedAt &&
          other.correctCount == this.correctCount);
}

class MockAttemptsCompanion extends UpdateCompanion<MockAttemptRow> {
  final Value<int?> seenBeforeStartCount;
  final Value<String> id;
  final Value<String> examId;
  final Value<String> questionIdsJson;
  final Value<String?> answerOrderJson;
  final Value<String> answersJson;
  final Value<String> flaggedQuestionIdsJson;
  final Value<String> status;
  final Value<DateTime> startedAt;
  final Value<int> durationMinutes;
  final Value<int> currentQuestionIndex;
  final Value<String?> contentVersion;
  final Value<DateTime?> completedAt;
  final Value<int?> correctCount;
  final Value<int> rowid;
  const MockAttemptsCompanion({
    this.seenBeforeStartCount = const Value.absent(),
    this.id = const Value.absent(),
    this.examId = const Value.absent(),
    this.questionIdsJson = const Value.absent(),
    this.answerOrderJson = const Value.absent(),
    this.answersJson = const Value.absent(),
    this.flaggedQuestionIdsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.currentQuestionIndex = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MockAttemptsCompanion.insert({
    this.seenBeforeStartCount = const Value.absent(),
    required String id,
    required String examId,
    required String questionIdsJson,
    this.answerOrderJson = const Value.absent(),
    required String answersJson,
    required String flaggedQuestionIdsJson,
    required String status,
    required DateTime startedAt,
    required int durationMinutes,
    this.currentQuestionIndex = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        examId = Value(examId),
        questionIdsJson = Value(questionIdsJson),
        answersJson = Value(answersJson),
        flaggedQuestionIdsJson = Value(flaggedQuestionIdsJson),
        status = Value(status),
        startedAt = Value(startedAt),
        durationMinutes = Value(durationMinutes);
  static Insertable<MockAttemptRow> custom({
    Expression<int>? seenBeforeStartCount,
    Expression<String>? id,
    Expression<String>? examId,
    Expression<String>? questionIdsJson,
    Expression<String>? answerOrderJson,
    Expression<String>? answersJson,
    Expression<String>? flaggedQuestionIdsJson,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<int>? durationMinutes,
    Expression<int>? currentQuestionIndex,
    Expression<String>? contentVersion,
    Expression<DateTime>? completedAt,
    Expression<int>? correctCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (seenBeforeStartCount != null)
        'seen_before_start_count': seenBeforeStartCount,
      if (id != null) 'id': id,
      if (examId != null) 'exam_id': examId,
      if (questionIdsJson != null) 'question_ids_json': questionIdsJson,
      if (answerOrderJson != null) 'answer_order_json': answerOrderJson,
      if (answersJson != null) 'answers_json': answersJson,
      if (flaggedQuestionIdsJson != null)
        'flagged_question_ids_json': flaggedQuestionIdsJson,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (currentQuestionIndex != null)
        'current_question_index': currentQuestionIndex,
      if (contentVersion != null) 'content_version': contentVersion,
      if (completedAt != null) 'completed_at': completedAt,
      if (correctCount != null) 'correct_count': correctCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MockAttemptsCompanion copyWith(
      {Value<int?>? seenBeforeStartCount,
      Value<String>? id,
      Value<String>? examId,
      Value<String>? questionIdsJson,
      Value<String?>? answerOrderJson,
      Value<String>? answersJson,
      Value<String>? flaggedQuestionIdsJson,
      Value<String>? status,
      Value<DateTime>? startedAt,
      Value<int>? durationMinutes,
      Value<int>? currentQuestionIndex,
      Value<String?>? contentVersion,
      Value<DateTime?>? completedAt,
      Value<int?>? correctCount,
      Value<int>? rowid}) {
    return MockAttemptsCompanion(
      seenBeforeStartCount: seenBeforeStartCount ?? this.seenBeforeStartCount,
      id: id ?? this.id,
      examId: examId ?? this.examId,
      questionIdsJson: questionIdsJson ?? this.questionIdsJson,
      answerOrderJson: answerOrderJson ?? this.answerOrderJson,
      answersJson: answersJson ?? this.answersJson,
      flaggedQuestionIdsJson:
          flaggedQuestionIdsJson ?? this.flaggedQuestionIdsJson,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      contentVersion: contentVersion ?? this.contentVersion,
      completedAt: completedAt ?? this.completedAt,
      correctCount: correctCount ?? this.correctCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seenBeforeStartCount.present) {
      map['seen_before_start_count'] =
          Variable<int>(seenBeforeStartCount.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (questionIdsJson.present) {
      map['question_ids_json'] = Variable<String>(questionIdsJson.value);
    }
    if (answerOrderJson.present) {
      map['answer_order_json'] = Variable<String>(answerOrderJson.value);
    }
    if (answersJson.present) {
      map['answers_json'] = Variable<String>(answersJson.value);
    }
    if (flaggedQuestionIdsJson.present) {
      map['flagged_question_ids_json'] =
          Variable<String>(flaggedQuestionIdsJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (currentQuestionIndex.present) {
      map['current_question_index'] = Variable<int>(currentQuestionIndex.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MockAttemptsCompanion(')
          ..write('seenBeforeStartCount: $seenBeforeStartCount, ')
          ..write('id: $id, ')
          ..write('examId: $examId, ')
          ..write('questionIdsJson: $questionIdsJson, ')
          ..write('answerOrderJson: $answerOrderJson, ')
          ..write('answersJson: $answersJson, ')
          ..write('flaggedQuestionIdsJson: $flaggedQuestionIdsJson, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('currentQuestionIndex: $currentQuestionIndex, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('completedAt: $completedAt, ')
          ..write('correctCount: $correctCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadinessSnapshotsTable extends ReadinessSnapshots
    with TableInfo<$ReadinessSnapshotsTable, ReadinessSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadinessSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
      'exam_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _calculatedAtMeta =
      const VerificationMeta('calculatedAt');
  @override
  late final GeneratedColumn<DateTime> calculatedAt = GeneratedColumn<DateTime>(
      'calculated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _overallScoreMeta =
      const VerificationMeta('overallScore');
  @override
  late final GeneratedColumn<double> overallScore = GeneratedColumn<double>(
      'overall_score', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _bandMeta = const VerificationMeta('band');
  @override
  late final GeneratedColumn<String> band = GeneratedColumn<String>(
      'band', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recentAccuracyComponentMeta =
      const VerificationMeta('recentAccuracyComponent');
  @override
  late final GeneratedColumn<double> recentAccuracyComponent =
      GeneratedColumn<double>('recent_accuracy_component', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _domainMasteryComponentMeta =
      const VerificationMeta('domainMasteryComponent');
  @override
  late final GeneratedColumn<double> domainMasteryComponent =
      GeneratedColumn<double>('domain_mastery_component', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _mockPerformanceComponentMeta =
      const VerificationMeta('mockPerformanceComponent');
  @override
  late final GeneratedColumn<double> mockPerformanceComponent =
      GeneratedColumn<double>('mock_performance_component', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _repeatedMasteryComponentMeta =
      const VerificationMeta('repeatedMasteryComponent');
  @override
  late final GeneratedColumn<double> repeatedMasteryComponent =
      GeneratedColumn<double>('repeated_mastery_component', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _coverageComponentMeta =
      const VerificationMeta('coverageComponent');
  @override
  late final GeneratedColumn<double> coverageComponent =
      GeneratedColumn<double>('coverage_component', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _evidenceConfidenceMeta =
      const VerificationMeta('evidenceConfidence');
  @override
  late final GeneratedColumn<double> evidenceConfidence =
      GeneratedColumn<double>('evidence_confidence', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _uniqueQuestionsAnsweredMeta =
      const VerificationMeta('uniqueQuestionsAnswered');
  @override
  late final GeneratedColumn<int> uniqueQuestionsAnswered =
      GeneratedColumn<int>('unique_questions_answered', aliasedName, false,
          type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        examId,
        calculatedAt,
        overallScore,
        band,
        recentAccuracyComponent,
        domainMasteryComponent,
        mockPerformanceComponent,
        repeatedMasteryComponent,
        coverageComponent,
        evidenceConfidence,
        uniqueQuestionsAnswered
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'readiness_snapshots';
  @override
  VerificationContext validateIntegrity(
      Insertable<ReadinessSnapshotRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(_examIdMeta,
          examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta));
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('calculated_at')) {
      context.handle(
          _calculatedAtMeta,
          calculatedAt.isAcceptableOrUnknown(
              data['calculated_at']!, _calculatedAtMeta));
    } else if (isInserting) {
      context.missing(_calculatedAtMeta);
    }
    if (data.containsKey('overall_score')) {
      context.handle(
          _overallScoreMeta,
          overallScore.isAcceptableOrUnknown(
              data['overall_score']!, _overallScoreMeta));
    } else if (isInserting) {
      context.missing(_overallScoreMeta);
    }
    if (data.containsKey('band')) {
      context.handle(
          _bandMeta, band.isAcceptableOrUnknown(data['band']!, _bandMeta));
    } else if (isInserting) {
      context.missing(_bandMeta);
    }
    if (data.containsKey('recent_accuracy_component')) {
      context.handle(
          _recentAccuracyComponentMeta,
          recentAccuracyComponent.isAcceptableOrUnknown(
              data['recent_accuracy_component']!,
              _recentAccuracyComponentMeta));
    } else if (isInserting) {
      context.missing(_recentAccuracyComponentMeta);
    }
    if (data.containsKey('domain_mastery_component')) {
      context.handle(
          _domainMasteryComponentMeta,
          domainMasteryComponent.isAcceptableOrUnknown(
              data['domain_mastery_component']!, _domainMasteryComponentMeta));
    } else if (isInserting) {
      context.missing(_domainMasteryComponentMeta);
    }
    if (data.containsKey('mock_performance_component')) {
      context.handle(
          _mockPerformanceComponentMeta,
          mockPerformanceComponent.isAcceptableOrUnknown(
              data['mock_performance_component']!,
              _mockPerformanceComponentMeta));
    } else if (isInserting) {
      context.missing(_mockPerformanceComponentMeta);
    }
    if (data.containsKey('repeated_mastery_component')) {
      context.handle(
          _repeatedMasteryComponentMeta,
          repeatedMasteryComponent.isAcceptableOrUnknown(
              data['repeated_mastery_component']!,
              _repeatedMasteryComponentMeta));
    } else if (isInserting) {
      context.missing(_repeatedMasteryComponentMeta);
    }
    if (data.containsKey('coverage_component')) {
      context.handle(
          _coverageComponentMeta,
          coverageComponent.isAcceptableOrUnknown(
              data['coverage_component']!, _coverageComponentMeta));
    } else if (isInserting) {
      context.missing(_coverageComponentMeta);
    }
    if (data.containsKey('evidence_confidence')) {
      context.handle(
          _evidenceConfidenceMeta,
          evidenceConfidence.isAcceptableOrUnknown(
              data['evidence_confidence']!, _evidenceConfidenceMeta));
    } else if (isInserting) {
      context.missing(_evidenceConfidenceMeta);
    }
    if (data.containsKey('unique_questions_answered')) {
      context.handle(
          _uniqueQuestionsAnsweredMeta,
          uniqueQuestionsAnswered.isAcceptableOrUnknown(
              data['unique_questions_answered']!,
              _uniqueQuestionsAnsweredMeta));
    } else if (isInserting) {
      context.missing(_uniqueQuestionsAnsweredMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadinessSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadinessSnapshotRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      examId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exam_id'])!,
      calculatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}calculated_at'])!,
      overallScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}overall_score'])!,
      band: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}band'])!,
      recentAccuracyComponent: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}recent_accuracy_component'])!,
      domainMasteryComponent: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}domain_mastery_component'])!,
      mockPerformanceComponent: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}mock_performance_component'])!,
      repeatedMasteryComponent: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}repeated_mastery_component'])!,
      coverageComponent: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}coverage_component'])!,
      evidenceConfidence: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}evidence_confidence'])!,
      uniqueQuestionsAnswered: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}unique_questions_answered'])!,
    );
  }

  @override
  $ReadinessSnapshotsTable createAlias(String alias) {
    return $ReadinessSnapshotsTable(attachedDatabase, alias);
  }
}

class ReadinessSnapshotRow extends DataClass
    implements Insertable<ReadinessSnapshotRow> {
  final String id;
  final String examId;
  final DateTime calculatedAt;
  final double overallScore;
  final String band;
  final double recentAccuracyComponent;
  final double domainMasteryComponent;
  final double mockPerformanceComponent;
  final double repeatedMasteryComponent;
  final double coverageComponent;
  final double evidenceConfidence;
  final int uniqueQuestionsAnswered;
  const ReadinessSnapshotRow(
      {required this.id,
      required this.examId,
      required this.calculatedAt,
      required this.overallScore,
      required this.band,
      required this.recentAccuracyComponent,
      required this.domainMasteryComponent,
      required this.mockPerformanceComponent,
      required this.repeatedMasteryComponent,
      required this.coverageComponent,
      required this.evidenceConfidence,
      required this.uniqueQuestionsAnswered});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['exam_id'] = Variable<String>(examId);
    map['calculated_at'] = Variable<DateTime>(calculatedAt);
    map['overall_score'] = Variable<double>(overallScore);
    map['band'] = Variable<String>(band);
    map['recent_accuracy_component'] =
        Variable<double>(recentAccuracyComponent);
    map['domain_mastery_component'] = Variable<double>(domainMasteryComponent);
    map['mock_performance_component'] =
        Variable<double>(mockPerformanceComponent);
    map['repeated_mastery_component'] =
        Variable<double>(repeatedMasteryComponent);
    map['coverage_component'] = Variable<double>(coverageComponent);
    map['evidence_confidence'] = Variable<double>(evidenceConfidence);
    map['unique_questions_answered'] = Variable<int>(uniqueQuestionsAnswered);
    return map;
  }

  ReadinessSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return ReadinessSnapshotsCompanion(
      id: Value(id),
      examId: Value(examId),
      calculatedAt: Value(calculatedAt),
      overallScore: Value(overallScore),
      band: Value(band),
      recentAccuracyComponent: Value(recentAccuracyComponent),
      domainMasteryComponent: Value(domainMasteryComponent),
      mockPerformanceComponent: Value(mockPerformanceComponent),
      repeatedMasteryComponent: Value(repeatedMasteryComponent),
      coverageComponent: Value(coverageComponent),
      evidenceConfidence: Value(evidenceConfidence),
      uniqueQuestionsAnswered: Value(uniqueQuestionsAnswered),
    );
  }

  factory ReadinessSnapshotRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadinessSnapshotRow(
      id: serializer.fromJson<String>(json['id']),
      examId: serializer.fromJson<String>(json['examId']),
      calculatedAt: serializer.fromJson<DateTime>(json['calculatedAt']),
      overallScore: serializer.fromJson<double>(json['overallScore']),
      band: serializer.fromJson<String>(json['band']),
      recentAccuracyComponent:
          serializer.fromJson<double>(json['recentAccuracyComponent']),
      domainMasteryComponent:
          serializer.fromJson<double>(json['domainMasteryComponent']),
      mockPerformanceComponent:
          serializer.fromJson<double>(json['mockPerformanceComponent']),
      repeatedMasteryComponent:
          serializer.fromJson<double>(json['repeatedMasteryComponent']),
      coverageComponent: serializer.fromJson<double>(json['coverageComponent']),
      evidenceConfidence:
          serializer.fromJson<double>(json['evidenceConfidence']),
      uniqueQuestionsAnswered:
          serializer.fromJson<int>(json['uniqueQuestionsAnswered']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'examId': serializer.toJson<String>(examId),
      'calculatedAt': serializer.toJson<DateTime>(calculatedAt),
      'overallScore': serializer.toJson<double>(overallScore),
      'band': serializer.toJson<String>(band),
      'recentAccuracyComponent':
          serializer.toJson<double>(recentAccuracyComponent),
      'domainMasteryComponent':
          serializer.toJson<double>(domainMasteryComponent),
      'mockPerformanceComponent':
          serializer.toJson<double>(mockPerformanceComponent),
      'repeatedMasteryComponent':
          serializer.toJson<double>(repeatedMasteryComponent),
      'coverageComponent': serializer.toJson<double>(coverageComponent),
      'evidenceConfidence': serializer.toJson<double>(evidenceConfidence),
      'uniqueQuestionsAnswered':
          serializer.toJson<int>(uniqueQuestionsAnswered),
    };
  }

  ReadinessSnapshotRow copyWith(
          {String? id,
          String? examId,
          DateTime? calculatedAt,
          double? overallScore,
          String? band,
          double? recentAccuracyComponent,
          double? domainMasteryComponent,
          double? mockPerformanceComponent,
          double? repeatedMasteryComponent,
          double? coverageComponent,
          double? evidenceConfidence,
          int? uniqueQuestionsAnswered}) =>
      ReadinessSnapshotRow(
        id: id ?? this.id,
        examId: examId ?? this.examId,
        calculatedAt: calculatedAt ?? this.calculatedAt,
        overallScore: overallScore ?? this.overallScore,
        band: band ?? this.band,
        recentAccuracyComponent:
            recentAccuracyComponent ?? this.recentAccuracyComponent,
        domainMasteryComponent:
            domainMasteryComponent ?? this.domainMasteryComponent,
        mockPerformanceComponent:
            mockPerformanceComponent ?? this.mockPerformanceComponent,
        repeatedMasteryComponent:
            repeatedMasteryComponent ?? this.repeatedMasteryComponent,
        coverageComponent: coverageComponent ?? this.coverageComponent,
        evidenceConfidence: evidenceConfidence ?? this.evidenceConfidence,
        uniqueQuestionsAnswered:
            uniqueQuestionsAnswered ?? this.uniqueQuestionsAnswered,
      );
  ReadinessSnapshotRow copyWithCompanion(ReadinessSnapshotsCompanion data) {
    return ReadinessSnapshotRow(
      id: data.id.present ? data.id.value : this.id,
      examId: data.examId.present ? data.examId.value : this.examId,
      calculatedAt: data.calculatedAt.present
          ? data.calculatedAt.value
          : this.calculatedAt,
      overallScore: data.overallScore.present
          ? data.overallScore.value
          : this.overallScore,
      band: data.band.present ? data.band.value : this.band,
      recentAccuracyComponent: data.recentAccuracyComponent.present
          ? data.recentAccuracyComponent.value
          : this.recentAccuracyComponent,
      domainMasteryComponent: data.domainMasteryComponent.present
          ? data.domainMasteryComponent.value
          : this.domainMasteryComponent,
      mockPerformanceComponent: data.mockPerformanceComponent.present
          ? data.mockPerformanceComponent.value
          : this.mockPerformanceComponent,
      repeatedMasteryComponent: data.repeatedMasteryComponent.present
          ? data.repeatedMasteryComponent.value
          : this.repeatedMasteryComponent,
      coverageComponent: data.coverageComponent.present
          ? data.coverageComponent.value
          : this.coverageComponent,
      evidenceConfidence: data.evidenceConfidence.present
          ? data.evidenceConfidence.value
          : this.evidenceConfidence,
      uniqueQuestionsAnswered: data.uniqueQuestionsAnswered.present
          ? data.uniqueQuestionsAnswered.value
          : this.uniqueQuestionsAnswered,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadinessSnapshotRow(')
          ..write('id: $id, ')
          ..write('examId: $examId, ')
          ..write('calculatedAt: $calculatedAt, ')
          ..write('overallScore: $overallScore, ')
          ..write('band: $band, ')
          ..write('recentAccuracyComponent: $recentAccuracyComponent, ')
          ..write('domainMasteryComponent: $domainMasteryComponent, ')
          ..write('mockPerformanceComponent: $mockPerformanceComponent, ')
          ..write('repeatedMasteryComponent: $repeatedMasteryComponent, ')
          ..write('coverageComponent: $coverageComponent, ')
          ..write('evidenceConfidence: $evidenceConfidence, ')
          ..write('uniqueQuestionsAnswered: $uniqueQuestionsAnswered')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      examId,
      calculatedAt,
      overallScore,
      band,
      recentAccuracyComponent,
      domainMasteryComponent,
      mockPerformanceComponent,
      repeatedMasteryComponent,
      coverageComponent,
      evidenceConfidence,
      uniqueQuestionsAnswered);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadinessSnapshotRow &&
          other.id == this.id &&
          other.examId == this.examId &&
          other.calculatedAt == this.calculatedAt &&
          other.overallScore == this.overallScore &&
          other.band == this.band &&
          other.recentAccuracyComponent == this.recentAccuracyComponent &&
          other.domainMasteryComponent == this.domainMasteryComponent &&
          other.mockPerformanceComponent == this.mockPerformanceComponent &&
          other.repeatedMasteryComponent == this.repeatedMasteryComponent &&
          other.coverageComponent == this.coverageComponent &&
          other.evidenceConfidence == this.evidenceConfidence &&
          other.uniqueQuestionsAnswered == this.uniqueQuestionsAnswered);
}

class ReadinessSnapshotsCompanion
    extends UpdateCompanion<ReadinessSnapshotRow> {
  final Value<String> id;
  final Value<String> examId;
  final Value<DateTime> calculatedAt;
  final Value<double> overallScore;
  final Value<String> band;
  final Value<double> recentAccuracyComponent;
  final Value<double> domainMasteryComponent;
  final Value<double> mockPerformanceComponent;
  final Value<double> repeatedMasteryComponent;
  final Value<double> coverageComponent;
  final Value<double> evidenceConfidence;
  final Value<int> uniqueQuestionsAnswered;
  final Value<int> rowid;
  const ReadinessSnapshotsCompanion({
    this.id = const Value.absent(),
    this.examId = const Value.absent(),
    this.calculatedAt = const Value.absent(),
    this.overallScore = const Value.absent(),
    this.band = const Value.absent(),
    this.recentAccuracyComponent = const Value.absent(),
    this.domainMasteryComponent = const Value.absent(),
    this.mockPerformanceComponent = const Value.absent(),
    this.repeatedMasteryComponent = const Value.absent(),
    this.coverageComponent = const Value.absent(),
    this.evidenceConfidence = const Value.absent(),
    this.uniqueQuestionsAnswered = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadinessSnapshotsCompanion.insert({
    required String id,
    required String examId,
    required DateTime calculatedAt,
    required double overallScore,
    required String band,
    required double recentAccuracyComponent,
    required double domainMasteryComponent,
    required double mockPerformanceComponent,
    required double repeatedMasteryComponent,
    required double coverageComponent,
    required double evidenceConfidence,
    required int uniqueQuestionsAnswered,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        examId = Value(examId),
        calculatedAt = Value(calculatedAt),
        overallScore = Value(overallScore),
        band = Value(band),
        recentAccuracyComponent = Value(recentAccuracyComponent),
        domainMasteryComponent = Value(domainMasteryComponent),
        mockPerformanceComponent = Value(mockPerformanceComponent),
        repeatedMasteryComponent = Value(repeatedMasteryComponent),
        coverageComponent = Value(coverageComponent),
        evidenceConfidence = Value(evidenceConfidence),
        uniqueQuestionsAnswered = Value(uniqueQuestionsAnswered);
  static Insertable<ReadinessSnapshotRow> custom({
    Expression<String>? id,
    Expression<String>? examId,
    Expression<DateTime>? calculatedAt,
    Expression<double>? overallScore,
    Expression<String>? band,
    Expression<double>? recentAccuracyComponent,
    Expression<double>? domainMasteryComponent,
    Expression<double>? mockPerformanceComponent,
    Expression<double>? repeatedMasteryComponent,
    Expression<double>? coverageComponent,
    Expression<double>? evidenceConfidence,
    Expression<int>? uniqueQuestionsAnswered,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (examId != null) 'exam_id': examId,
      if (calculatedAt != null) 'calculated_at': calculatedAt,
      if (overallScore != null) 'overall_score': overallScore,
      if (band != null) 'band': band,
      if (recentAccuracyComponent != null)
        'recent_accuracy_component': recentAccuracyComponent,
      if (domainMasteryComponent != null)
        'domain_mastery_component': domainMasteryComponent,
      if (mockPerformanceComponent != null)
        'mock_performance_component': mockPerformanceComponent,
      if (repeatedMasteryComponent != null)
        'repeated_mastery_component': repeatedMasteryComponent,
      if (coverageComponent != null) 'coverage_component': coverageComponent,
      if (evidenceConfidence != null) 'evidence_confidence': evidenceConfidence,
      if (uniqueQuestionsAnswered != null)
        'unique_questions_answered': uniqueQuestionsAnswered,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadinessSnapshotsCompanion copyWith(
      {Value<String>? id,
      Value<String>? examId,
      Value<DateTime>? calculatedAt,
      Value<double>? overallScore,
      Value<String>? band,
      Value<double>? recentAccuracyComponent,
      Value<double>? domainMasteryComponent,
      Value<double>? mockPerformanceComponent,
      Value<double>? repeatedMasteryComponent,
      Value<double>? coverageComponent,
      Value<double>? evidenceConfidence,
      Value<int>? uniqueQuestionsAnswered,
      Value<int>? rowid}) {
    return ReadinessSnapshotsCompanion(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      overallScore: overallScore ?? this.overallScore,
      band: band ?? this.band,
      recentAccuracyComponent:
          recentAccuracyComponent ?? this.recentAccuracyComponent,
      domainMasteryComponent:
          domainMasteryComponent ?? this.domainMasteryComponent,
      mockPerformanceComponent:
          mockPerformanceComponent ?? this.mockPerformanceComponent,
      repeatedMasteryComponent:
          repeatedMasteryComponent ?? this.repeatedMasteryComponent,
      coverageComponent: coverageComponent ?? this.coverageComponent,
      evidenceConfidence: evidenceConfidence ?? this.evidenceConfidence,
      uniqueQuestionsAnswered:
          uniqueQuestionsAnswered ?? this.uniqueQuestionsAnswered,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (calculatedAt.present) {
      map['calculated_at'] = Variable<DateTime>(calculatedAt.value);
    }
    if (overallScore.present) {
      map['overall_score'] = Variable<double>(overallScore.value);
    }
    if (band.present) {
      map['band'] = Variable<String>(band.value);
    }
    if (recentAccuracyComponent.present) {
      map['recent_accuracy_component'] =
          Variable<double>(recentAccuracyComponent.value);
    }
    if (domainMasteryComponent.present) {
      map['domain_mastery_component'] =
          Variable<double>(domainMasteryComponent.value);
    }
    if (mockPerformanceComponent.present) {
      map['mock_performance_component'] =
          Variable<double>(mockPerformanceComponent.value);
    }
    if (repeatedMasteryComponent.present) {
      map['repeated_mastery_component'] =
          Variable<double>(repeatedMasteryComponent.value);
    }
    if (coverageComponent.present) {
      map['coverage_component'] = Variable<double>(coverageComponent.value);
    }
    if (evidenceConfidence.present) {
      map['evidence_confidence'] = Variable<double>(evidenceConfidence.value);
    }
    if (uniqueQuestionsAnswered.present) {
      map['unique_questions_answered'] =
          Variable<int>(uniqueQuestionsAnswered.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadinessSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('examId: $examId, ')
          ..write('calculatedAt: $calculatedAt, ')
          ..write('overallScore: $overallScore, ')
          ..write('band: $band, ')
          ..write('recentAccuracyComponent: $recentAccuracyComponent, ')
          ..write('domainMasteryComponent: $domainMasteryComponent, ')
          ..write('mockPerformanceComponent: $mockPerformanceComponent, ')
          ..write('repeatedMasteryComponent: $repeatedMasteryComponent, ')
          ..write('coverageComponent: $coverageComponent, ')
          ..write('evidenceConfidence: $evidenceConfidence, ')
          ..write('uniqueQuestionsAnswered: $uniqueQuestionsAnswered, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _studyPlanPreferencesJsonMeta =
      const VerificationMeta('studyPlanPreferencesJson');
  @override
  late final GeneratedColumn<String> studyPlanPreferencesJson =
      GeneratedColumn<String>('study_plan_preferences_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
      'exam_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _experienceLevelMeta =
      const VerificationMeta('experienceLevel');
  @override
  late final GeneratedColumn<String> experienceLevel = GeneratedColumn<String>(
      'experience_level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _examDatePrecisionMeta =
      const VerificationMeta('examDatePrecision');
  @override
  late final GeneratedColumn<String> examDatePrecision =
      GeneratedColumn<String>('exam_date_precision', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _examDateMeta =
      const VerificationMeta('examDate');
  @override
  late final GeneratedColumn<DateTime> examDate = GeneratedColumn<DateTime>(
      'exam_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dailyGoalQuestionsMeta =
      const VerificationMeta('dailyGoalQuestions');
  @override
  late final GeneratedColumn<int> dailyGoalQuestions = GeneratedColumn<int>(
      'daily_goal_questions', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
      'notifications_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notifications_enabled" IN (0, 1))'));
  static const VerificationMeta _themePreferenceMeta =
      const VerificationMeta('themePreference');
  @override
  late final GeneratedColumn<String> themePreference = GeneratedColumn<String>(
      'theme_preference', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _onboardingCompleteMeta =
      const VerificationMeta('onboardingComplete');
  @override
  late final GeneratedColumn<bool> onboardingComplete = GeneratedColumn<bool>(
      'onboarding_complete', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("onboarding_complete" IN (0, 1))'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        studyPlanPreferencesJson,
        examId,
        experienceLevel,
        examDatePrecision,
        examDate,
        dailyGoalQuestions,
        notificationsEnabled,
        themePreference,
        onboardingComplete,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<UserProfileRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('study_plan_preferences_json')) {
      context.handle(
          _studyPlanPreferencesJsonMeta,
          studyPlanPreferencesJson.isAcceptableOrUnknown(
              data['study_plan_preferences_json']!,
              _studyPlanPreferencesJsonMeta));
    }
    if (data.containsKey('exam_id')) {
      context.handle(_examIdMeta,
          examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta));
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('experience_level')) {
      context.handle(
          _experienceLevelMeta,
          experienceLevel.isAcceptableOrUnknown(
              data['experience_level']!, _experienceLevelMeta));
    } else if (isInserting) {
      context.missing(_experienceLevelMeta);
    }
    if (data.containsKey('exam_date_precision')) {
      context.handle(
          _examDatePrecisionMeta,
          examDatePrecision.isAcceptableOrUnknown(
              data['exam_date_precision']!, _examDatePrecisionMeta));
    } else if (isInserting) {
      context.missing(_examDatePrecisionMeta);
    }
    if (data.containsKey('exam_date')) {
      context.handle(_examDateMeta,
          examDate.isAcceptableOrUnknown(data['exam_date']!, _examDateMeta));
    }
    if (data.containsKey('daily_goal_questions')) {
      context.handle(
          _dailyGoalQuestionsMeta,
          dailyGoalQuestions.isAcceptableOrUnknown(
              data['daily_goal_questions']!, _dailyGoalQuestionsMeta));
    } else if (isInserting) {
      context.missing(_dailyGoalQuestionsMeta);
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
          _notificationsEnabledMeta,
          notificationsEnabled.isAcceptableOrUnknown(
              data['notifications_enabled']!, _notificationsEnabledMeta));
    } else if (isInserting) {
      context.missing(_notificationsEnabledMeta);
    }
    if (data.containsKey('theme_preference')) {
      context.handle(
          _themePreferenceMeta,
          themePreference.isAcceptableOrUnknown(
              data['theme_preference']!, _themePreferenceMeta));
    } else if (isInserting) {
      context.missing(_themePreferenceMeta);
    }
    if (data.containsKey('onboarding_complete')) {
      context.handle(
          _onboardingCompleteMeta,
          onboardingComplete.isAcceptableOrUnknown(
              data['onboarding_complete']!, _onboardingCompleteMeta));
    } else if (isInserting) {
      context.missing(_onboardingCompleteMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {examId};
  @override
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      studyPlanPreferencesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}study_plan_preferences_json']),
      examId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exam_id'])!,
      experienceLevel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}experience_level'])!,
      examDatePrecision: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}exam_date_precision'])!,
      examDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}exam_date']),
      dailyGoalQuestions: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}daily_goal_questions'])!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}notifications_enabled'])!,
      themePreference: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}theme_preference'])!,
      onboardingComplete: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}onboarding_complete'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  final String? studyPlanPreferencesJson;
  final String examId;
  final String experienceLevel;
  final String examDatePrecision;
  final DateTime? examDate;
  final int dailyGoalQuestions;
  final bool notificationsEnabled;
  final String themePreference;
  final bool onboardingComplete;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserProfileRow(
      {this.studyPlanPreferencesJson,
      required this.examId,
      required this.experienceLevel,
      required this.examDatePrecision,
      this.examDate,
      required this.dailyGoalQuestions,
      required this.notificationsEnabled,
      required this.themePreference,
      required this.onboardingComplete,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || studyPlanPreferencesJson != null) {
      map['study_plan_preferences_json'] =
          Variable<String>(studyPlanPreferencesJson);
    }
    map['exam_id'] = Variable<String>(examId);
    map['experience_level'] = Variable<String>(experienceLevel);
    map['exam_date_precision'] = Variable<String>(examDatePrecision);
    if (!nullToAbsent || examDate != null) {
      map['exam_date'] = Variable<DateTime>(examDate);
    }
    map['daily_goal_questions'] = Variable<int>(dailyGoalQuestions);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['theme_preference'] = Variable<String>(themePreference);
    map['onboarding_complete'] = Variable<bool>(onboardingComplete);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      studyPlanPreferencesJson: studyPlanPreferencesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(studyPlanPreferencesJson),
      examId: Value(examId),
      experienceLevel: Value(experienceLevel),
      examDatePrecision: Value(examDatePrecision),
      examDate: examDate == null && nullToAbsent
          ? const Value.absent()
          : Value(examDate),
      dailyGoalQuestions: Value(dailyGoalQuestions),
      notificationsEnabled: Value(notificationsEnabled),
      themePreference: Value(themePreference),
      onboardingComplete: Value(onboardingComplete),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfileRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      studyPlanPreferencesJson:
          serializer.fromJson<String?>(json['studyPlanPreferencesJson']),
      examId: serializer.fromJson<String>(json['examId']),
      experienceLevel: serializer.fromJson<String>(json['experienceLevel']),
      examDatePrecision: serializer.fromJson<String>(json['examDatePrecision']),
      examDate: serializer.fromJson<DateTime?>(json['examDate']),
      dailyGoalQuestions: serializer.fromJson<int>(json['dailyGoalQuestions']),
      notificationsEnabled:
          serializer.fromJson<bool>(json['notificationsEnabled']),
      themePreference: serializer.fromJson<String>(json['themePreference']),
      onboardingComplete: serializer.fromJson<bool>(json['onboardingComplete']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'studyPlanPreferencesJson':
          serializer.toJson<String?>(studyPlanPreferencesJson),
      'examId': serializer.toJson<String>(examId),
      'experienceLevel': serializer.toJson<String>(experienceLevel),
      'examDatePrecision': serializer.toJson<String>(examDatePrecision),
      'examDate': serializer.toJson<DateTime?>(examDate),
      'dailyGoalQuestions': serializer.toJson<int>(dailyGoalQuestions),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'themePreference': serializer.toJson<String>(themePreference),
      'onboardingComplete': serializer.toJson<bool>(onboardingComplete),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfileRow copyWith(
          {Value<String?> studyPlanPreferencesJson = const Value.absent(),
          String? examId,
          String? experienceLevel,
          String? examDatePrecision,
          Value<DateTime?> examDate = const Value.absent(),
          int? dailyGoalQuestions,
          bool? notificationsEnabled,
          String? themePreference,
          bool? onboardingComplete,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      UserProfileRow(
        studyPlanPreferencesJson: studyPlanPreferencesJson.present
            ? studyPlanPreferencesJson.value
            : this.studyPlanPreferencesJson,
        examId: examId ?? this.examId,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        examDatePrecision: examDatePrecision ?? this.examDatePrecision,
        examDate: examDate.present ? examDate.value : this.examDate,
        dailyGoalQuestions: dailyGoalQuestions ?? this.dailyGoalQuestions,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        themePreference: themePreference ?? this.themePreference,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  UserProfileRow copyWithCompanion(UserProfilesCompanion data) {
    return UserProfileRow(
      studyPlanPreferencesJson: data.studyPlanPreferencesJson.present
          ? data.studyPlanPreferencesJson.value
          : this.studyPlanPreferencesJson,
      examId: data.examId.present ? data.examId.value : this.examId,
      experienceLevel: data.experienceLevel.present
          ? data.experienceLevel.value
          : this.experienceLevel,
      examDatePrecision: data.examDatePrecision.present
          ? data.examDatePrecision.value
          : this.examDatePrecision,
      examDate: data.examDate.present ? data.examDate.value : this.examDate,
      dailyGoalQuestions: data.dailyGoalQuestions.present
          ? data.dailyGoalQuestions.value
          : this.dailyGoalQuestions,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      themePreference: data.themePreference.present
          ? data.themePreference.value
          : this.themePreference,
      onboardingComplete: data.onboardingComplete.present
          ? data.onboardingComplete.value
          : this.onboardingComplete,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('studyPlanPreferencesJson: $studyPlanPreferencesJson, ')
          ..write('examId: $examId, ')
          ..write('experienceLevel: $experienceLevel, ')
          ..write('examDatePrecision: $examDatePrecision, ')
          ..write('examDate: $examDate, ')
          ..write('dailyGoalQuestions: $dailyGoalQuestions, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('themePreference: $themePreference, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      studyPlanPreferencesJson,
      examId,
      experienceLevel,
      examDatePrecision,
      examDate,
      dailyGoalQuestions,
      notificationsEnabled,
      themePreference,
      onboardingComplete,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.studyPlanPreferencesJson == this.studyPlanPreferencesJson &&
          other.examId == this.examId &&
          other.experienceLevel == this.experienceLevel &&
          other.examDatePrecision == this.examDatePrecision &&
          other.examDate == this.examDate &&
          other.dailyGoalQuestions == this.dailyGoalQuestions &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.themePreference == this.themePreference &&
          other.onboardingComplete == this.onboardingComplete &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<String?> studyPlanPreferencesJson;
  final Value<String> examId;
  final Value<String> experienceLevel;
  final Value<String> examDatePrecision;
  final Value<DateTime?> examDate;
  final Value<int> dailyGoalQuestions;
  final Value<bool> notificationsEnabled;
  final Value<String> themePreference;
  final Value<bool> onboardingComplete;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserProfilesCompanion({
    this.studyPlanPreferencesJson = const Value.absent(),
    this.examId = const Value.absent(),
    this.experienceLevel = const Value.absent(),
    this.examDatePrecision = const Value.absent(),
    this.examDate = const Value.absent(),
    this.dailyGoalQuestions = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.themePreference = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.studyPlanPreferencesJson = const Value.absent(),
    required String examId,
    required String experienceLevel,
    required String examDatePrecision,
    this.examDate = const Value.absent(),
    required int dailyGoalQuestions,
    required bool notificationsEnabled,
    required String themePreference,
    required bool onboardingComplete,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : examId = Value(examId),
        experienceLevel = Value(experienceLevel),
        examDatePrecision = Value(examDatePrecision),
        dailyGoalQuestions = Value(dailyGoalQuestions),
        notificationsEnabled = Value(notificationsEnabled),
        themePreference = Value(themePreference),
        onboardingComplete = Value(onboardingComplete),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<UserProfileRow> custom({
    Expression<String>? studyPlanPreferencesJson,
    Expression<String>? examId,
    Expression<String>? experienceLevel,
    Expression<String>? examDatePrecision,
    Expression<DateTime>? examDate,
    Expression<int>? dailyGoalQuestions,
    Expression<bool>? notificationsEnabled,
    Expression<String>? themePreference,
    Expression<bool>? onboardingComplete,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (studyPlanPreferencesJson != null)
        'study_plan_preferences_json': studyPlanPreferencesJson,
      if (examId != null) 'exam_id': examId,
      if (experienceLevel != null) 'experience_level': experienceLevel,
      if (examDatePrecision != null) 'exam_date_precision': examDatePrecision,
      if (examDate != null) 'exam_date': examDate,
      if (dailyGoalQuestions != null)
        'daily_goal_questions': dailyGoalQuestions,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (themePreference != null) 'theme_preference': themePreference,
      if (onboardingComplete != null) 'onboarding_complete': onboardingComplete,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfilesCompanion copyWith(
      {Value<String?>? studyPlanPreferencesJson,
      Value<String>? examId,
      Value<String>? experienceLevel,
      Value<String>? examDatePrecision,
      Value<DateTime?>? examDate,
      Value<int>? dailyGoalQuestions,
      Value<bool>? notificationsEnabled,
      Value<String>? themePreference,
      Value<bool>? onboardingComplete,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UserProfilesCompanion(
      studyPlanPreferencesJson:
          studyPlanPreferencesJson ?? this.studyPlanPreferencesJson,
      examId: examId ?? this.examId,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      examDatePrecision: examDatePrecision ?? this.examDatePrecision,
      examDate: examDate ?? this.examDate,
      dailyGoalQuestions: dailyGoalQuestions ?? this.dailyGoalQuestions,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themePreference: themePreference ?? this.themePreference,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (studyPlanPreferencesJson.present) {
      map['study_plan_preferences_json'] =
          Variable<String>(studyPlanPreferencesJson.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (experienceLevel.present) {
      map['experience_level'] = Variable<String>(experienceLevel.value);
    }
    if (examDatePrecision.present) {
      map['exam_date_precision'] = Variable<String>(examDatePrecision.value);
    }
    if (examDate.present) {
      map['exam_date'] = Variable<DateTime>(examDate.value);
    }
    if (dailyGoalQuestions.present) {
      map['daily_goal_questions'] = Variable<int>(dailyGoalQuestions.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (themePreference.present) {
      map['theme_preference'] = Variable<String>(themePreference.value);
    }
    if (onboardingComplete.present) {
      map['onboarding_complete'] = Variable<bool>(onboardingComplete.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('studyPlanPreferencesJson: $studyPlanPreferencesJson, ')
          ..write('examId: $examId, ')
          ..write('experienceLevel: $experienceLevel, ')
          ..write('examDatePrecision: $examDatePrecision, ')
          ..write('examDate: $examDate, ')
          ..write('dailyGoalQuestions: $dailyGoalQuestions, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('themePreference: $themePreference, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudySchedulesTable extends StudySchedules
    with TableInfo<$StudySchedulesTable, StudyScheduleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudySchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
      'exam_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minutesMeta =
      const VerificationMeta('minutes');
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
      'minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _reservedQuestionIdsJsonMeta =
      const VerificationMeta('reservedQuestionIdsJson');
  @override
  late final GeneratedColumn<String> reservedQuestionIdsJson =
      GeneratedColumn<String>('reserved_question_ids_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [examId, date, kind, minutes, reservedQuestionIdsJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_schedules';
  @override
  VerificationContext validateIntegrity(Insertable<StudyScheduleRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exam_id')) {
      context.handle(_examIdMeta,
          examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta));
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(_minutesMeta,
          minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta));
    }
    if (data.containsKey('reserved_question_ids_json')) {
      context.handle(
          _reservedQuestionIdsJsonMeta,
          reservedQuestionIdsJson.isAcceptableOrUnknown(
              data['reserved_question_ids_json']!,
              _reservedQuestionIdsJsonMeta));
    } else if (isInserting) {
      context.missing(_reservedQuestionIdsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {examId, date};
  @override
  StudyScheduleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyScheduleRow(
      examId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exam_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      minutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minutes']),
      reservedQuestionIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reserved_question_ids_json'])!,
    );
  }

  @override
  $StudySchedulesTable createAlias(String alias) {
    return $StudySchedulesTable(attachedDatabase, alias);
  }
}

class StudyScheduleRow extends DataClass
    implements Insertable<StudyScheduleRow> {
  final String examId;
  final String date;
  final String kind;
  final int? minutes;
  final String reservedQuestionIdsJson;
  const StudyScheduleRow(
      {required this.examId,
      required this.date,
      required this.kind,
      this.minutes,
      required this.reservedQuestionIdsJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exam_id'] = Variable<String>(examId);
    map['date'] = Variable<String>(date);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || minutes != null) {
      map['minutes'] = Variable<int>(minutes);
    }
    map['reserved_question_ids_json'] =
        Variable<String>(reservedQuestionIdsJson);
    return map;
  }

  StudySchedulesCompanion toCompanion(bool nullToAbsent) {
    return StudySchedulesCompanion(
      examId: Value(examId),
      date: Value(date),
      kind: Value(kind),
      minutes: minutes == null && nullToAbsent
          ? const Value.absent()
          : Value(minutes),
      reservedQuestionIdsJson: Value(reservedQuestionIdsJson),
    );
  }

  factory StudyScheduleRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyScheduleRow(
      examId: serializer.fromJson<String>(json['examId']),
      date: serializer.fromJson<String>(json['date']),
      kind: serializer.fromJson<String>(json['kind']),
      minutes: serializer.fromJson<int?>(json['minutes']),
      reservedQuestionIdsJson:
          serializer.fromJson<String>(json['reservedQuestionIdsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'examId': serializer.toJson<String>(examId),
      'date': serializer.toJson<String>(date),
      'kind': serializer.toJson<String>(kind),
      'minutes': serializer.toJson<int?>(minutes),
      'reservedQuestionIdsJson':
          serializer.toJson<String>(reservedQuestionIdsJson),
    };
  }

  StudyScheduleRow copyWith(
          {String? examId,
          String? date,
          String? kind,
          Value<int?> minutes = const Value.absent(),
          String? reservedQuestionIdsJson}) =>
      StudyScheduleRow(
        examId: examId ?? this.examId,
        date: date ?? this.date,
        kind: kind ?? this.kind,
        minutes: minutes.present ? minutes.value : this.minutes,
        reservedQuestionIdsJson:
            reservedQuestionIdsJson ?? this.reservedQuestionIdsJson,
      );
  StudyScheduleRow copyWithCompanion(StudySchedulesCompanion data) {
    return StudyScheduleRow(
      examId: data.examId.present ? data.examId.value : this.examId,
      date: data.date.present ? data.date.value : this.date,
      kind: data.kind.present ? data.kind.value : this.kind,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      reservedQuestionIdsJson: data.reservedQuestionIdsJson.present
          ? data.reservedQuestionIdsJson.value
          : this.reservedQuestionIdsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyScheduleRow(')
          ..write('examId: $examId, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('minutes: $minutes, ')
          ..write('reservedQuestionIdsJson: $reservedQuestionIdsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(examId, date, kind, minutes, reservedQuestionIdsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyScheduleRow &&
          other.examId == this.examId &&
          other.date == this.date &&
          other.kind == this.kind &&
          other.minutes == this.minutes &&
          other.reservedQuestionIdsJson == this.reservedQuestionIdsJson);
}

class StudySchedulesCompanion extends UpdateCompanion<StudyScheduleRow> {
  final Value<String> examId;
  final Value<String> date;
  final Value<String> kind;
  final Value<int?> minutes;
  final Value<String> reservedQuestionIdsJson;
  final Value<int> rowid;
  const StudySchedulesCompanion({
    this.examId = const Value.absent(),
    this.date = const Value.absent(),
    this.kind = const Value.absent(),
    this.minutes = const Value.absent(),
    this.reservedQuestionIdsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudySchedulesCompanion.insert({
    required String examId,
    required String date,
    required String kind,
    this.minutes = const Value.absent(),
    required String reservedQuestionIdsJson,
    this.rowid = const Value.absent(),
  })  : examId = Value(examId),
        date = Value(date),
        kind = Value(kind),
        reservedQuestionIdsJson = Value(reservedQuestionIdsJson);
  static Insertable<StudyScheduleRow> custom({
    Expression<String>? examId,
    Expression<String>? date,
    Expression<String>? kind,
    Expression<int>? minutes,
    Expression<String>? reservedQuestionIdsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (examId != null) 'exam_id': examId,
      if (date != null) 'date': date,
      if (kind != null) 'kind': kind,
      if (minutes != null) 'minutes': minutes,
      if (reservedQuestionIdsJson != null)
        'reserved_question_ids_json': reservedQuestionIdsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudySchedulesCompanion copyWith(
      {Value<String>? examId,
      Value<String>? date,
      Value<String>? kind,
      Value<int?>? minutes,
      Value<String>? reservedQuestionIdsJson,
      Value<int>? rowid}) {
    return StudySchedulesCompanion(
      examId: examId ?? this.examId,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      minutes: minutes ?? this.minutes,
      reservedQuestionIdsJson:
          reservedQuestionIdsJson ?? this.reservedQuestionIdsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (reservedQuestionIdsJson.present) {
      map['reserved_question_ids_json'] =
          Variable<String>(reservedQuestionIdsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudySchedulesCompanion(')
          ..write('examId: $examId, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('minutes: $minutes, ')
          ..write('reservedQuestionIdsJson: $reservedQuestionIdsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AnswerAttemptsTable answerAttempts = $AnswerAttemptsTable(this);
  late final $QuestionStatesTable questionStates = $QuestionStatesTable(this);
  late final $PracticeSessionsTable practiceSessions =
      $PracticeSessionsTable(this);
  late final $MockAttemptsTable mockAttempts = $MockAttemptsTable(this);
  late final $ReadinessSnapshotsTable readinessSnapshots =
      $ReadinessSnapshotsTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $StudySchedulesTable studySchedules = $StudySchedulesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        answerAttempts,
        questionStates,
        practiceSessions,
        mockAttempts,
        readinessSnapshots,
        userProfiles,
        studySchedules
      ];
}

typedef $$AnswerAttemptsTableCreateCompanionBuilder = AnswerAttemptsCompanion
    Function({
  Value<bool?> confident,
  Value<int?> activeDurationSeconds,
  Value<String?> localAnsweredDate,
  required String id,
  required String examId,
  required String questionId,
  required String domainId,
  required String topicId,
  required int difficulty,
  required String sessionId,
  required String sessionType,
  required String selectedAnswerId,
  required bool isCorrect,
  required DateTime answeredAt,
  Value<String?> contentVersion,
  Value<int?> questionVersion,
  Value<String?> correctAnswerId,
  Value<String?> explanation,
  Value<int> rowid,
});
typedef $$AnswerAttemptsTableUpdateCompanionBuilder = AnswerAttemptsCompanion
    Function({
  Value<bool?> confident,
  Value<int?> activeDurationSeconds,
  Value<String?> localAnsweredDate,
  Value<String> id,
  Value<String> examId,
  Value<String> questionId,
  Value<String> domainId,
  Value<String> topicId,
  Value<int> difficulty,
  Value<String> sessionId,
  Value<String> sessionType,
  Value<String> selectedAnswerId,
  Value<bool> isCorrect,
  Value<DateTime> answeredAt,
  Value<String?> contentVersion,
  Value<int?> questionVersion,
  Value<String?> correctAnswerId,
  Value<String?> explanation,
  Value<int> rowid,
});

class $$AnswerAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $AnswerAttemptsTable> {
  $$AnswerAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get confident => $composableBuilder(
      column: $table.confident, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get activeDurationSeconds => $composableBuilder(
      column: $table.activeDurationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localAnsweredDate => $composableBuilder(
      column: $table.localAnsweredDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get domainId => $composableBuilder(
      column: $table.domainId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionType => $composableBuilder(
      column: $table.sessionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get selectedAnswerId => $composableBuilder(
      column: $table.selectedAnswerId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCorrect => $composableBuilder(
      column: $table.isCorrect, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
      column: $table.answeredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get questionVersion => $composableBuilder(
      column: $table.questionVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get correctAnswerId => $composableBuilder(
      column: $table.correctAnswerId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnFilters(column));
}

class $$AnswerAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnswerAttemptsTable> {
  $$AnswerAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get confident => $composableBuilder(
      column: $table.confident, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get activeDurationSeconds => $composableBuilder(
      column: $table.activeDurationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localAnsweredDate => $composableBuilder(
      column: $table.localAnsweredDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get domainId => $composableBuilder(
      column: $table.domainId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionType => $composableBuilder(
      column: $table.sessionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get selectedAnswerId => $composableBuilder(
      column: $table.selectedAnswerId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
      column: $table.isCorrect, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
      column: $table.answeredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get questionVersion => $composableBuilder(
      column: $table.questionVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get correctAnswerId => $composableBuilder(
      column: $table.correctAnswerId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnOrderings(column));
}

class $$AnswerAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnswerAttemptsTable> {
  $$AnswerAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get confident =>
      $composableBuilder(column: $table.confident, builder: (column) => column);

  GeneratedColumn<int> get activeDurationSeconds => $composableBuilder(
      column: $table.activeDurationSeconds, builder: (column) => column);

  GeneratedColumn<String> get localAnsweredDate => $composableBuilder(
      column: $table.localAnsweredDate, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get examId =>
      $composableBuilder(column: $table.examId, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => column);

  GeneratedColumn<String> get domainId =>
      $composableBuilder(column: $table.domainId, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
      column: $table.sessionType, builder: (column) => column);

  GeneratedColumn<String> get selectedAnswerId => $composableBuilder(
      column: $table.selectedAnswerId, builder: (column) => column);

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
      column: $table.answeredAt, builder: (column) => column);

  GeneratedColumn<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion, builder: (column) => column);

  GeneratedColumn<int> get questionVersion => $composableBuilder(
      column: $table.questionVersion, builder: (column) => column);

  GeneratedColumn<String> get correctAnswerId => $composableBuilder(
      column: $table.correctAnswerId, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => column);
}

class $$AnswerAttemptsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AnswerAttemptsTable,
    AnswerAttemptRow,
    $$AnswerAttemptsTableFilterComposer,
    $$AnswerAttemptsTableOrderingComposer,
    $$AnswerAttemptsTableAnnotationComposer,
    $$AnswerAttemptsTableCreateCompanionBuilder,
    $$AnswerAttemptsTableUpdateCompanionBuilder,
    (
      AnswerAttemptRow,
      BaseReferences<_$AppDatabase, $AnswerAttemptsTable, AnswerAttemptRow>
    ),
    AnswerAttemptRow,
    PrefetchHooks Function()> {
  $$AnswerAttemptsTableTableManager(
      _$AppDatabase db, $AnswerAttemptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnswerAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnswerAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnswerAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<bool?> confident = const Value.absent(),
            Value<int?> activeDurationSeconds = const Value.absent(),
            Value<String?> localAnsweredDate = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> examId = const Value.absent(),
            Value<String> questionId = const Value.absent(),
            Value<String> domainId = const Value.absent(),
            Value<String> topicId = const Value.absent(),
            Value<int> difficulty = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> sessionType = const Value.absent(),
            Value<String> selectedAnswerId = const Value.absent(),
            Value<bool> isCorrect = const Value.absent(),
            Value<DateTime> answeredAt = const Value.absent(),
            Value<String?> contentVersion = const Value.absent(),
            Value<int?> questionVersion = const Value.absent(),
            Value<String?> correctAnswerId = const Value.absent(),
            Value<String?> explanation = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnswerAttemptsCompanion(
            confident: confident,
            activeDurationSeconds: activeDurationSeconds,
            localAnsweredDate: localAnsweredDate,
            id: id,
            examId: examId,
            questionId: questionId,
            domainId: domainId,
            topicId: topicId,
            difficulty: difficulty,
            sessionId: sessionId,
            sessionType: sessionType,
            selectedAnswerId: selectedAnswerId,
            isCorrect: isCorrect,
            answeredAt: answeredAt,
            contentVersion: contentVersion,
            questionVersion: questionVersion,
            correctAnswerId: correctAnswerId,
            explanation: explanation,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<bool?> confident = const Value.absent(),
            Value<int?> activeDurationSeconds = const Value.absent(),
            Value<String?> localAnsweredDate = const Value.absent(),
            required String id,
            required String examId,
            required String questionId,
            required String domainId,
            required String topicId,
            required int difficulty,
            required String sessionId,
            required String sessionType,
            required String selectedAnswerId,
            required bool isCorrect,
            required DateTime answeredAt,
            Value<String?> contentVersion = const Value.absent(),
            Value<int?> questionVersion = const Value.absent(),
            Value<String?> correctAnswerId = const Value.absent(),
            Value<String?> explanation = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnswerAttemptsCompanion.insert(
            confident: confident,
            activeDurationSeconds: activeDurationSeconds,
            localAnsweredDate: localAnsweredDate,
            id: id,
            examId: examId,
            questionId: questionId,
            domainId: domainId,
            topicId: topicId,
            difficulty: difficulty,
            sessionId: sessionId,
            sessionType: sessionType,
            selectedAnswerId: selectedAnswerId,
            isCorrect: isCorrect,
            answeredAt: answeredAt,
            contentVersion: contentVersion,
            questionVersion: questionVersion,
            correctAnswerId: correctAnswerId,
            explanation: explanation,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AnswerAttemptsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AnswerAttemptsTable,
    AnswerAttemptRow,
    $$AnswerAttemptsTableFilterComposer,
    $$AnswerAttemptsTableOrderingComposer,
    $$AnswerAttemptsTableAnnotationComposer,
    $$AnswerAttemptsTableCreateCompanionBuilder,
    $$AnswerAttemptsTableUpdateCompanionBuilder,
    (
      AnswerAttemptRow,
      BaseReferences<_$AppDatabase, $AnswerAttemptsTable, AnswerAttemptRow>
    ),
    AnswerAttemptRow,
    PrefetchHooks Function()>;
typedef $$QuestionStatesTableCreateCompanionBuilder = QuestionStatesCompanion
    Function({
  required String examId,
  required String questionId,
  Value<bool> bookmarked,
  Value<int> timesSeen,
  Value<int> timesCorrect,
  Value<int> timesIncorrect,
  Value<int> consecutiveCorrect,
  Value<DateTime?> lastAnsweredAt,
  Value<int> rowid,
});
typedef $$QuestionStatesTableUpdateCompanionBuilder = QuestionStatesCompanion
    Function({
  Value<String> examId,
  Value<String> questionId,
  Value<bool> bookmarked,
  Value<int> timesSeen,
  Value<int> timesCorrect,
  Value<int> timesIncorrect,
  Value<int> consecutiveCorrect,
  Value<DateTime?> lastAnsweredAt,
  Value<int> rowid,
});

class $$QuestionStatesTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionStatesTable> {
  $$QuestionStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get bookmarked => $composableBuilder(
      column: $table.bookmarked, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timesSeen => $composableBuilder(
      column: $table.timesSeen, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timesCorrect => $composableBuilder(
      column: $table.timesCorrect, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timesIncorrect => $composableBuilder(
      column: $table.timesIncorrect,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get consecutiveCorrect => $composableBuilder(
      column: $table.consecutiveCorrect,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAnsweredAt => $composableBuilder(
      column: $table.lastAnsweredAt,
      builder: (column) => ColumnFilters(column));
}

class $$QuestionStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionStatesTable> {
  $$QuestionStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get bookmarked => $composableBuilder(
      column: $table.bookmarked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timesSeen => $composableBuilder(
      column: $table.timesSeen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timesCorrect => $composableBuilder(
      column: $table.timesCorrect,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timesIncorrect => $composableBuilder(
      column: $table.timesIncorrect,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get consecutiveCorrect => $composableBuilder(
      column: $table.consecutiveCorrect,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAnsweredAt => $composableBuilder(
      column: $table.lastAnsweredAt,
      builder: (column) => ColumnOrderings(column));
}

class $$QuestionStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionStatesTable> {
  $$QuestionStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get examId =>
      $composableBuilder(column: $table.examId, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => column);

  GeneratedColumn<bool> get bookmarked => $composableBuilder(
      column: $table.bookmarked, builder: (column) => column);

  GeneratedColumn<int> get timesSeen =>
      $composableBuilder(column: $table.timesSeen, builder: (column) => column);

  GeneratedColumn<int> get timesCorrect => $composableBuilder(
      column: $table.timesCorrect, builder: (column) => column);

  GeneratedColumn<int> get timesIncorrect => $composableBuilder(
      column: $table.timesIncorrect, builder: (column) => column);

  GeneratedColumn<int> get consecutiveCorrect => $composableBuilder(
      column: $table.consecutiveCorrect, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAnsweredAt => $composableBuilder(
      column: $table.lastAnsweredAt, builder: (column) => column);
}

class $$QuestionStatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuestionStatesTable,
    QuestionStateRow,
    $$QuestionStatesTableFilterComposer,
    $$QuestionStatesTableOrderingComposer,
    $$QuestionStatesTableAnnotationComposer,
    $$QuestionStatesTableCreateCompanionBuilder,
    $$QuestionStatesTableUpdateCompanionBuilder,
    (
      QuestionStateRow,
      BaseReferences<_$AppDatabase, $QuestionStatesTable, QuestionStateRow>
    ),
    QuestionStateRow,
    PrefetchHooks Function()> {
  $$QuestionStatesTableTableManager(
      _$AppDatabase db, $QuestionStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> examId = const Value.absent(),
            Value<String> questionId = const Value.absent(),
            Value<bool> bookmarked = const Value.absent(),
            Value<int> timesSeen = const Value.absent(),
            Value<int> timesCorrect = const Value.absent(),
            Value<int> timesIncorrect = const Value.absent(),
            Value<int> consecutiveCorrect = const Value.absent(),
            Value<DateTime?> lastAnsweredAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuestionStatesCompanion(
            examId: examId,
            questionId: questionId,
            bookmarked: bookmarked,
            timesSeen: timesSeen,
            timesCorrect: timesCorrect,
            timesIncorrect: timesIncorrect,
            consecutiveCorrect: consecutiveCorrect,
            lastAnsweredAt: lastAnsweredAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String examId,
            required String questionId,
            Value<bool> bookmarked = const Value.absent(),
            Value<int> timesSeen = const Value.absent(),
            Value<int> timesCorrect = const Value.absent(),
            Value<int> timesIncorrect = const Value.absent(),
            Value<int> consecutiveCorrect = const Value.absent(),
            Value<DateTime?> lastAnsweredAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuestionStatesCompanion.insert(
            examId: examId,
            questionId: questionId,
            bookmarked: bookmarked,
            timesSeen: timesSeen,
            timesCorrect: timesCorrect,
            timesIncorrect: timesIncorrect,
            consecutiveCorrect: consecutiveCorrect,
            lastAnsweredAt: lastAnsweredAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuestionStatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuestionStatesTable,
    QuestionStateRow,
    $$QuestionStatesTableFilterComposer,
    $$QuestionStatesTableOrderingComposer,
    $$QuestionStatesTableAnnotationComposer,
    $$QuestionStatesTableCreateCompanionBuilder,
    $$QuestionStatesTableUpdateCompanionBuilder,
    (
      QuestionStateRow,
      BaseReferences<_$AppDatabase, $QuestionStatesTable, QuestionStateRow>
    ),
    QuestionStateRow,
    PrefetchHooks Function()>;
typedef $$PracticeSessionsTableCreateCompanionBuilder
    = PracticeSessionsCompanion Function({
  Value<String?> planDate,
  Value<String?> reviewQuestionIdsJson,
  required String id,
  required String examId,
  required String mode,
  required String questionIdsJson,
  Value<String?> answerOrderJson,
  required String status,
  required DateTime startedAt,
  Value<DateTime?> completedAt,
  Value<String?> contentVersion,
  Value<int> rowid,
});
typedef $$PracticeSessionsTableUpdateCompanionBuilder
    = PracticeSessionsCompanion Function({
  Value<String?> planDate,
  Value<String?> reviewQuestionIdsJson,
  Value<String> id,
  Value<String> examId,
  Value<String> mode,
  Value<String> questionIdsJson,
  Value<String?> answerOrderJson,
  Value<String> status,
  Value<DateTime> startedAt,
  Value<DateTime?> completedAt,
  Value<String?> contentVersion,
  Value<int> rowid,
});

class $$PracticeSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get planDate => $composableBuilder(
      column: $table.planDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reviewQuestionIdsJson => $composableBuilder(
      column: $table.reviewQuestionIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionIdsJson => $composableBuilder(
      column: $table.questionIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answerOrderJson => $composableBuilder(
      column: $table.answerOrderJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnFilters(column));
}

class $$PracticeSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get planDate => $composableBuilder(
      column: $table.planDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reviewQuestionIdsJson => $composableBuilder(
      column: $table.reviewQuestionIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionIdsJson => $composableBuilder(
      column: $table.questionIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answerOrderJson => $composableBuilder(
      column: $table.answerOrderJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnOrderings(column));
}

class $$PracticeSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get planDate =>
      $composableBuilder(column: $table.planDate, builder: (column) => column);

  GeneratedColumn<String> get reviewQuestionIdsJson => $composableBuilder(
      column: $table.reviewQuestionIdsJson, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get examId =>
      $composableBuilder(column: $table.examId, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get questionIdsJson => $composableBuilder(
      column: $table.questionIdsJson, builder: (column) => column);

  GeneratedColumn<String> get answerOrderJson => $composableBuilder(
      column: $table.answerOrderJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion, builder: (column) => column);
}

class $$PracticeSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PracticeSessionsTable,
    PracticeSessionRow,
    $$PracticeSessionsTableFilterComposer,
    $$PracticeSessionsTableOrderingComposer,
    $$PracticeSessionsTableAnnotationComposer,
    $$PracticeSessionsTableCreateCompanionBuilder,
    $$PracticeSessionsTableUpdateCompanionBuilder,
    (
      PracticeSessionRow,
      BaseReferences<_$AppDatabase, $PracticeSessionsTable, PracticeSessionRow>
    ),
    PracticeSessionRow,
    PrefetchHooks Function()> {
  $$PracticeSessionsTableTableManager(
      _$AppDatabase db, $PracticeSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String?> planDate = const Value.absent(),
            Value<String?> reviewQuestionIdsJson = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> examId = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<String> questionIdsJson = const Value.absent(),
            Value<String?> answerOrderJson = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> contentVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PracticeSessionsCompanion(
            planDate: planDate,
            reviewQuestionIdsJson: reviewQuestionIdsJson,
            id: id,
            examId: examId,
            mode: mode,
            questionIdsJson: questionIdsJson,
            answerOrderJson: answerOrderJson,
            status: status,
            startedAt: startedAt,
            completedAt: completedAt,
            contentVersion: contentVersion,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String?> planDate = const Value.absent(),
            Value<String?> reviewQuestionIdsJson = const Value.absent(),
            required String id,
            required String examId,
            required String mode,
            required String questionIdsJson,
            Value<String?> answerOrderJson = const Value.absent(),
            required String status,
            required DateTime startedAt,
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> contentVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PracticeSessionsCompanion.insert(
            planDate: planDate,
            reviewQuestionIdsJson: reviewQuestionIdsJson,
            id: id,
            examId: examId,
            mode: mode,
            questionIdsJson: questionIdsJson,
            answerOrderJson: answerOrderJson,
            status: status,
            startedAt: startedAt,
            completedAt: completedAt,
            contentVersion: contentVersion,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PracticeSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PracticeSessionsTable,
    PracticeSessionRow,
    $$PracticeSessionsTableFilterComposer,
    $$PracticeSessionsTableOrderingComposer,
    $$PracticeSessionsTableAnnotationComposer,
    $$PracticeSessionsTableCreateCompanionBuilder,
    $$PracticeSessionsTableUpdateCompanionBuilder,
    (
      PracticeSessionRow,
      BaseReferences<_$AppDatabase, $PracticeSessionsTable, PracticeSessionRow>
    ),
    PracticeSessionRow,
    PrefetchHooks Function()>;
typedef $$MockAttemptsTableCreateCompanionBuilder = MockAttemptsCompanion
    Function({
  Value<int?> seenBeforeStartCount,
  required String id,
  required String examId,
  required String questionIdsJson,
  Value<String?> answerOrderJson,
  required String answersJson,
  required String flaggedQuestionIdsJson,
  required String status,
  required DateTime startedAt,
  required int durationMinutes,
  Value<int> currentQuestionIndex,
  Value<String?> contentVersion,
  Value<DateTime?> completedAt,
  Value<int?> correctCount,
  Value<int> rowid,
});
typedef $$MockAttemptsTableUpdateCompanionBuilder = MockAttemptsCompanion
    Function({
  Value<int?> seenBeforeStartCount,
  Value<String> id,
  Value<String> examId,
  Value<String> questionIdsJson,
  Value<String?> answerOrderJson,
  Value<String> answersJson,
  Value<String> flaggedQuestionIdsJson,
  Value<String> status,
  Value<DateTime> startedAt,
  Value<int> durationMinutes,
  Value<int> currentQuestionIndex,
  Value<String?> contentVersion,
  Value<DateTime?> completedAt,
  Value<int?> correctCount,
  Value<int> rowid,
});

class $$MockAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $MockAttemptsTable> {
  $$MockAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seenBeforeStartCount => $composableBuilder(
      column: $table.seenBeforeStartCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionIdsJson => $composableBuilder(
      column: $table.questionIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answerOrderJson => $composableBuilder(
      column: $table.answerOrderJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answersJson => $composableBuilder(
      column: $table.answersJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get flaggedQuestionIdsJson => $composableBuilder(
      column: $table.flaggedQuestionIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentQuestionIndex => $composableBuilder(
      column: $table.currentQuestionIndex,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => ColumnFilters(column));
}

class $$MockAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $MockAttemptsTable> {
  $$MockAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seenBeforeStartCount => $composableBuilder(
      column: $table.seenBeforeStartCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionIdsJson => $composableBuilder(
      column: $table.questionIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answerOrderJson => $composableBuilder(
      column: $table.answerOrderJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answersJson => $composableBuilder(
      column: $table.answersJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get flaggedQuestionIdsJson => $composableBuilder(
      column: $table.flaggedQuestionIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentQuestionIndex => $composableBuilder(
      column: $table.currentQuestionIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctCount => $composableBuilder(
      column: $table.correctCount,
      builder: (column) => ColumnOrderings(column));
}

class $$MockAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MockAttemptsTable> {
  $$MockAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seenBeforeStartCount => $composableBuilder(
      column: $table.seenBeforeStartCount, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get examId =>
      $composableBuilder(column: $table.examId, builder: (column) => column);

  GeneratedColumn<String> get questionIdsJson => $composableBuilder(
      column: $table.questionIdsJson, builder: (column) => column);

  GeneratedColumn<String> get answerOrderJson => $composableBuilder(
      column: $table.answerOrderJson, builder: (column) => column);

  GeneratedColumn<String> get answersJson => $composableBuilder(
      column: $table.answersJson, builder: (column) => column);

  GeneratedColumn<String> get flaggedQuestionIdsJson => $composableBuilder(
      column: $table.flaggedQuestionIdsJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<int> get currentQuestionIndex => $composableBuilder(
      column: $table.currentQuestionIndex, builder: (column) => column);

  GeneratedColumn<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => column);
}

class $$MockAttemptsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MockAttemptsTable,
    MockAttemptRow,
    $$MockAttemptsTableFilterComposer,
    $$MockAttemptsTableOrderingComposer,
    $$MockAttemptsTableAnnotationComposer,
    $$MockAttemptsTableCreateCompanionBuilder,
    $$MockAttemptsTableUpdateCompanionBuilder,
    (
      MockAttemptRow,
      BaseReferences<_$AppDatabase, $MockAttemptsTable, MockAttemptRow>
    ),
    MockAttemptRow,
    PrefetchHooks Function()> {
  $$MockAttemptsTableTableManager(_$AppDatabase db, $MockAttemptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MockAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MockAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MockAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int?> seenBeforeStartCount = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> examId = const Value.absent(),
            Value<String> questionIdsJson = const Value.absent(),
            Value<String?> answerOrderJson = const Value.absent(),
            Value<String> answersJson = const Value.absent(),
            Value<String> flaggedQuestionIdsJson = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<int> currentQuestionIndex = const Value.absent(),
            Value<String?> contentVersion = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int?> correctCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MockAttemptsCompanion(
            seenBeforeStartCount: seenBeforeStartCount,
            id: id,
            examId: examId,
            questionIdsJson: questionIdsJson,
            answerOrderJson: answerOrderJson,
            answersJson: answersJson,
            flaggedQuestionIdsJson: flaggedQuestionIdsJson,
            status: status,
            startedAt: startedAt,
            durationMinutes: durationMinutes,
            currentQuestionIndex: currentQuestionIndex,
            contentVersion: contentVersion,
            completedAt: completedAt,
            correctCount: correctCount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<int?> seenBeforeStartCount = const Value.absent(),
            required String id,
            required String examId,
            required String questionIdsJson,
            Value<String?> answerOrderJson = const Value.absent(),
            required String answersJson,
            required String flaggedQuestionIdsJson,
            required String status,
            required DateTime startedAt,
            required int durationMinutes,
            Value<int> currentQuestionIndex = const Value.absent(),
            Value<String?> contentVersion = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int?> correctCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MockAttemptsCompanion.insert(
            seenBeforeStartCount: seenBeforeStartCount,
            id: id,
            examId: examId,
            questionIdsJson: questionIdsJson,
            answerOrderJson: answerOrderJson,
            answersJson: answersJson,
            flaggedQuestionIdsJson: flaggedQuestionIdsJson,
            status: status,
            startedAt: startedAt,
            durationMinutes: durationMinutes,
            currentQuestionIndex: currentQuestionIndex,
            contentVersion: contentVersion,
            completedAt: completedAt,
            correctCount: correctCount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MockAttemptsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MockAttemptsTable,
    MockAttemptRow,
    $$MockAttemptsTableFilterComposer,
    $$MockAttemptsTableOrderingComposer,
    $$MockAttemptsTableAnnotationComposer,
    $$MockAttemptsTableCreateCompanionBuilder,
    $$MockAttemptsTableUpdateCompanionBuilder,
    (
      MockAttemptRow,
      BaseReferences<_$AppDatabase, $MockAttemptsTable, MockAttemptRow>
    ),
    MockAttemptRow,
    PrefetchHooks Function()>;
typedef $$ReadinessSnapshotsTableCreateCompanionBuilder
    = ReadinessSnapshotsCompanion Function({
  required String id,
  required String examId,
  required DateTime calculatedAt,
  required double overallScore,
  required String band,
  required double recentAccuracyComponent,
  required double domainMasteryComponent,
  required double mockPerformanceComponent,
  required double repeatedMasteryComponent,
  required double coverageComponent,
  required double evidenceConfidence,
  required int uniqueQuestionsAnswered,
  Value<int> rowid,
});
typedef $$ReadinessSnapshotsTableUpdateCompanionBuilder
    = ReadinessSnapshotsCompanion Function({
  Value<String> id,
  Value<String> examId,
  Value<DateTime> calculatedAt,
  Value<double> overallScore,
  Value<String> band,
  Value<double> recentAccuracyComponent,
  Value<double> domainMasteryComponent,
  Value<double> mockPerformanceComponent,
  Value<double> repeatedMasteryComponent,
  Value<double> coverageComponent,
  Value<double> evidenceConfidence,
  Value<int> uniqueQuestionsAnswered,
  Value<int> rowid,
});

class $$ReadinessSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadinessSnapshotsTable> {
  $$ReadinessSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get calculatedAt => $composableBuilder(
      column: $table.calculatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get overallScore => $composableBuilder(
      column: $table.overallScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get band => $composableBuilder(
      column: $table.band, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get recentAccuracyComponent => $composableBuilder(
      column: $table.recentAccuracyComponent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get domainMasteryComponent => $composableBuilder(
      column: $table.domainMasteryComponent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get mockPerformanceComponent => $composableBuilder(
      column: $table.mockPerformanceComponent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get repeatedMasteryComponent => $composableBuilder(
      column: $table.repeatedMasteryComponent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get coverageComponent => $composableBuilder(
      column: $table.coverageComponent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get evidenceConfidence => $composableBuilder(
      column: $table.evidenceConfidence,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get uniqueQuestionsAnswered => $composableBuilder(
      column: $table.uniqueQuestionsAnswered,
      builder: (column) => ColumnFilters(column));
}

class $$ReadinessSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadinessSnapshotsTable> {
  $$ReadinessSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get calculatedAt => $composableBuilder(
      column: $table.calculatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get overallScore => $composableBuilder(
      column: $table.overallScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get band => $composableBuilder(
      column: $table.band, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get recentAccuracyComponent => $composableBuilder(
      column: $table.recentAccuracyComponent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get domainMasteryComponent => $composableBuilder(
      column: $table.domainMasteryComponent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get mockPerformanceComponent => $composableBuilder(
      column: $table.mockPerformanceComponent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get repeatedMasteryComponent => $composableBuilder(
      column: $table.repeatedMasteryComponent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get coverageComponent => $composableBuilder(
      column: $table.coverageComponent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get evidenceConfidence => $composableBuilder(
      column: $table.evidenceConfidence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uniqueQuestionsAnswered => $composableBuilder(
      column: $table.uniqueQuestionsAnswered,
      builder: (column) => ColumnOrderings(column));
}

class $$ReadinessSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadinessSnapshotsTable> {
  $$ReadinessSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get examId =>
      $composableBuilder(column: $table.examId, builder: (column) => column);

  GeneratedColumn<DateTime> get calculatedAt => $composableBuilder(
      column: $table.calculatedAt, builder: (column) => column);

  GeneratedColumn<double> get overallScore => $composableBuilder(
      column: $table.overallScore, builder: (column) => column);

  GeneratedColumn<String> get band =>
      $composableBuilder(column: $table.band, builder: (column) => column);

  GeneratedColumn<double> get recentAccuracyComponent => $composableBuilder(
      column: $table.recentAccuracyComponent, builder: (column) => column);

  GeneratedColumn<double> get domainMasteryComponent => $composableBuilder(
      column: $table.domainMasteryComponent, builder: (column) => column);

  GeneratedColumn<double> get mockPerformanceComponent => $composableBuilder(
      column: $table.mockPerformanceComponent, builder: (column) => column);

  GeneratedColumn<double> get repeatedMasteryComponent => $composableBuilder(
      column: $table.repeatedMasteryComponent, builder: (column) => column);

  GeneratedColumn<double> get coverageComponent => $composableBuilder(
      column: $table.coverageComponent, builder: (column) => column);

  GeneratedColumn<double> get evidenceConfidence => $composableBuilder(
      column: $table.evidenceConfidence, builder: (column) => column);

  GeneratedColumn<int> get uniqueQuestionsAnswered => $composableBuilder(
      column: $table.uniqueQuestionsAnswered, builder: (column) => column);
}

class $$ReadinessSnapshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReadinessSnapshotsTable,
    ReadinessSnapshotRow,
    $$ReadinessSnapshotsTableFilterComposer,
    $$ReadinessSnapshotsTableOrderingComposer,
    $$ReadinessSnapshotsTableAnnotationComposer,
    $$ReadinessSnapshotsTableCreateCompanionBuilder,
    $$ReadinessSnapshotsTableUpdateCompanionBuilder,
    (
      ReadinessSnapshotRow,
      BaseReferences<_$AppDatabase, $ReadinessSnapshotsTable,
          ReadinessSnapshotRow>
    ),
    ReadinessSnapshotRow,
    PrefetchHooks Function()> {
  $$ReadinessSnapshotsTableTableManager(
      _$AppDatabase db, $ReadinessSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadinessSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadinessSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadinessSnapshotsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> examId = const Value.absent(),
            Value<DateTime> calculatedAt = const Value.absent(),
            Value<double> overallScore = const Value.absent(),
            Value<String> band = const Value.absent(),
            Value<double> recentAccuracyComponent = const Value.absent(),
            Value<double> domainMasteryComponent = const Value.absent(),
            Value<double> mockPerformanceComponent = const Value.absent(),
            Value<double> repeatedMasteryComponent = const Value.absent(),
            Value<double> coverageComponent = const Value.absent(),
            Value<double> evidenceConfidence = const Value.absent(),
            Value<int> uniqueQuestionsAnswered = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReadinessSnapshotsCompanion(
            id: id,
            examId: examId,
            calculatedAt: calculatedAt,
            overallScore: overallScore,
            band: band,
            recentAccuracyComponent: recentAccuracyComponent,
            domainMasteryComponent: domainMasteryComponent,
            mockPerformanceComponent: mockPerformanceComponent,
            repeatedMasteryComponent: repeatedMasteryComponent,
            coverageComponent: coverageComponent,
            evidenceConfidence: evidenceConfidence,
            uniqueQuestionsAnswered: uniqueQuestionsAnswered,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String examId,
            required DateTime calculatedAt,
            required double overallScore,
            required String band,
            required double recentAccuracyComponent,
            required double domainMasteryComponent,
            required double mockPerformanceComponent,
            required double repeatedMasteryComponent,
            required double coverageComponent,
            required double evidenceConfidence,
            required int uniqueQuestionsAnswered,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReadinessSnapshotsCompanion.insert(
            id: id,
            examId: examId,
            calculatedAt: calculatedAt,
            overallScore: overallScore,
            band: band,
            recentAccuracyComponent: recentAccuracyComponent,
            domainMasteryComponent: domainMasteryComponent,
            mockPerformanceComponent: mockPerformanceComponent,
            repeatedMasteryComponent: repeatedMasteryComponent,
            coverageComponent: coverageComponent,
            evidenceConfidence: evidenceConfidence,
            uniqueQuestionsAnswered: uniqueQuestionsAnswered,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReadinessSnapshotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReadinessSnapshotsTable,
    ReadinessSnapshotRow,
    $$ReadinessSnapshotsTableFilterComposer,
    $$ReadinessSnapshotsTableOrderingComposer,
    $$ReadinessSnapshotsTableAnnotationComposer,
    $$ReadinessSnapshotsTableCreateCompanionBuilder,
    $$ReadinessSnapshotsTableUpdateCompanionBuilder,
    (
      ReadinessSnapshotRow,
      BaseReferences<_$AppDatabase, $ReadinessSnapshotsTable,
          ReadinessSnapshotRow>
    ),
    ReadinessSnapshotRow,
    PrefetchHooks Function()>;
typedef $$UserProfilesTableCreateCompanionBuilder = UserProfilesCompanion
    Function({
  Value<String?> studyPlanPreferencesJson,
  required String examId,
  required String experienceLevel,
  required String examDatePrecision,
  Value<DateTime?> examDate,
  required int dailyGoalQuestions,
  required bool notificationsEnabled,
  required String themePreference,
  required bool onboardingComplete,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$UserProfilesTableUpdateCompanionBuilder = UserProfilesCompanion
    Function({
  Value<String?> studyPlanPreferencesJson,
  Value<String> examId,
  Value<String> experienceLevel,
  Value<String> examDatePrecision,
  Value<DateTime?> examDate,
  Value<int> dailyGoalQuestions,
  Value<bool> notificationsEnabled,
  Value<String> themePreference,
  Value<bool> onboardingComplete,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get studyPlanPreferencesJson => $composableBuilder(
      column: $table.studyPlanPreferencesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get experienceLevel => $composableBuilder(
      column: $table.experienceLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get examDatePrecision => $composableBuilder(
      column: $table.examDatePrecision,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get examDate => $composableBuilder(
      column: $table.examDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyGoalQuestions => $composableBuilder(
      column: $table.dailyGoalQuestions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themePreference => $composableBuilder(
      column: $table.themePreference,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get onboardingComplete => $composableBuilder(
      column: $table.onboardingComplete,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get studyPlanPreferencesJson => $composableBuilder(
      column: $table.studyPlanPreferencesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get experienceLevel => $composableBuilder(
      column: $table.experienceLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get examDatePrecision => $composableBuilder(
      column: $table.examDatePrecision,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get examDate => $composableBuilder(
      column: $table.examDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyGoalQuestions => $composableBuilder(
      column: $table.dailyGoalQuestions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themePreference => $composableBuilder(
      column: $table.themePreference,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get onboardingComplete => $composableBuilder(
      column: $table.onboardingComplete,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get studyPlanPreferencesJson => $composableBuilder(
      column: $table.studyPlanPreferencesJson, builder: (column) => column);

  GeneratedColumn<String> get examId =>
      $composableBuilder(column: $table.examId, builder: (column) => column);

  GeneratedColumn<String> get experienceLevel => $composableBuilder(
      column: $table.experienceLevel, builder: (column) => column);

  GeneratedColumn<String> get examDatePrecision => $composableBuilder(
      column: $table.examDatePrecision, builder: (column) => column);

  GeneratedColumn<DateTime> get examDate =>
      $composableBuilder(column: $table.examDate, builder: (column) => column);

  GeneratedColumn<int> get dailyGoalQuestions => $composableBuilder(
      column: $table.dailyGoalQuestions, builder: (column) => column);

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled, builder: (column) => column);

  GeneratedColumn<String> get themePreference => $composableBuilder(
      column: $table.themePreference, builder: (column) => column);

  GeneratedColumn<bool> get onboardingComplete => $composableBuilder(
      column: $table.onboardingComplete, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserProfilesTable,
    UserProfileRow,
    $$UserProfilesTableFilterComposer,
    $$UserProfilesTableOrderingComposer,
    $$UserProfilesTableAnnotationComposer,
    $$UserProfilesTableCreateCompanionBuilder,
    $$UserProfilesTableUpdateCompanionBuilder,
    (
      UserProfileRow,
      BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow>
    ),
    UserProfileRow,
    PrefetchHooks Function()> {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String?> studyPlanPreferencesJson = const Value.absent(),
            Value<String> examId = const Value.absent(),
            Value<String> experienceLevel = const Value.absent(),
            Value<String> examDatePrecision = const Value.absent(),
            Value<DateTime?> examDate = const Value.absent(),
            Value<int> dailyGoalQuestions = const Value.absent(),
            Value<bool> notificationsEnabled = const Value.absent(),
            Value<String> themePreference = const Value.absent(),
            Value<bool> onboardingComplete = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProfilesCompanion(
            studyPlanPreferencesJson: studyPlanPreferencesJson,
            examId: examId,
            experienceLevel: experienceLevel,
            examDatePrecision: examDatePrecision,
            examDate: examDate,
            dailyGoalQuestions: dailyGoalQuestions,
            notificationsEnabled: notificationsEnabled,
            themePreference: themePreference,
            onboardingComplete: onboardingComplete,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String?> studyPlanPreferencesJson = const Value.absent(),
            required String examId,
            required String experienceLevel,
            required String examDatePrecision,
            Value<DateTime?> examDate = const Value.absent(),
            required int dailyGoalQuestions,
            required bool notificationsEnabled,
            required String themePreference,
            required bool onboardingComplete,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProfilesCompanion.insert(
            studyPlanPreferencesJson: studyPlanPreferencesJson,
            examId: examId,
            experienceLevel: experienceLevel,
            examDatePrecision: examDatePrecision,
            examDate: examDate,
            dailyGoalQuestions: dailyGoalQuestions,
            notificationsEnabled: notificationsEnabled,
            themePreference: themePreference,
            onboardingComplete: onboardingComplete,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserProfilesTable,
    UserProfileRow,
    $$UserProfilesTableFilterComposer,
    $$UserProfilesTableOrderingComposer,
    $$UserProfilesTableAnnotationComposer,
    $$UserProfilesTableCreateCompanionBuilder,
    $$UserProfilesTableUpdateCompanionBuilder,
    (
      UserProfileRow,
      BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow>
    ),
    UserProfileRow,
    PrefetchHooks Function()>;
typedef $$StudySchedulesTableCreateCompanionBuilder = StudySchedulesCompanion
    Function({
  required String examId,
  required String date,
  required String kind,
  Value<int?> minutes,
  required String reservedQuestionIdsJson,
  Value<int> rowid,
});
typedef $$StudySchedulesTableUpdateCompanionBuilder = StudySchedulesCompanion
    Function({
  Value<String> examId,
  Value<String> date,
  Value<String> kind,
  Value<int?> minutes,
  Value<String> reservedQuestionIdsJson,
  Value<int> rowid,
});

class $$StudySchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $StudySchedulesTable> {
  $$StudySchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minutes => $composableBuilder(
      column: $table.minutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reservedQuestionIdsJson => $composableBuilder(
      column: $table.reservedQuestionIdsJson,
      builder: (column) => ColumnFilters(column));
}

class $$StudySchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $StudySchedulesTable> {
  $$StudySchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minutes => $composableBuilder(
      column: $table.minutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reservedQuestionIdsJson => $composableBuilder(
      column: $table.reservedQuestionIdsJson,
      builder: (column) => ColumnOrderings(column));
}

class $$StudySchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudySchedulesTable> {
  $$StudySchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get examId =>
      $composableBuilder(column: $table.examId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<String> get reservedQuestionIdsJson => $composableBuilder(
      column: $table.reservedQuestionIdsJson, builder: (column) => column);
}

class $$StudySchedulesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StudySchedulesTable,
    StudyScheduleRow,
    $$StudySchedulesTableFilterComposer,
    $$StudySchedulesTableOrderingComposer,
    $$StudySchedulesTableAnnotationComposer,
    $$StudySchedulesTableCreateCompanionBuilder,
    $$StudySchedulesTableUpdateCompanionBuilder,
    (
      StudyScheduleRow,
      BaseReferences<_$AppDatabase, $StudySchedulesTable, StudyScheduleRow>
    ),
    StudyScheduleRow,
    PrefetchHooks Function()> {
  $$StudySchedulesTableTableManager(
      _$AppDatabase db, $StudySchedulesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudySchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudySchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudySchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> examId = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int?> minutes = const Value.absent(),
            Value<String> reservedQuestionIdsJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudySchedulesCompanion(
            examId: examId,
            date: date,
            kind: kind,
            minutes: minutes,
            reservedQuestionIdsJson: reservedQuestionIdsJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String examId,
            required String date,
            required String kind,
            Value<int?> minutes = const Value.absent(),
            required String reservedQuestionIdsJson,
            Value<int> rowid = const Value.absent(),
          }) =>
              StudySchedulesCompanion.insert(
            examId: examId,
            date: date,
            kind: kind,
            minutes: minutes,
            reservedQuestionIdsJson: reservedQuestionIdsJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StudySchedulesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StudySchedulesTable,
    StudyScheduleRow,
    $$StudySchedulesTableFilterComposer,
    $$StudySchedulesTableOrderingComposer,
    $$StudySchedulesTableAnnotationComposer,
    $$StudySchedulesTableCreateCompanionBuilder,
    $$StudySchedulesTableUpdateCompanionBuilder,
    (
      StudyScheduleRow,
      BaseReferences<_$AppDatabase, $StudySchedulesTable, StudyScheduleRow>
    ),
    StudyScheduleRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AnswerAttemptsTableTableManager get answerAttempts =>
      $$AnswerAttemptsTableTableManager(_db, _db.answerAttempts);
  $$QuestionStatesTableTableManager get questionStates =>
      $$QuestionStatesTableTableManager(_db, _db.questionStates);
  $$PracticeSessionsTableTableManager get practiceSessions =>
      $$PracticeSessionsTableTableManager(_db, _db.practiceSessions);
  $$MockAttemptsTableTableManager get mockAttempts =>
      $$MockAttemptsTableTableManager(_db, _db.mockAttempts);
  $$ReadinessSnapshotsTableTableManager get readinessSnapshots =>
      $$ReadinessSnapshotsTableTableManager(_db, _db.readinessSnapshots);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$StudySchedulesTableTableManager get studySchedules =>
      $$StudySchedulesTableTableManager(_db, _db.studySchedules);
}
