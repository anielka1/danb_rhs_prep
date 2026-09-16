import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/data/repositories/drift_user_settings_repository.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_content_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/sync/content_release.dart';
import 'package:danb_rhs_prep/features/content/sync/content_release_database.dart';
import 'package:danb_rhs_prep/features/content/sync/remote_content_source.dart';
import 'package:danb_rhs_prep/features/content/sync/supabase_remote_content_source.dart';
import 'package:danb_rhs_prep/features/content/sync/synced_content_repository.dart';

const examId = 'danb_rhs';
final now = DateTime.utc(2026, 9, 14);
Map<String, Object?> payload(int version) {
  final data = jsonDecode(
          File('assets/content/danb_rhs/content.json').readAsStringSync())
      as Map<String, dynamic>;
  data['contentVersion'] = 'fixture-$version';
  (data['exam'] as Map)['contentVersion'] = 'fixture-$version';
  // Isolated test copy only. No content asset or reviewer decision is changed.
  for (final q in data['questions'] as List) {
    q['status'] = 'approved';
  }
  return data;
}

Map<String, Object?> record(int version) {
  final data = payload(version);
  return {
    'exam_id': examId,
    'release_version': version,
    'schema_version': 1,
    'content_version': data['contentVersion'],
    'question_count': (data['questions'] as List).length,
    'payload': data,
    'content_sha256': contentPayloadSha256(data),
    'published_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'retired_at': null
  };
}

class FakeRemote implements RemoteContentSource {
  FakeRemote(this.value);
  Map<String, Object?>? value;
  Object? error;
  Completer<Map<String, Object?>?>? pending;
  int calls = 0;
  @override
  Future<Map<String, Object?>?> latestRelease(
      String examId, DateTime now) async {
    calls++;
    if (error != null) throw error!;
    if (pending != null) return await pending!.future;
    return value;
  }
}

class UnreadableProgress extends InMemoryProgressRepository {
  @override
  Future<PracticeSession?> inProgressPracticeSession(String examId) async {
    throw StateError('fixture progress read failure');
  }
}

