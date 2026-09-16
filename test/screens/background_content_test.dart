import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:danb_rhs_prep/main.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_content_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_user_settings_repository.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/content/sync/content_release_database.dart';
import 'package:danb_rhs_prep/features/content/sync/content_update_controller.dart';
import 'package:danb_rhs_prep/features/content/sync/synced_content_repository.dart';
import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/screens/progress_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_free_practice_store.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import '../study_plan/fixtures.dart';

class ControlledSync extends SyncedContentRepository {
  ControlledSync(this.initial, this.downloaded, ContentReleaseDatabase database,
      InMemoryProgressRepository progress)
      : super(
            bundled: InMemoryContentRepository({initial.exam.id: initial}),
            database: database,
            progress: progress);
  final ContentPackage initial, downloaded;
  Completer<ContentSyncResult> response = Completer();
  int calls = 0, activations = 0;
  @override
  Future<ContentPackage> loadLocalContentPackage(String examId) async =>
      initial;
  @override
  Future<ContentSyncResult> retrySync(String examId) {
    calls++;
    return response.future;
  }

  @override
  Future<ContentPackage> activateDownloadedContent(String examId) async {
    activations++;
    return downloaded;
  }
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await loader.load();
  });
  for (final variant in [(false, 1.0), (true, 1.0), (false, 2.0)]) {
    final (dark, scale) = variant;
    testWidgets(
        'Home opens before download; Retry updates both tabs dark=$dark scale=$scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final empty = fixture(count: 0);
      final raw = jsonDecode(
              File('assets/content/danb_rhs/content.json').readAsStringSync())
          as Map<String, dynamic>;
      raw['contentVersion'] = 'downloaded';
      (raw['exam'] as Map)['contentVersion'] = 'downloaded';
      final downloaded = fixtureFromJson(raw, count: 20);
      final db = ContentReleaseDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final progress = InMemoryProgressRepository();
      final repository = ControlledSync(empty, downloaded, db, progress);
      final updates = ContentUpdateController(repository);
      addTearDown(updates.dispose);
      final store = InMemoryBootstrapLocalStore(
          onboardingComplete: true,
          themePreference: dark ? ThemePreference.dark : ThemePreference.light);
      final settings = InMemoryUserSettingsRepository();
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: DanbRhsPrepApp(
            contentUpdates: updates,
            localStore: store,
            themeModeController:
                ThemeModeController(dark ? ThemeMode.dark : ThemeMode.light),
            progressRepository: progress,
            userSettingsRepository: settings,
            freePracticeStore: InMemoryFreePracticeStore(),
            bootstrapService: AppBootstrapService(
                contentRepository: repository.localRepository,
                localStore: store,
                userSettingsRepository: settings),
          )));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Downloading questions…'), findsOneWidget);
      expect(
          find.textContaining('No approved practice questions'), findsNothing);
      expect(repository.activations, 0);
      expect(repository.calls, 1);

      repository.response.complete(ContentSyncResult.rejected);
      await tester.pumpAndSettle();
      expect(find.text('Retry download'), findsOneWidget);
      repository.response = Completer();
      await tester.ensureVisible(find.text('Retry download'));
      await tester.tap(find.text('Retry download'));
      await tester.pump();
      expect(repository.calls, 2);
      expect(find.textContaining('Downloading questions…'), findsOneWidget);
      expect(
          find.textContaining('No approved practice questions'), findsNothing);
      // Render opt-in review artifacts without modifying any golden baselines.
      if (Platform.environment['CAPTURE_CONTENT_SYNC'] == '1') {
        await Scrollable.ensureVisible(
            tester.element(find.textContaining('Downloading questions…')),
            alignment: 0.2);
        await tester.pump();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
                  '/private/tmp/content-download-${dark ? 'dark' : 'light'}-$scale.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      // A route holding the old package must remain intact until it closes.
      final navigator = Navigator.of(tester.element(find.byType(HomeScreen)),
          rootNavigator: dark);
      unawaited(navigator.push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Existing route')))));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      repository.response.complete(ContentSyncResult.installed);
      await tester.pumpAndSettle();
      expect(repository.activations, 0);
      expect(find.text('Existing route'), findsOneWidget);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(repository.activations, 1);
      expect(find.textContaining('Downloading questions…'), findsNothing);
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<ProgressScreen>(find.byType(ProgressScreen))
              .contentPackage!
              .questions,
          hasLength(20));
      expect(find.text('20 available questions'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
