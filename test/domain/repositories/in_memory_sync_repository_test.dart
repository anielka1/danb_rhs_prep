import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/repositories/sync_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_sync_repository.dart';

void main() {
  test('defaults to signed out with no provider-specific state', () async {
    final repository = InMemorySyncRepository();
    final status = await repository.currentStatus();

    expect(status.state, SyncState.signedOut);
    expect(status, const SyncStatus.signedOut());

    repository.dispose();
  });

  test('setStatus updates current value and emits a change', () async {
    final repository = InMemorySyncRepository();
    final synced = SyncStatus(
      state: SyncState.idle,
      lastSyncedAt: DateTime.utc(2026, 1, 1),
    );

    final changes = repository.statusChanges();
    final firstChange = changes.first;

    repository.setStatus(synced);

    expect(await repository.currentStatus(), synced);
    expect(await firstChange, synced);

    repository.dispose();
  });

  test('signOut clears sync state without touching local data', () async {
    final repository = InMemorySyncRepository(
      SyncStatus(state: SyncState.idle, lastSyncedAt: DateTime.utc(2026, 1, 1)),
    );

    await repository.signOut();

    expect(await repository.currentStatus(), const SyncStatus.signedOut());

    repository.dispose();
  });
}
