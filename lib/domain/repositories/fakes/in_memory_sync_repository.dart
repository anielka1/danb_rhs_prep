import 'dart:async';

import '../sync_repository.dart';

/// An in-memory [SyncRepository] for unit tests and previews. Tests can
/// call [setStatus] to simulate sign-in, syncing, and error states without
/// any backend dependency.
class InMemorySyncRepository implements SyncRepository {
  InMemorySyncRepository([
    SyncStatus initialStatus = const SyncStatus.signedOut(),
  ]) : _status = initialStatus;

  SyncStatus _status;
  final StreamController<SyncStatus> _controller =
      StreamController<SyncStatus>.broadcast();

  void setStatus(SyncStatus status) {
    _status = status;
    _controller.add(status);
  }

  @override
  Future<SyncStatus> currentStatus() async => _status;

  @override
  Stream<SyncStatus> statusChanges() => _controller.stream;

  @override
  Future<void> signOut() async {
    setStatus(const SyncStatus.signedOut());
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
