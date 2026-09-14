import 'package:danb_rhs_prep/screens/subscription_screen.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/main.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_content_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_user_settings_repository.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'fixtures.dart';

class _FailCompletion extends InMemoryBootstrapLocalStore {
  _FailCompletion() : super(onboardingComplete: false);
  bool fail = false;
  @override
  Future<void> writeOnboardingComplete(bool complete) async {
    if (fail && complete) {
      fail = false;
      throw StateError('completion write');
    }
    await super.writeOnboardingComplete(complete);
  }
}

class _FailProfile extends InMemoryUserSettingsRepository {
  bool fail = false;
  @override
  Future<void> saveProfile(UserProfile profile) async {
    if (fail) {
      fail = false;
      throw StateError('profile write');
    }
    await super.saveProfile(profile);
  }
}

void main() {
  for (final approved in [true, false]) {
    testWidgets(
        'date opens offer then Home and survives restart approved=$approved',
        (tester) async {
      final package = fixture(
          count: 80,
          status: approved ? QuestionStatus.approved : QuestionStatus.draft);
      final local = InMemoryBootstrapLocalStore(onboardingComplete: false);
      final settings = InMemoryUserSettingsRepository();
      final progress = InMemoryProgressRepository();
      Widget app() => DanbRhsPrepApp(
          localStore: local,
          progressRepository: progress,
          userSettingsRepository: settings,
          bootstrapService: AppBootstrapService(
              localStore: local,
              userSettingsRepository: settings,
              contentRepository:
                  InMemoryContentRepository({package.exam.id: package})));
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text));
        await tester.tap(find.text(text));
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tap('Start Preparing');
      await tap('Within a month');
      await tap('Continue');
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close subscription'));
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('Optional starting check'), findsNothing);
      expect(await local.readExperienceLevel(), isNull);
      expect((await settings.loadProfile(package.exam.id))!.experienceLevel,
          isNull);
      expect(await local.readOnboardingComplete(), isTrue);
      expect(await progress.practiceSessionsForExam(package.exam.id), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
      expect(await progress.answerAttemptsForExam(package.exam.id), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  for (final failure in ['profile', 'completion']) {
    testWidgets(
        'onboarding $failure failure retries before Home and survives restart',
        (tester) async {
      final package = fixture(count: 0);
      final local = _FailCompletion();
      final settings = _FailProfile();
      final progress = InMemoryProgressRepository();
      Widget app() => DanbRhsPrepApp(
          localStore: local,
          progressRepository: progress,
          userSettingsRepository: settings,
          bootstrapService: AppBootstrapService(
              localStore: local,
              userSettingsRepository: settings,
              contentRepository:
                  InMemoryContentRepository({package.exam.id: package})));
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text));
        await tester.tap(find.text(text));
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tap('Start Preparing');
      await tap('Within a month');
      settings.fail = failure == 'profile';
      local.fail = failure == 'completion';
      await tap('Continue');
      expect(find.byType(MainShell), findsNothing);
      expect(await local.readOnboardingComplete(), isFalse);
      expect(await local.readExamDateSelection(), isNotNull);
      await tap('Retry');
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close subscription'));
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
      expect(await settings.loadProfile(package.exam.id), isNotNull);
      expect(await local.readOnboardingComplete(), isTrue);
      expect(await progress.practiceSessionsForExam(package.exam.id), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
