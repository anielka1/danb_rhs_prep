/// Public release transport only. No user identity, progress or workbench API.
abstract interface class RemoteContentSource {
  Future<Map<String, Object?>?> latestRelease(String examId, DateTime now);
}
