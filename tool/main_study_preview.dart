// Explicit, isolated development entrypoint. Never imported by production.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:danb_rhs_prep/main.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_content_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_user_settings_repository.dart';
import '../test/study_plan/fixtures.dart';

Future<void> main() async {
  if (!kDebugMode) throw UnsupportedError('Study preview requires debug mode.');
  WidgetsFlutterBinding.ensureInitialized();
  // Existing test fixture constructor, independent of candidate/production questions.
  final package = fixtureFromJson(
      jsonDecode(await rootBundle.loadString(
          'assets/content/danb_rhs/content.json')) as Map<String, dynamic>,
      count: 80);
  final local = InMemoryBootstrapLocalStore(onboardingComplete: false);
  final settings = InMemoryUserSettingsRepository();
  runApp(DanbRhsPrepApp(
      localStore: local,
      userSettingsRepository: settings,
      progressRepository: InMemoryProgressRepository(),
      bootstrapService: AppBootstrapService(
          localStore: local,
          userSettingsRepository: settings,
          contentRepository:
              InMemoryContentRepository({package.exam.id: package}))));
}
