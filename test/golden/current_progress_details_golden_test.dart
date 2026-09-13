import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/screens/progress_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import '../study_plan/fixtures.dart';
import '../support/golden_probe.dart';

void main() {
  for (final dark in [false, true]) {
    for (final home in [true, false]) {
      testWidgets('scrolled current counts home=$home dark=$dark at AX5',
          (tester) async {
        final package = fixture(count: 8);
        final repo = InMemoryProgressRepository();
        final now = DateTime(2026, 9, 13);
        await repo.recordAnswerAttempt(answer(package.questions[0], now));
        await repo.recordAnswerAttempt(
            answer(package.questions[1], now, correct: false));
        await repo.recordAnswerAttempt(answer(
            package.questions[2], now.subtract(const Duration(days: 1))));
        final bootstrap = BootstrapSessionController(
            BootstrapReady(
                profile: null,
                selectedExamId: package.exam.id,
                contentPackage: package,
                themePreference: ThemePreference.system,
                readinessSnapshot: null,
                entitlement: Entitlement.free(lastVerifiedAt: now),
                onboardingComplete: true,
                examDateSelection: null,
                experienceLevel: null),
            progressRepository: repo);
        await pumpGolden(
            tester,
            BootstrapSessionScope(
                controller: bootstrap,
                child: home
                    ? HomeScreen(progressRepository: repo, now: () => now)
                    : ProgressScreen(
                        progressRepository: repo, contentPackage: package)),
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            textScale: GoldenTextScale.ax5);
        await tester.ensureVisible(find.byKey(
            ValueKey(home ? 'home-progress-metrics' : 'bank-progress-counts')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(goldenPath(
                screen:
                    home ? 'home_current_counts' : 'progress_current_counts',
                brightness: dark ? Brightness.dark : Brightness.light,
                textScale: GoldenTextScale.ax5)));
      });
    }
  }
}
