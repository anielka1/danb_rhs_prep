import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/features/content/sync/supabase_remote_content_source.dart';

// Intercept below the real SDK query builder, before any socket can be opened.
class RecordingHttpClient implements HttpClient {
  final requests = <({String method, Uri url})>[];

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    requests.add((method: method, url: url));
    throw const SocketException('fixture: no network permitted');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('metadata request selects only revision without payload or retry',
      () async {
    final http = RecordingHttpClient();
    await HttpOverrides.runZoned(() async {
      final source = SupabaseRemoteContentSource.fromConfiguration(
          url: 'https://example.invalid',
          publishableKey: 'sb_publishable_fixture')!;
      await expectLater(source.latestVersion('danb_rhs', DateTime.utc(2026)),
          throwsA(isA<Exception>()));
    }, createHttpClient: (_) => http);
    expect(http.requests, hasLength(1));
    expect(
        http.requests.single.url.queryParameters['select'], 'release_version');
    expect(http.requests.single.url.queryParameters['retired_at'], 'is.null');
  });

  for (final suffix in ['', '/']) {
    test(
        'SDK queries only latest published public release, URL suffix "$suffix"',
        () async {
      final http = RecordingHttpClient();
      await HttpOverrides.runZoned(() async {
        final source = SupabaseRemoteContentSource.fromConfiguration(
          url: 'https://example.invalid$suffix',
          publishableKey: 'sb_publishable_fixture',
        )!;
        await expectLater(
            source.release('danb_rhs', 1, DateTime.utc(2026, 9, 14)),
            throwsA(isA<Exception>()));
      }, createHttpClient: (_) => http);
      expect(http.requests, hasLength(1),
          reason: 'no Auth request or SDK retry');
      final request = http.requests.single;
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/question_bank_releases');
      expect(request.url.queryParameters, {
        'select':
            'exam_id,schema_version,release_version,content_version,question_count,payload,content_sha256,published_at,retired_at',
        'exam_id': 'eq.danb_rhs',
        'release_version': 'eq.1',
        'published_at': 'lte.2026-09-14T00:00:00.000Z',
        'retired_at': 'is.null',
        'order': 'release_version.desc.nullslast',
        'limit': '1',
      });
    });
  }
}
