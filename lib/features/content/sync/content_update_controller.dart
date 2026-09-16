import 'package:flutter/foundation.dart';
import '../domain/content_package.dart';
import 'synced_content_repository.dart';

enum ContentUpdateStatus {
  idle,
  downloading,
  pending,
  failed,
  unavailable,
  ready
}

/// Owns one background request at a time; never grants access or changes history.
class ContentUpdateController extends ChangeNotifier {
  ContentUpdateController(this.repository);
  final SyncedContentRepository repository;
  ContentUpdateStatus status = ContentUpdateStatus.idle;
  bool activating = false;
  bool _disposed = false;
  String? _examId;
  Future<void>? _request;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start(String examId) {
    if (_examId != null) return _request ?? Future.value();
    _examId = examId;
    return retry();
  }

  Future<void> retry() {
    if (_request != null) return _request!;
    if (_examId == null || activating || _disposed) return Future.value();
    status = ContentUpdateStatus.downloading;
    _notify();
    return _request = _download().whenComplete(() => _request = null);
  }

  Future<void> _download() async {
    try {
      final result = await repository.retrySync(_examId!);
      if (_disposed) return;
      status = switch (result) {
        ContentSyncResult.installed ||
        ContentSyncResult.unchanged =>
          ContentUpdateStatus.pending,
        ContentSyncResult.rejected => ContentUpdateStatus.failed,
        ContentSyncResult.disabled ||
        ContentSyncResult.noRelease =>
          ContentUpdateStatus.unavailable,
      };
    } on Object {
      status = ContentUpdateStatus.failed;
    }
    _notify();
  }

  /// Caller must keep navigation/input locked until this future completes.
  Future<ContentPackage?> activate() async {
    if (activating || status != ContentUpdateStatus.pending) return null;
    activating = true;
    _notify();
    try {
      return await repository.activateDownloadedContent(_examId!);
    } on Object {
      status = ContentUpdateStatus.failed;
      return null;
    } finally {
      activating = false;
      _notify();
    }
  }

  void navigationChanged() => _notify();

  void applied() {
    status = ContentUpdateStatus.ready;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
