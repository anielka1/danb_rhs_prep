/// Whether, and how, local progress is currently syncing to a remote
/// account. Deliberately provider-agnostic: no backend-specific types.
enum SyncState { signedOut, idle, syncing, error }

/// A snapshot of sync state suitable for display in Settings.
///
/// Invariant: [lastSyncedAt] is only ever set once at least one sync has
/// completed successfully; [errorMessage] is only meaningful when [state]
/// is [SyncState.error].
class SyncStatus {
  const SyncStatus({
    required this.state,
    this.lastSyncedAt,
    this.errorMessage,
  });

  const SyncStatus.signedOut() : this(state: SyncState.signedOut);

  final SyncState state;

  /// Always stored in UTC when set.
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncStatus &&
        other.state == state &&
        other.lastSyncedAt == lastSyncedAt &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(state, lastSyncedAt, errorMessage);
}

/// The optional cloud-sync boundary. This describes only what the app needs
/// to show and control sync from Settings — it must remain provider
/// independent and must never mention Supabase (or any other backend) types.
/// Signing in/out with a specific identity provider is a separate concern;
/// this interface only reflects and controls the resulting sync state.
abstract interface class SyncRepository {
  Future<SyncStatus> currentStatus();
  Stream<SyncStatus> statusChanges();

  /// Signs the user out of sync without deleting local progress.
  Future<void> signOut();
}
