import 'dart:async';
import 'dart:convert';
import '../../../domain/models/mock_attempt.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../../domain/repositories/progress_repository.dart';
import '../domain/content_package.dart';
import 'content_release.dart';
import 'content_release_database.dart';
import 'remote_content_source.dart';

enum ContentSyncResult { disabled, noRelease, unchanged, installed, rejected }

/// Bounded cold-start refresh, followed by one immutable package per process.
class SyncedContentRepository implements ContentRepository {
  SyncedContentRepository({
    required this.bundled,
    required this.database,
    required this.progress,
    this.remote,
    this.onUpdating,
    this.versionTimeout = const Duration(seconds: 1),
    this.downloadTimeout = const Duration(seconds: 8),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final ContentRepository bundled;
  final ContentReleaseDatabase database;
  final ProgressRepository progress;
  final RemoteContentSource? remote;
  final void Function(bool)? onUpdating;
  final Duration versionTimeout;
  final Duration downloadTimeout;
  final DateTime Function() _now;
  final Map<String, Future<ContentPackage>> _loads = {};
  final Map<String, Future<ContentSyncResult>> _syncs = {};

  @override
  Future<ContentPackage> loadContentPackage(String examId) =>
      _loads.putIfAbsent(examId, () => _load(examId));

  Future<ContentPackage> _load(String examId) async {
    final fallback = await bundled.loadContentPackage(examId);
    await sync(examId, bundledContentVersion: fallback.contentVersion);
    ContentPackage selected = fallback;
    try {
      final rows = await database.releases(examId);
      // An unreadable session store is not evidence that no session exists.
      // Keep the activated bank until we can establish that activation is safe.
      var busy = true;
      try {
        final practice = await progress.inProgressPracticeSession(examId);
        final mocks = await progress.mockAttemptsForExam(examId);
        busy = practice != null ||
            mocks.any((m) => m.status == MockAttemptStatus.inProgress);
      } on Object {
        // Session screens retain their own error/retry behavior.
      }
      for (final row in rows) {
        // A pending session stays on the previously activated bank. No active
        // row means it started with the bundled bank, including legacy sessions.
        if (busy && !row.active) continue;
        try {
          final release = ContentRelease.validate(
            Map<String, Object?>.from(jsonDecode(row.recordJson) as Map),
            examId: examId,
            now: _now(),
          );
          if (!busy && !row.active) await database.activate(row);
          selected = release.package;
          break;
        } on Object {
          // Keep earlier verified releases available; never delete on a read error.
        }
      }
    } on Object {
      // Cache unavailable: bundled content still starts offline.
    }
    return selected;
  }

  Future<ContentSyncResult> sync(
    String examId, {
    String? bundledContentVersion,
  }) =>
      _syncs.putIfAbsent(examId, () async {
        if (remote == null) return ContentSyncResult.disabled;
        try {
          final cached = await database.releases(examId);
          final version = await remote!
              .latestVersion(examId, _now().toUtc())
              .timeout(versionTimeout);
          if (version == null) return ContentSyncResult.noRelease;
          if (version <= 0) return ContentSyncResult.rejected;
          if (cached.any((row) => row.releaseVersion >= version)) {
            return ContentSyncResult.unchanged;
          }
          onUpdating?.call(true);
          final record = await remote!
              .release(examId, version, _now().toUtc())
              .timeout(downloadTimeout);
          if (record != null && record['release_version'] != version) {
            return ContentSyncResult.rejected;
          }
          if (record == null) return ContentSyncResult.noRelease;
          final release = ContentRelease.validate(
            record,
            examId: examId,
            now: _now(),
          );
          if (release.package.contentVersion == bundledContentVersion) {
            return ContentSyncResult.unchanged;
          }
          return await database.install(release)
              ? ContentSyncResult.installed
              : ContentSyncResult.unchanged;
        } on Object {
          // No credentials, payloads, user data or raw SDK errors in logs/UI.
          return ContentSyncResult.rejected;
        } finally {
          onUpdating?.call(false);
        }
      });
}
