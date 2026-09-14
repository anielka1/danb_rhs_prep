import 'package:danb_rhs_prep/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/main.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_content_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_user_settings_repository.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/screens/welcome_screen.dart';
import '../study_plan/fixtures.dart';

class _Local extends InMemoryBootstrapLocalStore {
  bool fail = false;
  @override
  Future<void> writeOnboardingComplete(bool value) async {
    if (fail) throw StateError('completion write');
    await super.writeOnboardingComplete(value);
  }
}

class _Profiles extends InMemoryUserSettingsRepository {
  bool fail = false;
  @override
  Future<void> saveProfile(UserProfile value) async {
    if (fail) throw StateError('profile write');
    await super.saveProfile(value);
  }
}

void main() {
  for (final failure in ['none', 'profile', 'completion']) {
    testWidgets(
        'short onboarding preserves root stack and retries $failure write',
        (tester) async {
      final package = fixture(count: 0),
          local = _Local(),
          profiles = _Profiles();
      Widget app() => DanbRhsPrepApp(
          localStore: local,
          userSettingsRepository: profiles,
          progressRepository: InMemoryProgressRepository(),
          bootstrapService: AppBootstrapService(
              localStore: local,
              userSettingsRepository: profiles,
              contentRepository:
                  InMemoryContentRepository({package.exam.id: package})));
      Future<void> tap(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tap('Start Preparing');
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      await tap('Start Preparing');
      await tap("I haven't scheduled it yet");
      profiles.fail = failure == 'profile';
      local.fail = failure == 'completion';
      await tap('Continue');
      if (failure != 'none') {
        expect(find.text('Retry'), findsOneWidget);
        expect(await local.readOnboardingComplete(), isNot(true));
        profiles.fail = false;
        local.fail = false;
        await tap('Retry');
      }
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close subscription'));
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
      expect(await local.readExperienceLevel(), isNull);
      expect((await profiles.loadProfile(package.exam.id))!.experienceLevel,
          isNull);
      expect(await local.readOnboardingComplete(), isTrue);
      expect(Navigator.of(tester.element(find.byType(MainShell))).canPop(),
          isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('Just starting'), findsNothing);
      expect(find.byType(WelcomeScreen), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
