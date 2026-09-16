/// Public release transport only. No user identity or progress API.
abstract interface class RemoteContentSource {
  /// Metadata only; must never select the question payload.
  Future<int?> latestVersion(String examId, DateTime now);

  /// Fetch the exact published revision checked above, not a racing latest row.
  Future<Map<String, Object?>?> release(
    String examId,
    int version,
    DateTime now,
  );
}
