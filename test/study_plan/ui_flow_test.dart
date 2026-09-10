import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/experience_level.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/models/study_plan_preferences.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_user_settings_repository.dart';
import 'package:danb_rhs_prep/screens/study_availability_screen.dart';
import 'package:danb_rhs_prep/screens/study_calendar_screen.dart';
import 'package:danb_rhs_prep/screens/diagnostic_screen.dart';
import 'package:danb_rhs_prep/study_plan/study_plan.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/study_plan_panel.dart';
import 'fixtures.dart';

void main() {
  final day = DateTime(2026, 9, 10), package = fixture();
  final prefs = StudyPlanPreferences(weekdays: [1, 2, 3, 4, 5], minutes: 30);
  BootstrapSessionController session(
      {bool configured = true, int count = 500}) {
    final p = fixture(count: count);
    final date = ExamDateSelection(
        precision: ExamDatePrecision.exact, date: DateTime(2026, 10, 10));
    final profile = UserProfile.fromOnboarding(
        examId: p.exam.id,
        experienceLevel: ExperienceLevel.justStarting,
        examDateSelection: date,
        themePreference: ThemePreference.light,
        now: day);
    return BootstrapSessionController(
        BootstrapReady(
            selectedExamId: p.exam.id,
            contentPackage: p,
            profile: configured
                ? profile.copyWith(studyPlanPreferences: prefs)
                : profile,
            themePreference: ThemePreference.light,
            readinessSnapshot: null,
            entitlement: Entitlement.free(lastVerifiedAt: day),
            onboardingComplete: true,
            examDateSelection: date,
            experienceLevel: ExperienceLevel.justStarting),
        progressRepository: InMemoryProgressRepository(),
        userSettingsRepository:
            InMemoryUserSettingsRepository(seedProfile: profile));
  }

  Widget wrap(Widget child, bool dark, double scale) => MaterialApp(
      theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: child);
  for (final dark in [false, true]) {
    for (final scale in [1.0, 4.0]) {
      testWidgets(
          'availability, calendar and plan fit 375x667 dark=$dark text=$scale',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 667));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final s = session();
        await tester
            .pumpWidget(wrap(StudyAvailabilityScreen(session: s), dark, scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final p = const StudyPlanPolicy().project(
            now: day,
            localToday: day,
            timezone: 'Test',
            exam: package.exam,
            preferences: prefs,
            pool: package.questions,
            attempts: []);
        await tester.pumpWidget(wrap(
            StudyCalendarScreen(
                plan: p,
                session: s,
                repository: s.progressRepository!,
                now: () => day),
            dark,
            scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(wrap(
            Scaffold(
                body: SingleChildScrollView(
                    child: StudyPlanPanel(
                        session: s,
                        repository: s.progressRepository!,
                        now: () => day))),
            dark,
            scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets(
      'existing user adds availability without resetting history or full onboarding',
      (tester) async {
    final s = session(configured: false);
    final repo = s.progressRepository!;
    await repo.recordAnswerAttempt(answer(package.questions.first, day));
    await tester.pumpWidget(wrap(
        Scaffold(
            body: SingleChildScrollView(
                child: StudyPlanPanel(
                    session: s, repository: repo, now: () => day))),
        false,
        1));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Set study availability'));
    await tester.tap(find.text('Set study availability'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monday'));
    await tester.tap(find.text('30 min'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save availability'));
    await tester.tap(find.text('Save availability'));
    await tester.pumpAndSettle();
    expect(s.snapshot.profile!.studyPlanPreferences!.minutes, 30);
    expect((await repo.answerAttemptsForExam(package.exam.id)).length, 1);
    expect(find.text("Today's plan"), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'Home starts the assigned set, answer saves and returning offers the same session',
      (tester) async {
    final s = session();
    await tester.pumpWidget(wrap(
        Scaffold(
            body: SingleChildScrollView(
                child: StudyPlanPanel(
                    session: s,
                    repository: s.progressRepository!,
                    now: () => day))),
        false,
        1));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Start today's session"));
    await tester.tap(find.text("Start today's session"));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeQuestionScreen), findsOneWidget);
    final active =
        await s.progressRepository!.inProgressPracticeSession(package.exam.id);
    expect(active!.mode, PracticeMode.planned);
    await tester.ensureVisible(find.text('Correct fixture answer'));
    await tester.tap(find.text('Correct fixture answer'));
    await tester.pump();
    await tester.ensureVisible(find.text('Submit Answer'));
    await tester.tap(find.text('Submit Answer'));
    await tester.pumpAndSettle();
    expect(
        (await s.progressRepository!.answerAttemptsForExam(package.exam.id))
            .length,
        1);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .popUntil((route) => route.isFirst);
    await tester.pumpAndSettle();
    expect(find.text('Continue planned session'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue planned session'));
    await tester.tap(find.text('Continue planned session'));
    await tester.pumpAndSettle();
    expect(
        (await s.progressRepository!
                .inProgressPracticeSession(package.exam.id))!
            .questionIds,
        active.questionIds);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('short diagnostic gives reason and Skip; no fabricated attempts',
      (tester) async {
    final s = session(count: 1);
    await tester.pumpWidget(wrap(DiagnosticScreen(session: s), false, 1));
    await tester.pumpAndSettle();
    expect(find.text('Skip for now'), findsOneWidget);
    expect(find.text('Start diagnostic'), findsNothing);
    expect(await s.progressRepository!.answerAttemptsForExam(package.exam.id),
        isEmpty);
  });
}
