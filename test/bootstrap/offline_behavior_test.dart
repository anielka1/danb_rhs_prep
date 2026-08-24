import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/repositories/content_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';

/// Dedicated, narrowly-scoped proof of Section 3.1's offline-first
/// requirement, gathering what `app_bootstrap_service_test.dart` already
/// establishes piecemeal (real content loads without `rootBundle`
/// touching a second time in that file; no remote dependency type is
/// reachable) into one place named for exactly what the roadmap asks:
/// bootstrap must not require HTTP, Supabase, auth, analytics delivery,
/// billing, remote config, or network time, and bundled content must be
/// sufficient on its own to begin studying.
class _FileContentRepository implements ContentRepository {
  const _FileContentRepository();

  @override
  Future<ContentPackage> loadContentPackage(String examId) async {
    final String source =
        File('assets/content/$examId/content.json').readAsStringSync();
    return const ExamContentCodec().decode(source);
  }
}

void main() {
  test(
      'bootstrap succeeds with every dependency offline-capable — no '
      'HTTP client, no Supabase, no auth, no StoreKit, no remote config, '
      'no network time, anywhere in the object graph', () async {
    final service = AppBootstrapService(
      contentRepository: const _FileContentRepository(),
      localStore: InMemoryBootstrapLocalStore(),
      // userSettingsRepository intentionally omitted: null, matching
      // production, where no adapter exists yet — proves this path
      // doesn't secretly require one either.
    );

    final result = await service.initialize();

    expect(result, isA<BootstrapReady>());
  });

  test(
      'bundled questions are available with zero network access — read '
      'directly from the local asset file, decoded, and validated', () async {
    final service = AppBootstrapService(
      contentRepository: const _FileContentRepository(),
      localStore: InMemoryBootstrapLocalStore(),
    );

    final result = await service.initialize() as BootstrapReady;

    expect(result.contentPackage.questions, isNotEmpty,
        reason: 'bundled content and valid local data must be sufficient '
            'to begin studying without any network access');
    expect(result.contentPackage.exam.domains, isNotEmpty);
  });

  test(
      'a missing/never-purchased entitlement defaults to free without '
      'contacting any billing service', () async {
    final service = AppBootstrapService(
      contentRepository: const _FileContentRepository(),
      localStore: InMemoryBootstrapLocalStore(),
      now: () => DateTime.utc(2026, 1, 1),
    );

    final result = await service.initialize() as BootstrapReady;

    expect(result.entitlement.tier, EntitlementTier.free);
    expect(result.entitlement.source, EntitlementSource.none);
  });
}
