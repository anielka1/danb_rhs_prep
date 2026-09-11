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
import 'package:danb_rhs_prep/screens/diagnostic_screen.dart';
import 'fixtures.dart';

void main() {
  for (final mode in ['complete', 'skip', 'unavailable']) {
    final skip = mode != 'complete';
    final package = fixture(
        count: 80,
        status: mode == 'unavailable'
            ? QuestionStatus.draft
            : QuestionStatus.approved);
    testWidgets('real launch onboarding diagnostic $mode and restart',
        (tester) async {
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

      Future<void> onboarding() async {
        await tap('Start Preparing');
        await tap('Within a month');
        await tap('Continue');
        expect(find.text('Just starting'), findsNothing);
        expect(await local.readExperienceLevel(), isNull);
        expect(find.byType(DiagnosticScreen), findsOneWidget);
      }

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await onboarding();
      if (mode == 'unavailable') {
        expect(find.text('Start diagnostic'), findsNothing);
        expect(find.textContaining('approved questions'), findsOneWidget);
      }
      if (skip) {
        await tap('Skip for now');
        expect(
            await progress.practiceSessionsForExam(package.exam.id), isEmpty);
      } else {
        await tap('Start diagnostic');
        await tap('Correct fixture answer');
        await tap('Save and continue');
        final original =
            (await progress.practiceSessionsForExam(package.exam.id)).single;
        final order = original.answerOrder;
        // Destroy the entire app and reconstruct its composition root, retaining stores.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        // Saved onboarding choices are still presented; availability toggles retain state.
        await tap('Start Preparing');
        await tap('Continue');
        await tap('Resume diagnostic');
        expect(find.text('Question 2 of 15'), findsOneWidget);
        expect(
            (await progress.practiceSessionsForExam(package.exam.id))
                .single
                .answerOrder,
            order);
        for (var i = 1; i < 15; i++) {
          await tap('Correct fixture answer');
          await tap('Save and continue');
        }
        expect(find.text('Your starting point'), findsOneWidget);
        expect(await progress.answerAttemptsForExam(package.exam.id),
            hasLength(15));
        expect(await progress.practiceSessionsForExam(package.exam.id),
            hasLength(1));
        await tap('Continue to Home');
      }
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('Study calendar'), findsNothing);
      expect((await settings.loadProfile(package.exam.id))!.experienceLevel,
          isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
      expect(await progress.answerAttemptsForExam(package.exam.id),
          hasLength(skip ? 0 : 15));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