void main() {
  late ContentReleaseDatabase db;
  late InMemoryProgressRepository progress;
  final bundled = InMemoryContentRepository({
    examId: const ExamContentCodec()
        .decode(File('assets/content/danb_rhs/content.json').readAsStringSync())
  });
  SyncedContentRepository repo([RemoteContentSource? remote]) =>
      SyncedContentRepository(
          bundled: bundled,
          database: db,
          progress: progress,
          remote: remote,
          now: () => now);
  setUp(() {
    db = ContentReleaseDatabase.forTesting(NativeDatabase.memory());
    progress = InMemoryProgressRepository();
  });
  tearDown(() => db.close());

  test('no configuration disables remote; rejects secret, JWT and unsafe URL',
      () async {
    expect(
        SupabaseRemoteContentSource.fromConfiguration(
            url: '', publishableKey: ''),
        isNull);
    for (final key in ['sb_secret_fixture', 'eyJfixture', '', 'service_role']) {
      expect(
          SupabaseRemoteContentSource.fromConfiguration(
              url: 'https://example.invalid', publishableKey: key),
          isNull);
    }
    expect(
        SupabaseRemoteContentSource.fromConfiguration(
            url: 'http://example.invalid',
            publishableKey: 'sb_publishable_fixture'),
        isNull);
    expect(
        SupabaseRemoteContentSource.fromConfiguration(
            url: 'https://example.invalid',
            publishableKey: 'sb_publishable_fixture'),
        isNotNull);
    expect(await repo().sync(examId), ContentSyncResult.disabled);
    expect((await repo().loadContentPackage(examId)).contentVersion,
        (await bundled.loadContentPackage(examId)).contentVersion);
  });

  test('no publication is normal and retains bundle', () async {
    final remote = FakeRemote(null);
    final repository = repo(remote);
    final result = await repository.loadContentPackage(examId);
    expect(result, await bundled.loadContentPackage(examId));
    expect(await repository.sync(examId), ContentSyncResult.noRelease);
    expect(await db.releases(examId), isEmpty);
    expect(remote.calls, 1);
  });

  test('offline and SDK failures retain last good release', () async {
    await repo(FakeRemote(record(1))).sync(examId);
    for (final error in [
      const SocketException('offline'),
      StateError('server')
    ]) {
      final remote = FakeRemote(null)..error = error;
      final repository = repo(remote);
      expect((await repository.loadContentPackage(examId)).contentVersion,
          'fixture-1');
      expect(await repository.sync(examId), ContentSyncResult.rejected);
      expect((await db.releases(examId)).length, 1);
    }
  });

  test('network never blocks bootstrap or changes a running snapshot',
      () async {
    final remote = FakeRemote(null)..pending = Completer();
    final repository = repo(remote);
    final first = await repository
        .loadContentPackage(examId)
        .timeout(const Duration(seconds: 2));
    remote.pending!.complete(record(1));
    expect(await repository.sync(examId), ContentSyncResult.installed);
    expect(await repository.loadContentPackage(examId), same(first));
    expect(
        (await repo().loadContentPackage(examId)).contentVersion, 'fixture-1');
  });

  test('newer installs; identical and older do not overwrite', () async {
    expect(await repo(FakeRemote(record(2))).sync(examId),
        ContentSyncResult.installed);
    for (final version in [2, 1]) {
      expect(await repo(FakeRemote(record(version))).sync(examId),
          ContentSyncResult.unchanged);
    }
    expect((await db.releases(examId)).single.releaseVersion, 2);
    expect(await repo(FakeRemote(record(3))).sync(examId),
        ContentSyncResult.installed);
    expect((await db.releases(examId)).map((r) => r.releaseVersion), [3, 2]);
  });

  final invalid = <String, void Function(Map<String, Object?>)>{
    'hash': (r) => r['content_sha256'] = '0' * 64,
    'invalid JSON string': (r) => r['payload'] = '{broken',
    'non-object JSON': (r) => r['payload'] = [],
    'schema': (r) => r['schema_version'] = 2,
    'exam': (r) => r['exam_id'] = 'other',
    'release version': (r) => r['release_version'] = 0,
    'fractional version': (r) => r['release_version'] = 2.5,
    'content version': (r) => r['content_version'] = 'mismatch',
    'count': (r) => r['question_count'] = 900,
    'retired': (r) => r['retired_at'] = now.toIso8601String(),
    'future': (r) =>
        r['published_at'] = now.add(const Duration(days: 1)).toIso8601String(),
    'missing publication': (r) => r['published_at'] = null,
    'validator failure': (r) {
      final p = r['payload'] as Map<String, Object?>;
      ((p['questions'] as List).first as Map)['correctAnswerId'] =
          'not-an-answer';
      r['content_sha256'] = contentPayloadSha256(p);
    },
    'draft even with valid checksum': (r) {
      final p = r['payload'] as Map<String, Object?>;
      ((p['questions'] as List).first as Map)['status'] = 'draft';
      r['content_sha256'] = contentPayloadSha256(p);
    },
  };
  for (final entry in invalid.entries) {
    test('${entry.key} rejects without replacing last good bank', () async {
      await repo(FakeRemote(record(1))).sync(examId);
      final broken = record(2);
      entry.value(broken);
      expect(await repo(FakeRemote(broken)).sync(examId),
          ContentSyncResult.rejected);
      expect((await repo().loadContentPackage(examId)).contentVersion,
          'fixture-1');
      expect((await db.releases(examId)).length, 1);
    });
  }

  test('database write failure rolls back and retains previous version',
      () async {
    await repo(FakeRemote(record(1))).sync(examId);
    await db.customStatement(
        "CREATE TRIGGER fail_insert AFTER INSERT ON cached_releases "
        "BEGIN SELECT RAISE(ABORT, 'fixture disk write failure'); END");
    expect(await repo(FakeRemote(record(2))).sync(examId),
        ContentSyncResult.rejected);
    expect((await db.releases(examId)).single.releaseVersion, 1);
    expect(
        (await repo().loadContentPackage(examId)).contentVersion, 'fixture-1');
  });

  test('activation failure after clearing flag rolls back', () async {
    await repo(FakeRemote(record(1))).sync(examId);
    await repo().loadContentPackage(examId);
    await repo(FakeRemote(record(2))).sync(examId);
    await db.customStatement(
        "CREATE TRIGGER fail_activate BEFORE UPDATE ON cached_releases "
        "WHEN NEW.active = 1 AND NEW.release_version = 2 "
        "BEGIN SELECT RAISE(ABORT, 'fixture activation failure'); END");
    expect(
        (await repo().loadContentPackage(examId)).contentVersion, 'fixture-1');
    expect(
        (await db.releases(examId)).singleWhere((r) => r.active).releaseVersion,
        1);
  });

  test('corrupt newest cached JSON falls back to previous validated bank',
      () async {
    await repo(FakeRemote(record(1))).sync(examId);
    await repo(FakeRemote(record(2))).sync(examId);
    await db.customStatement(
        "UPDATE cached_releases SET record_json = '{broken' WHERE release_version = 2");
    expect(
        (await repo().loadContentPackage(examId)).contentVersion, 'fixture-1');
    expect((await db.releases(examId)).length, 2);
  });

  for (final mock in [false, true]) {
    test(
        '${mock ? 'mock' : 'practice'} keeps active bank and saved answer order',
        () async {
      await repo(FakeRemote(record(1))).sync(examId);
      final old = await repo().loadContentPackage(examId);
      final q = old.questions.first;
      final order = {q.id: q.answers.reversed.map((a) => a.id).toList()};
      if (mock) {
        await progress.saveMockAttempt(MockAttempt(
            id: 'mock',
            examId: examId,
            questionIds: [q.id],
            answerOrder: order,
            answers: {q.id: q.correctAnswerId},
            flaggedQuestionIds: {},
            status: MockAttemptStatus.inProgress,
            startedAt: now,
            durationMinutes: 30,
            contentVersion: old.contentVersion));
      } else {
        await progress.savePracticeSession(PracticeSession(
            id: 'practice',
            examId: examId,
            questionIds: [q.id],
            answerOrder: order,
            mode: PracticeMode.quickPractice,
            status: SessionStatus.inProgress,
            startedAt: now,
            contentVersion: old.contentVersion));
      }
      await repo(FakeRemote(record(2))).sync(examId);
      expect((await repo().loadContentPackage(examId)).contentVersion,
          old.contentVersion);
      if (mock) {
        final saved = (await progress.mockAttemptsForExam(examId)).single;
        expect(saved.answerOrder, order);
        expect(saved.answers, {q.id: q.correctAnswerId});
      } else {
        expect((await progress.inProgressPracticeSession(examId))!.answerOrder,
            order);
      }
    });
  }

  test('failed progress read keeps activated bank and defers new activation',
      () async {
    await repo(FakeRemote(record(1))).sync(examId);
    await repo().loadContentPackage(examId);
    await repo(FakeRemote(record(2))).sync(examId);
    progress = UnreadableProgress();
    expect(
        (await repo().loadContentPackage(examId)).contentVersion, 'fixture-1');
    expect(
        (await db.releases(examId)).singleWhere((r) => r.active).releaseVersion,
        1);
  });

  test('finished practice allows pending bank at next bootstrap', () async {
    await repo(FakeRemote(record(1))).sync(examId);
    final old = await repo().loadContentPackage(examId);
    final session = PracticeSession(
        id: 'pending',
        examId: examId,
        questionIds: [old.questions.first.id],
        mode: PracticeMode.quickPractice,
        status: SessionStatus.inProgress,
        startedAt: now,
        contentVersion: old.contentVersion);
    await progress.savePracticeSession(session);
    await repo(FakeRemote(record(2))).sync(examId);
    expect(
        (await repo().loadContentPackage(examId)).contentVersion, 'fixture-1');
    await progress.savePracticeSession(
        session.copyWith(status: SessionStatus.completed, completedAt: now));
    expect(
        (await repo().loadContentPackage(examId)).contentVersion, 'fixture-2');
  });

  test('reused content version cannot install a different snapshot', () async {
    await repo(FakeRemote(record(1))).sync(examId);
    final reused = record(1)..['release_version'] = 2;
    expect(await repo(FakeRemote(reused)).sync(examId),
        ContentSyncResult.rejected);
    expect((await db.releases(examId)).single.releaseVersion, 1);
  });

  test('legacy session without a version keeps bundled bank', () async {
    await progress.savePracticeSession(PracticeSession(
        id: 'legacy',
        examId: examId,
        questionIds: ['old'],
        mode: PracticeMode.quickPractice,
        status: SessionStatus.inProgress,
        startedAt: now));
    await repo(FakeRemote(record(1))).sync(examId);
    expect((await repo().loadContentPackage(examId)).contentVersion,
        (await bundled.loadContentPackage(examId)).contentVersion);
  });

  test(
      'full bootstrap stays offline-first and leaves all progress tables unchanged',
      () async {
    final appDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(appDb.close);
    final savedProgress = DriftProgressRepository(appDb);
    final settings = DriftUserSettingsRepository(appDb);
    final q = (await bundled.loadContentPackage(examId)).questions.first;
    await savedProgress.recordAnswerAttempt(AnswerAttempt(
        id: 'history',
        examId: examId,
        questionId: q.id,
        domainId: q.domainId,
        topicId: q.topicId,
        difficulty: q.difficulty,
        sessionId: 'historical-session',
        sessionType: AttemptSessionType.diagnostic,
        selectedAnswerId: q.correctAnswerId,
        isCorrect: true,
        answeredAt: now,
        contentVersion: 'historical-bank'));
    await savedProgress.saveQuestionState(
        QuestionState.unseen(examId: examId, questionId: q.id)
            .copyWith(bookmarked: true));
    await settings.saveProfile(UserProfile(
        experienceLevel: null,
        examId: examId,
        examDatePrecision: ExamDatePrecision.exact,
        examDate: now.add(const Duration(days: 30)),
        dailyGoalQuestions: 10,
        notificationsEnabled: false,
        themePreference: ThemePreference.dark,
        onboardingComplete: true,
        createdAt: now,
        updatedAt: now));
    Future<Map<String, Object?>> snapshot() async => {
          for (final table in appDb.allTables)
            table.actualTableName: (await appDb
                    .customSelect('SELECT * FROM "${table.actualTableName}"')
                    .get())
                .map((r) => r.data)
                .toList(),
        };
    final before = await snapshot();
    final local = InMemoryBootstrapLocalStore(
        selectedExamId: examId, onboardingComplete: true);
    final remote = FakeRemote(null)..pending = Completer();
    final content = SyncedContentRepository(
        bundled: bundled,
        database: db,
        progress: savedProgress,
        remote: remote,
        now: () => now);
    final ready = await AppBootstrapService(
            contentRepository: content,
            localStore: local,
            userSettingsRepository: settings)
        .initialize()
        .timeout(const Duration(seconds: 2));
    expect(ready, isA<BootstrapReady>());
    expect((ready as BootstrapReady).onboardingComplete, isTrue);
    remote.pending!.complete(record(1));
    expect(await content.sync(examId), ContentSyncResult.installed);
    final afterRestart = SyncedContentRepository(
        bundled: bundled,
        database: db,
        progress: savedProgress,
        now: () => now);
    expect((await afterRestart.loadContentPackage(examId)).contentVersion,
        'fixture-1');
    expect(await snapshot(), before);
    expect(appDb.schemaVersion, 6);
    expect(await local.readOnboardingComplete(), isTrue);
  });

  test('canonical hash is independent of map order and numeric scale', () {
    expect(
        canonicalPayloadJson({
          'z': 1.0,
          'a': ['é', true, null]
        }),
        '{"a":["é",true,null],"z":1}');
    // Independent SHA-256 reference for the literal UTF-8 bytes below.
    expect(contentPayloadSha256({'a': 2, 'z': 1}),
        'c2985c5ba6f7d2a55e768f92490ca09388e95bc4cccb9fdf11b15f4d42f93e73');
    expect(contentPayloadSha256({'z': 1.0, 'a': 2}),
        contentPayloadSha256({'a': 2.0, 'z': 1}));
    expect(
        contentPayloadSha256({
          'a': [1, 2]
        }),
        isNot(contentPayloadSha256({
          'a': [2, 1]
        })));
    expect(() => canonicalPayloadJson(double.nan), throwsFormatException);
  });

  test('disk cache survives actual close and reopen without a remote',
      () async {
    final dir = Directory.systemTemp.createTempSync('rhs-release-test');
    final file = File('${dir.path}/banks.sqlite');
    final disk = ContentReleaseDatabase.forTesting(NativeDatabase(file));
    await disk
        .install(ContentRelease.validate(record(1), examId: examId, now: now));
    await disk.close();
    final reopened = ContentReleaseDatabase.forTesting(NativeDatabase(file));
    try {
      final repository = SyncedContentRepository(
          bundled: bundled,
          database: reopened,
          progress: progress,
          now: () => now);
      expect((await repository.loadContentPackage(examId)).contentVersion,
          'fixture-1');
    } finally {
      await reopened.close();
      dir.deleteSync(recursive: true);
    }
  });
}
