/// Shared transport and repository bounds. These are maximum waits, not delays.
abstract final class ContentSyncTimeouts {
  static const metadata = Duration(seconds: 10);
  static const download = Duration(seconds: 30);
}
