import 'dart:math';
import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/screens/diagnostic_screen.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/experience_level.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/study_plan_preferences.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/screens/study_calendar_screen.dart';
import 'package:danb_rhs_prep/study_plan/daily_study_overview.dart';
import 'package:danb_rhs_prep/study_plan/study_plan.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/study_plan_panel.dart';
import '../study_plan/fixtures.dart';
import '../support/golden_probe.dart';

void main() {
  for (final dark in [false, true]) {
    for (final screen in [
      'daily_plan_partial',
      'daily_calendar_partial',
      'daily_result_done',
      'planned_home',
      'diagnostic_question'
    ]) {
      testWidgets('$screen dark=$dark', (tester) async {
        final today = DateTime(2026, 9, 11),
            package = fixture(
                count:
                    screen == 'diagnostic_question' || screen == 'planned_home'
                        ? 80
                        : 3);
        final repo = InMemoryProgressRepository();
        final profile = UserProfile.fromOnboarding(
                examId: package.exam.id,
                experienceLevel: ExperienceLevel.justStarting,
                examDateSelection: ExamDateSelection(
                    precision: ExamDatePrecision.exact,
                    date: DateTime(2026, 10, 10)),
                themePreference: ThemePreference.light,
                now: today)
            .copyWith(
                studyPlanPreferences: StudyPlanPreferences(
                    weekdays: [1, 2, 3, 4, 5, 6, 7], minutes: 30));
        final bootstrap = BootstrapSessionController(
            BootstrapReady(
                selectedExamId: package.exam.id,
                contentPackage: package,
                profile: profile,
                themePreference: ThemePreference.light,
                readinessSnapshot: null,
                entitlement: Entitlement.free(lastVerifiedAt: today),
                onboardingComplete: true,
                examDateSelection: ExamDateSelection(
                    precision: ExamDatePrecision.exact,
                    date: DateTime(2026, 10, 10)),
                experienceLevel: ExperienceLevel.justStarting),
            progressRepository: repo);
        final date = screen == 'daily_result_done'
            ? today
            : today.subtract(const Duration(days: 1));
        final controller = PracticeSessionController(
            session: PracticeSession(
                id: 'journey-golden',
                examId: package.exam.id,
                mode: PracticeMode.planned,
                questionIds: package.questions.map((q) => q.id).toList(),
                reviewQuestionIds: [package.questions.last.id],
                status: SessionStatus.inProgress,
                startedAt: date,
                planDate: dateKey(date)),
            questions: package.questions,
            progressRepository: repo,
            now: () => date);
        if (screen != 'diagnostic_question' && screen != 'planned_home') {
          await controller.saveSession();
          await controller.submitAnswer('a', activeDurationSeconds: 60);
          if (screen == 'daily_result_done') {
            for (var i = 1; i < 3; i++) {
              controller.moveTo(i);
              await controller.submitAnswer('a', activeDurationSeconds: 60);
            }
            await controller.complete();
          }
        }
        final overview =
            await DailyStudyOverview.load(bootstrap, repo, () => today);
        final Widget child = switch (screen) {
          'daily_plan_partial' => Scaffold(
              body: SingleChildScrollView(
                  child: StudyPlanPanel(
                      session: bootstrap, repository: repo, now: () => today))),
          'planned_home' => BootstrapSessionScope(
              controller: bootstrap,
              child: HomeScreen(progressRepository: repo, now: () => today)),
          'diagnostic_question' =>
            DiagnosticScreen(session: bootstrap, random: Random(11)),
          'daily_calendar_partial' => StudyCalendarScreen(
              initialDate: date,
              plan: overview.plan,
              session: bootstrap,
              repository: repo,
              now: () => today),
          _ => BootstrapSessionScope(
              controller: bootstrap,
              child: PracticeSessionScope(
                  controller: controller,
                  child: const PracticeSummaryScreen())),
        };
        await pumpGolden(tester, child,
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            textScale: GoldenTextScale.normal);
        if (screen == 'diagnostic_question') {
          await tester.tap(find.text('Start diagnostic'));
          await tester.pumpAndSettle();
          expect(find.text('Question 1 of 15'), findsOneWidget);
        }
        if (screen == 'daily_result_done') {
          expect(find.textContaining('Lowest session accuracy'), findsNothing);
          expect(find.textContaining('Highest session accuracy'), findsNothing);
          await tester.ensureVisible(find.byType(StudyPlanPanel));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(goldenPath(
                screen: screen,
                brightness: dark ? Brightness.dark : Brightness.light,
                textScale: GoldenTextScale.normal)));
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
