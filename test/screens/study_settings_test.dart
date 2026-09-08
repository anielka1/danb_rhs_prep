import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/experience_level.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_user_settings_repository.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

class _Store extends InMemoryBootstrapLocalStore {
  bool fail = false;
  @override
  Future<void> writeExamDateSelection(ExamDateSelection selection) async {
    if (fail) throw StateError('storage unavailable');
    await super.writeExamDateSelection(selection);
  }
}

class _Profiles extends InMemoryUserSettingsRepository {
  _Profiles(UserProfile profile) : super(seedProfile: profile);
  bool fail = false;
  @override
  Future<void> saveProfile(UserProfile profile) async {
    if (fail) throw StateError('profile unavailable');
    await super.saveProfile(profile);
  }
}

void main() {
  late _Store store;
  late _Profiles profiles;
  late BootstrapSessionController session;
  late UserProfile original;
  late ThemeModeController theme;

  setUp(() async {
    store = _Store();
    original =
        DebugDemoEnvironment.demoProfile.copyWith(dailyGoalQuestions: 20);
    profiles = _Profiles(original);
    final date = ExamDateSelection(precision: ExamDatePrecision.notScheduled);
    await store.writeExamDateSelection(date);
    await store.writeExperienceLevel(ExperienceLevel.justStarting);
    session = BootstrapSessionController(BootstrapReady(
      selectedExamId: DebugDemoEnvironment.demoExamId,
      contentPackage: DebugDemoEnvironment.demoContentPackage,
      profile: original,
      themePreference: ThemePreference.system,
      readinessSnapshot: null,
      entitlement: Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 9, 8)),
      onboardingComplete: true,
      examDateSelection: date,
      experienceLevel: ExperienceLevel.justStarting,
    ));
    theme = ThemeModeController();
  });
  tearDown(() => theme.dispose());

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProfileSettingsScreen(
            themeModeController: theme,
            session: session,
            localStore: store,
            userSettingsRepository: profiles)));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('cancel keeps the saved timeframe', (tester) async {
    await open(tester);
    await tap(tester, 'Exam timeframe');
    await tap(tester, 'Later');
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Not scheduled yet'), findsOneWidget);
    expect((await store.readExamDateSelection())!.precision,
        ExamDatePrecision.notScheduled);
  });

  testWidgets('study plan remains usable with accessibility text sizing',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3.12;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester);
    await tap(tester, 'Exam timeframe');
    await tap(tester, 'Later');
    await tap(tester, 'Save changes');
    await tap(tester, 'Study experience');
    await tap(tester, 'Studying already');
    await tap(tester, 'Save changes');
    expect(find.byType(ProfileSettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'failed preference save keeps old state; retry persists both stores',
      (tester) async {
    await open(tester);
    await tap(tester, 'Exam timeframe');
    await tap(tester, 'In 1–3 months');
    store.fail = true;
    await tap(tester, 'Save changes');
    expect(find.text('Retry'), findsOneWidget);
    expect(session.snapshot.examDateSelection!.precision,
        ExamDatePrecision.notScheduled);
    store.fail = false;
    await tap(tester, 'Retry');
    expect(find.text('In 1–3 months'), findsOneWidget);
    expect((await store.readExamDateSelection())!.precision,
        ExamDatePrecision.oneToThreeMonths);
    final saved = (await profiles.loadProfile(original.examId))!;
    expect(saved.examDatePrecision, ExamDatePrecision.oneToThreeMonths);
    expect(saved.examDate, isNull);
    expect(saved.dailyGoalQuestions, 20);
    expect(saved.createdAt, original.createdAt);
  });

  testWidgets(
      'profile write failure can be retried without restarting onboarding',
      (tester) async {
    await open(tester);
    await tap(tester, 'Study experience');
    await tap(tester, 'Studying already');
    profiles.fail = true;
    await tap(tester, 'Save changes');
    expect(find.text('Retry'), findsOneWidget);
    expect(session.snapshot.onboardingComplete, isTrue);
    expect(await store.readExperienceLevel(), ExperienceLevel.studyingAlready);
    profiles.fail = false;
    await tap(tester, 'Retry');
    expect(find.byType(ProfileSettingsScreen), findsOneWidget);
    expect((await profiles.loadProfile(original.examId))!.experienceLevel,
        ExperienceLevel.studyingAlready);
    expect(await store.readOnboardingComplete(), isNull,
        reason: 'Editing never changes onboarding completion storage.');
  });
}
