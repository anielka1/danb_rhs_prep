import 'package:supabase_flutter/supabase_flutter.dart';
import 'remote_content_source.dart';

/// Short-lived, accountless client. No sign-in, persisted token,
/// realtime channel, deep-link listener or global Supabase singleton.
class SupabaseRemoteContentSource implements RemoteContentSource {
  SupabaseRemoteContentSource._(this._url, this._key);
  final String _url;
  final String _key;

  static SupabaseRemoteContentSource? fromConfiguration({
    String url = const String.fromEnvironment('SUPABASE_URL'),
    String publishableKey = const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
  }) {
    final uri = Uri.tryParse(url);
    // Modern publishable keys only: rejects secret and service-role JWT keys.
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        !RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$').hasMatch(publishableKey)) {
      return null;
    }
    return SupabaseRemoteContentSource._(
      uri.replace(path: '').toString(),
      publishableKey,
    );
  }

  @override
  Future<Map<String, Object?>?> latestRelease(
    String examId,
    DateTime now,
  ) async {
    final client = SupabaseClient(
      _url,
      _key,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      postgrestOptions: const PostgrestClientOptions(
        schema: 'public',
        retryEnabled: false,
        requestTimeout: Duration(seconds: 12),
      ),
    );
    try {
      final rows = await client
          .from('question_bank_releases')
          .select(
            'exam_id,schema_version,release_version,content_version,'
            'question_count,payload,content_sha256,published_at,retired_at',
          )
          .eq('exam_id', examId)
          .lte('published_at', now.toUtc().toIso8601String())
          .isFilter('retired_at', null)
          .order('release_version', ascending: false)
          .limit(1)
          // Set this on the final builder as well: the pinned SDK's query
          // chain does not retain all client-level retry/timeout options.
          .retry(
              enabled: false,
              count: 0,
              requestTimeout: const Duration(seconds: 12));
      return rows.isEmpty ? null : Map<String, Object?>.from(rows.single);
    } finally {
      await client.dispose();
    }
  }
}
