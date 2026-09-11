import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/widgets/app_bottom_navigation.dart';
import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
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
  testWidgets('configured Home has one primary practice action',
      (tester) async {
    final s = session();
    await tester.pumpWidget(wrap(
        BootstrapSessionScope(
            controller: s,
            child: HomeScreen(
                progressRepository: s.progressRepository, now: () => day)),
        false,
        1));
    await tester.pumpAndSettle();
    expect(find.text("Start today's session"), findsOneWidget);
    expect(find.text('Start Practicing'), findsNothing);
    expect(find.text('Free practice'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('exam day offers no impossible calendar edits', (tester) async {
    final s = session();
    final p = const StudyPlanPolicy().project(
        now: day,
        localToday: day,
        timezone: 'Test',
        exam: package.exam,
        preferences: prefs,
        pool: package.questions,
        attempts: [],
        examDate: day.add(const Duration(days: 1)));
    await tester.pumpWidget(wrap(
        StudyCalendarScreen(
            plan: p,
            session: s,
            repository: s.progressRepository!,
            now: () => day),
        false,
        1));
    await tester.pumpAndSettle();
    expect(find.text('Move session'), findsNothing);
    expect(find.text('Day off / cancel mock'), findsNothing);
  });
  testWidgets(
      'completed calendar day shows recorded work instead of zero assignment',
      (tester) async {
    final s = session();
    final yesterday = day.subtract(const Duration(days: 1));
    final ids = package.questions.take(2).map((q) => q.id).toList();
    final history = package.questions
        .take(2)
        .map((q) => answer(q, yesterday, seconds: 60))
        .toList();
    final saved = PracticeSession(
        id: 'done',
        examId: package.exam.id,
        mode: PracticeMode.planned,
        questionIds: ids,
        status: SessionStatus.completed,
        startedAt: yesterday,
        completedAt: yesterday,
        planDate: dateKey(yesterday));
    final p = const StudyPlanPolicy().project(
        now: day,
        localToday: day,
        timezone: 'Test',
        exam: package.exam,
        preferences: prefs,
        pool: package.questions,
        attempts: history,
        sessions: [saved]);
    await tester.pumpWidget(wrap(
        StudyCalendarScreen(
            plan: p,
            session: s,
            repository: s.progressRepository!,
            now: () => day),
        false,
        1));
    await tester.pumpAndSettle();
    expect(find.text('2 answers recorded · 2 min spent'), findsOneWidget);
  });
  testWidgets(
      'Home session result Home restart and reset keep one current action',
      (tester) async {
    var s = session(count: 1);
    final repo = s.progressRepository! as InMemoryProgressRepository;
    Widget home() => wrap(
        BootstrapSessionScope(
            controller: s,
            child: HomeScreen(progressRepository: repo, now: () => day)),
        false,
        1);
    await tester.pumpWidget(home());
    await tester.pumpAndSettle();
    for (final label in [
      "Start today's session",
      'Correct fixture answer',
      'Submit Answer',
      'Finish',
      'Back to Home'
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(find.text("Today's plan completed"), findsOneWidget);
    expect(find.text("Start today's session"), findsNothing);
    expect(find.text('Continue planned session'), findsNothing);
    expect((await repo.answerAttemptsForExam(package.exam.id)).length, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    s = BootstrapSessionController(s.snapshot,
        progressRepository: repo,
        userSettingsRepository: s.userSettingsRepository);
    await tester.pumpWidget(home());
    await tester.pumpAndSettle();
    expect(find.text("Today's plan completed"), findsOneWidget);
    expect(find.text('1 answers recorded today'), findsOneWidget);
    await repo.resetProgressForExam(package.exam.id);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text("Start today's session"), findsOneWidget);
    expect(find.text("Today's plan completed"), findsNothing);
    expect(s.snapshot.profile!.studyPlanPreferences, prefs);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('return from another tab refreshes session completion',
      (tester) async {
    final s = session(count: 1), shell = _Shell();
    final repo = s.progressRepository!;
    final saved = PracticeSession(
        id: 'tab-session',
        examId: package.exam.id,
        mode: PracticeMode.planned,
        questionIds: [package.questions.first.id],
        status: SessionStatus.inProgress,
        startedAt: day,
        planDate: dateKey(day));
    await repo.savePracticeSession(saved);
    Widget home(AppTab tab) => wrap(
        BootstrapSessionScope(
            controller: s,
            child: MainShellScope(
                controller: shell,
                activeTab: tab,
                child: HomeScreen(progressRepository: repo, now: () => day))),
        false,
        1);
    await tester.pumpWidget(home(AppTab.home));
    await tester.pumpAndSettle();
    expect(find.text('Continue planned session'), findsOneWidget);
    await tester.pumpWidget(home(AppTab.practice));
    await tester.pumpAndSettle();
    await repo.recordAnswerAttempt(answer(package.questions.first, day));
    await repo.savePracticeSession(
        saved.copyWith(status: SessionStatus.completed, completedAt: day));
    await tester.pumpWidget(home(AppTab.home));
    await tester.pumpAndSettle();
    expect(find.text('Continue planned session'), findsNothing);
    expect(find.text("Today's plan completed"), findsOneWidget);
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

class _Shell implements MainShellController {
  @override
  AppTab get currentTab => AppTab.home;
  @override
  void goToTab(AppTab tab, {AppTab? resetTab}) {}
}
