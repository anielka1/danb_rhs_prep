import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/experience_level.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/navigation/analytics_navigator_observer.dart';
import 'package:danb_rhs_prep/screens/exam_date_screen.dart';
import 'package:danb_rhs_prep/screens/experience_level_screen.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/welcome_screen.dart';
import 'package:danb_rhs_prep/services/analytics_service.dart';
import 'package:danb_rhs_prep/services/fakes/fake_analytics_service.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

/// Verifies the full onboarding navigation stack across `WelcomeScreen`,
/// `ExamDateScreen`, and `ExperienceLevelScreen` together — the
/// individual screens' own test files each verify their local behavior
/// in isolation, but only a real, multi-route `Navigator` can prove what
/// the stack (and the session snapshot flowing through it) ends up
/// containing once onboarding completes.
ExamConfig _fakeExamConfig() {
  return const ExamConfig(
    id: 'danb_rhs',
    name: 'DANB RHS Exam Prep',
    provider: 'Dental Assisting National Board',
    examVersion: 'v1',
    contentVersion: '1.0',
    domains: [],
    mockExam: MockExamConfig(
      questionCount: 10,
      durationMinutes: 30,
      practicePassingPercent: 0.7,
      allowsBackNavigation: true,
      timed: true,
    ),
    officialScoring: OfficialScoringConfig(
      scaleMinimum: 200,
      scaleMaximum: 800,
      passingScaledScore: 400,
      isComputerAdaptive: false,
    ),
    readiness: ReadinessConfig(
      weights: ReadinessWeights(
        recentAccuracy: 0.2,
        domainMastery: 0.2,
        mockPerformance: 0.2,
        repeatedMastery: 0.2,
        coverage: 0.2,
      ),
      thresholds: [],
      priorScore: 0,
      minimumEvidenceQuestions: 5,
      recencyHalfLifeDays: 14,
      weakDomainPenalty: 0.1,
    ),
    subscriptionProductIds: SubscriptionProductIds(
      weekly: 'w',
      monthly: 'm',
      threeMonths: '3m',
    ),
    freeTier: FreeTierConfig(
      dailyPracticeQuestions: 5,
      diagnosticQuestions: 10,
      includedMockExams: 1,
    ),
    disclaimer: '',
  );
}

BootstrapReady _readySnapshot() {
  return BootstrapReady(
    selectedExamId: 'danb_rhs',
    contentPackage: ContentPackage(
      exam: _fakeExamConfig(),
      contentVersion: '1.0',
      sourceVersion: '1.0',
      generatedAt: DateTime.utc(2026, 1, 1),
      questions: const [],
    ),
    profile: null,
    themePreference: ThemePreference.system,
    readinessSnapshot: null,
    entitlement: Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1)),
    onboardingComplete: false,
    examDateSelection: null,
    experienceLevel: null,
  );
}

/// Forwards every [BootstrapLocalStore] method to [_delegate] unchanged.
class _DelegatingLocalStore implements BootstrapLocalStore {
  _DelegatingLocalStore(this._delegate);
  final BootstrapLocalStore _delegate;

  @override
  Future<String?> readSelectedExamId() => _delegate.readSelectedExamId();
  @override
  Future<void> writeSelectedExamId(String examId) =>
      _delegate.writeSelectedExamId(examId);
  @override
  Future<bool?> readOnboardingComplete() => _delegate.readOnboardingComplete();
  @override
  Future<void> writeOnboardingComplete(bool complete) =>
      _delegate.writeOnboardingComplete(complete);
  @override
  Future<ThemePreference?> readThemePreference() =>
      _delegate.readThemePreference();
  @override
  Future<void> writeThemePreference(ThemePreference preference) =>
      _delegate.writeThemePreference(preference);
  @override
  Future<Entitlement?> readEntitlementSnapshot() =>
      _delegate.readEntitlementSnapshot();
  @override
  Future<void> writeEntitlementSnapshot(Entitlement entitlement) =>
      _delegate.writeEntitlementSnapshot(entitlement);
  @override
  Future<ReadinessSnapshot?> readLatestReadinessSnapshot(String examId) =>
      _delegate.readLatestReadinessSnapshot(examId);
  @override
  Future<void> writeLatestReadinessSnapshot(ReadinessSnapshot snapshot) =>
      _delegate.writeLatestReadinessSnapshot(snapshot);
  @override
  Future<ExamDateSelection?> readExamDateSelection() =>
      _delegate.readExamDateSelection();
  @override
  Future<void> writeExamDateSelection(ExamDateSelection selection) =>
      _delegate.writeExamDateSelection(selection);
  @override
  Future<ExperienceLevel?> readExperienceLevel() =>
      _delegate.readExperienceLevel();
  @override
  Future<void> writeExperienceLevel(ExperienceLevel level) =>
      _delegate.writeExperienceLevel(level);
}

/// [writeExamDateSelection] always fails.
class _ThrowingExamDateWriteLocalStore extends _DelegatingLocalStore {
  _ThrowingExamDateWriteLocalStore(super.delegate);
  @override
  Future<void> writeExamDateSelection(ExamDateSelection selection) async {
    throw StateError('disk full');
  }
}

/// [writeExperienceLevel] always fails.
class _ThrowingExperienceWriteLocalStore extends _DelegatingLocalStore {
  _ThrowingExperienceWriteLocalStore(super.delegate);
  @override
  Future<void> writeExperienceLevel(ExperienceLevel level) async {
    throw StateError('disk full');
  }
}

/// [writeOnboardingComplete] always fails — whichever screen's
/// completion bridge calls it.
class _ThrowingCompletionWriteLocalStore extends _DelegatingLocalStore {
  _ThrowingCompletionWriteLocalStore(super.delegate);
  @override
  Future<void> writeOnboardingComplete(bool complete) async {
    throw StateError('disk full');
  }
}

void main() {
  Widget wrap({
    required BootstrapLocalStore localStore,
    AnalyticsService? analytics,
  }) {
    final AnalyticsService effectiveAnalytics =
        analytics ?? const NoOpAnalyticsService();
    return MaterialApp(
      theme: AppTheme.lightTheme,
      navigatorObservers: [AnalyticsNavigatorObserver(effectiveAnalytics)],
      home: BootstrapSessionScope(
        controller: BootstrapSessionController(_readySnapshot()),
        child: WelcomeScreen(
          localStore: localStore,
          analytics: effectiveAnalytics,
        ),
      ),
    );
  }

  Future<void> reachExamDateScreen(WidgetTester tester) async {
    await tester.tap(find.text('Start Preparing'));
    await tester.pumpAndSettle();
    expect(find.byType(ExamDateScreen), findsOneWidget);
  }

  /// From `ExamDateScreen`, chooses "unscheduled" and taps Continue —
  /// on success this lands on `ExperienceLevelScreen`, *not* Main.
  Future<void> chooseUnscheduledAndContinueToExperience(
      WidgetTester tester) async {
    await tester.tap(find.text("I haven't scheduled it yet"));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(ExperienceLevelScreen), findsOneWidget);
  }

  /// From `ExperienceLevelScreen`, chooses "Just starting" and taps
  /// Continue — the temporary completion bridge, on success, lands on
  /// `MainShell`.
  Future<void> chooseJustStartingAndContinue(WidgetTester tester) async {
    await tester.tap(find.text('Just starting'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Welcome → Exam Date → Experience → successful completion reaches '
      'Main, with Main as the only remaining route', (tester) async {
    final localStore = InMemoryBootstrapLocalStore();
    await tester.pumpWidget(wrap(localStore: localStore));

    await reachExamDateScreen(tester);
    await chooseUnscheduledAndContinueToExperience(tester);
    await chooseJustStartingAndContinue(tester);

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(ExamDateScreen), findsNothing);
    expect(find.byType(ExperienceLevelScreen), findsNothing);

    // Not `tester.state(find.byType(Navigator))`: MainShell now gives
    // each tab its own nested Navigator (PREP-654), so more than one
    // Navigator legitimately exists in the tree once it's mounted — this
    // test cares specifically about the app's root Navigator (the one
    // WelcomeScreen/ExamDateScreen/ExperienceLevelScreen/MainShell were
    // all pushed on), reached explicitly via `rootNavigator: true`.
    final NavigatorState navigator = Navigator.of(
      tester.element(find.byType(MainShell)),
      rootNavigator: true,
    );
    expect(navigator.canPop(), isFalse,
        reason: 'MainShell must be the sole, root route after onboarding '
            'completes');
  });

  testWidgets('attempting Back from Main does not reveal onboarding',
      (tester) async {
    final localStore = InMemoryBootstrapLocalStore();
    await tester.pumpWidget(wrap(localStore: localStore));
    await reachExamDateScreen(tester);
    await chooseUnscheduledAndContinueToExperience(tester);
    await chooseJustStartingAndContinue(tester);
    expect(find.byType(MainShell), findsOneWidget);

    // See the previous test's comment: explicitly the root Navigator, now
    // that MainShell's own per-tab Navigators also exist in the tree.
    final NavigatorState navigator = Navigator.of(
      tester.element(find.byType(MainShell)),
      rootNavigator: true,
    );
    final bool popped = await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(popped, isFalse,
        reason: 'there must be nothing left in the stack to pop to');
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(ExamDateScreen), findsNothing);
    expect(find.byType(ExperienceLevelScreen), findsNothing);
  });

  testWidgets(
      'explicit "Continue for this session" (from Experience Level) '
      'also clears the onboarding stack down to Main only', (tester) async {
    final localStore =
        _ThrowingCompletionWriteLocalStore(InMemoryBootstrapLocalStore());
    await tester.pumpWidget(wrap(localStore: localStore));
    await reachExamDateScreen(tester);
    await chooseUnscheduledAndContinueToExperience(tester);
    await tester.tap(find.text('Just starting'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Continue for this session'), findsOneWidget);
    await tester.tap(find.text('Continue for this session'));
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    // See the first test's comment: explicitly the root Navigator, now
    // that MainShell's own per-tab Navigators also exist in the tree.
    final NavigatorState navigator = Navigator.of(
      tester.element(find.byType(MainShell)),
      rootNavigator: true,
    );
    expect(navigator.canPop(), isFalse);

    // Session-only completion changes only the in-memory shared
    // snapshot — durable storage must remain honestly incomplete.
    final BuildContext mainContext = tester.element(find.byType(MainShell));
    expect(BootstrapSessionScope.snapshotOf(mainContext).onboardingComplete,
        isTrue,
        reason: 'the current session may consider onboarding complete');
    expect(await localStore.readOnboardingComplete(), isNot(isTrue),
        reason: 'the durable flag must never be claimed as written when '
            'it was not');
  });

  testWidgets(
      'a save failure on Exam Date does not clear or otherwise change '
      'the stack — Back from Exam Date still reaches Welcome', (tester) async {
    final localStore =
        _ThrowingExamDateWriteLocalStore(InMemoryBootstrapLocalStore());
    await tester.pumpWidget(wrap(localStore: localStore));
    await reachExamDateScreen(tester);
    await tester.tap(find.text("I haven't scheduled it yet"));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(ExamDateScreen), findsOneWidget);
    expect(find.byType(ExperienceLevelScreen), findsNothing);
    expect(find.byType(MainShell), findsNothing);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    expect(navigator.canPop(), isTrue,
        reason: 'Welcome must still be underneath Exam Date on the stack');

    // The failed write must never have reached the shared controller.
    final BuildContext examDateContext =
        tester.element(find.byType(ExamDateScreen));
    expect(BootstrapSessionScope.snapshotOf(examDateContext).examDateSelection,
        isNull,
        reason: 'a failed write must leave the shared session unchanged');

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets(
      'a save failure on Experience Level does not clear or otherwise '
      'change the stack — Back from Experience still reaches Exam Date '
      'with its saved selection still visible', (tester) async {
    final localStore =
        _ThrowingExperienceWriteLocalStore(InMemoryBootstrapLocalStore());
    await tester.pumpWidget(wrap(localStore: localStore));
    await reachExamDateScreen(tester);
    await chooseUnscheduledAndContinueToExperience(tester);

    await tester.tap(find.text('Just starting'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(ExperienceLevelScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    expect(navigator.canPop(), isTrue,
        reason: 'Exam Date must still be underneath Experience Level on '
            'the stack');

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(ExamDateScreen), findsOneWidget);
    expect(find.bySemanticsLabel("I haven't scheduled it yet, selected"),
        findsOneWidget,
        reason: 'the previously-saved exam-date selection must still be '
            'visible — Back must not lose in-progress state, and the '
            'earlier successful write is untouched by the later failure');
  });

  testWidgets(
      'Back from Experience Level (no failure) returns to Exam Date with '
      'the saved date still visible', (tester) async {
    final localStore = InMemoryBootstrapLocalStore();
    await tester.pumpWidget(wrap(localStore: localStore));
    await reachExamDateScreen(tester);
    await chooseUnscheduledAndContinueToExperience(tester);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(ExamDateScreen), findsOneWidget);
    expect(find.bySemanticsLabel("I haven't scheduled it yet, selected"),
        findsOneWidget);
  });

  testWidgets(
      'Main receives both saved onboarding answers via the '
      'session-synchronized snapshot', (tester) async {
    final localStore = InMemoryBootstrapLocalStore();
    await tester.pumpWidget(wrap(localStore: localStore));
    await reachExamDateScreen(tester);
    await chooseUnscheduledAndContinueToExperience(tester);
    await chooseJustStartingAndContinue(tester);

    final BuildContext mainContext = tester.element(find.byType(MainShell));
    final BootstrapReady mainSnapshot =
        BootstrapSessionScope.snapshotOf(mainContext);

    expect(mainSnapshot.examDateSelection,
        ExamDateSelection(precision: ExamDatePrecision.notScheduled));
    expect(mainSnapshot.experienceLevel, ExperienceLevel.justStarting);
    expect(mainSnapshot.onboardingComplete, isTrue);
  });

  testWidgets(
      'route analytics reports Exam Date, Experience Level, and Main, '
      'with the correct route names, as the stack-clearing navigation '
      'happens', (tester) async {
    final analytics = FakeAnalyticsService();
    final localStore = InMemoryBootstrapLocalStore();
    await tester.pumpWidget(wrap(localStore: localStore, analytics: analytics));

    await reachExamDateScreen(tester);
    expect(analytics.screenViews.contains(ExamDateScreen.route), isTrue);

    await chooseUnscheduledAndContinueToExperience(tester);
    expect(analytics.screenViews.contains(ExperienceLevelScreen.route), isTrue);

    await chooseJustStartingAndContinue(tester);
    expect(analytics.screenViews.contains(MainShell.route), isTrue);
  });

  group('shared session controller identity and re-entry', () {
    testWidgets(
        'the exact same BootstrapSessionController instance is shared by '
        'every onboarding route and Main — no route ever constructs a '
        'new one', (tester) async {
      final localStore = InMemoryBootstrapLocalStore();
      await tester.pumpWidget(wrap(localStore: localStore));

      final BootstrapSessionController welcomeController =
          BootstrapSessionScope.controllerOf(
              tester.element(find.byType(WelcomeScreen)));

      await reachExamDateScreen(tester);
      final BootstrapSessionController examDateController =
          BootstrapSessionScope.controllerOf(
              tester.element(find.byType(ExamDateScreen)));
      expect(identical(welcomeController, examDateController), isTrue);

      await chooseUnscheduledAndContinueToExperience(tester);
      final BootstrapSessionController experienceController =
          BootstrapSessionScope.controllerOf(
              tester.element(find.byType(ExperienceLevelScreen)));
      expect(identical(welcomeController, experienceController), isTrue);

      await chooseJustStartingAndContinue(tester);
      final BootstrapSessionController mainController =
          BootstrapSessionScope.controllerOf(
              tester.element(find.byType(MainShell)));
      expect(identical(welcomeController, mainController), isTrue);
    });

    testWidgets(
        'Save Exam Date → Experience → Back to Exam Date → Back to '
        'Welcome → Start Preparing again: the newly created Exam Date '
        'screen still prefills the saved date from the shared session',
        (tester) async {
      final localStore = InMemoryBootstrapLocalStore();
      await tester.pumpWidget(wrap(localStore: localStore));

      // 1. Save Exam Date.
      await reachExamDateScreen(tester);
      await tester.tap(find.text('I know the exact date'));
      await tester.pump();
      await tester.tap(find.text('Choose a date'));
      await tester.pumpAndSettle();
      // The picker opens with today already selected (`initialDate:
      // today`) — confirming immediately picks that default, with no
      // need to tap a specific day cell (whose number depends on the
      // real current date, which this test doesn't control).
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // 2. Navigate to Experience (already there after Continue above).
      expect(find.byType(ExperienceLevelScreen), findsOneWidget);

      // 3. Back to Exam Date — saved date remains selected.
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(ExamDateScreen), findsOneWidget);
      expect(find.bySemanticsLabel('I know the exact date, selected'),
          findsOneWidget);

      // 4. Back to Welcome.
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);

      // 5. Start Preparing again.
      await tester.tap(find.text('Start Preparing'));
      await tester.pumpAndSettle();

      // 6. The newly created Exam Date screen prefills the saved date —
      // proving the shared session, not a forward-only copy that a
      // route already underneath would have missed.
      expect(find.byType(ExamDateScreen), findsOneWidget);
      expect(find.bySemanticsLabel('I know the exact date, selected'),
          findsOneWidget);
    });

    testWidgets(
        'Save Experience Level, force onboarding-completion persistence '
        'to fail, navigate Back to Exam Date and forward to Experience '
        'again: the newly created Experience screen still prefills the '
        'saved experience selection', (tester) async {
      final localStore =
          _ThrowingCompletionWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(localStore: localStore));

      await reachExamDateScreen(tester);
      await chooseUnscheduledAndContinueToExperience(tester);

      // 1. Save Experience Level. 2. Onboarding-completion persistence
      // fails (this double always fails writeOnboardingComplete), so
      // the screen stays put with a recoverable error rather than
      // reaching Main.
      await tester.tap(find.text('Studying already'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(ExperienceLevelScreen), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);

      // 3. Navigate Back to Exam Date and forward to Experience again.
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(ExamDateScreen), findsOneWidget);

      await chooseUnscheduledAndContinueToExperience(tester);

      // 4. The newly created Experience screen prefills the saved
      // experience selection — the earlier successful experience-level
      // write is untouched by the later completion failure, and is
      // visible from the shared session even to a brand new screen
      // instance.
      expect(find.byType(ExperienceLevelScreen), findsOneWidget);
      expect(
          find.bySemanticsLabel('Studying already, selected'), findsOneWidget);
    });

    testWidgets(
        'reopening a step reads only the shared in-memory session — it '
        'does not restart bootstrap or read SharedPreferences JSON '
        'directly from the screen', (tester) async {
      // `InMemoryBootstrapLocalStore` never touches SharedPreferences at
      // all, and `ExamDateScreen`/`ExperienceLevelScreen` only ever read
      // `BootstrapSessionScope.snapshotOf(context)` to prefill — proven
      // structurally by the prefill still working correctly here with a
      // local store that has no JSON-decoding code path whatsoever to
      // have been (mis-)used.
      final localStore = InMemoryBootstrapLocalStore();
      await tester.pumpWidget(wrap(localStore: localStore));

      await reachExamDateScreen(tester);
      await tester.tap(find.text("I haven't scheduled it yet"));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(ExamDateScreen), findsOneWidget);
      expect(find.bySemanticsLabel("I haven't scheduled it yet, selected"),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('named-route analytics (exact sequence, not just presence)', () {
    /// Registers `WelcomeScreen` as the app's actual *named* initial
    /// route (`initialRoute`/`routes`, the same mechanism `main.dart`
    /// uses via `SplashScreen`) rather than the unnamed `home:` the
    /// other tests in this file use — so `AnalyticsNavigatorObserver`
    /// reports a real `/welcome` for it, not an anonymous `/`. Kept as
    /// a separate helper so the existing stack-clearing tests above
    /// (built on `wrap`) are left completely untouched.
    Widget wrapWithNamedWelcomeRoute({
      required BootstrapLocalStore localStore,
      required AnalyticsService analytics,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        navigatorObservers: [AnalyticsNavigatorObserver(analytics)],
        initialRoute: WelcomeScreen.route,
        routes: {
          WelcomeScreen.route: (_) => BootstrapSessionScope(
                controller: BootstrapSessionController(_readySnapshot()),
                child: WelcomeScreen(
                  localStore: localStore,
                  analytics: analytics,
                ),
              ),
        },
      );
    }

    testWidgets(
        'the full Welcome → Exam Date → Experience Level → Main flow '
        'reports the exact, ordered, deduplicated named-route sequence, '
        'with onboarding_started emitted exactly once as a generic event',
        (tester) async {
      final analytics = FakeAnalyticsService();
      final localStore = InMemoryBootstrapLocalStore();
      await tester.pumpWidget(wrapWithNamedWelcomeRoute(
          localStore: localStore, analytics: analytics));

      // 1. Welcome has the expected named route.
      expect(WelcomeScreen.route, '/welcome');
      expect(analytics.screenViews, ['/welcome']);

      // 2. Tapping Start Preparing records Exam Date exactly once.
      expect(ExamDateScreen.route, '/onboarding/exam-date');
      await reachExamDateScreen(tester);
      expect(
          analytics.screenViews.where((r) => r == ExamDateScreen.route).length,
          1);

      // 5. onboarding_started is a single, generic event — fired once,
      // carrying only the non-sensitive exam ID.
      expect(analytics.events.length, 1);
      expect(analytics.events.single.name, 'onboarding_started');
      expect(analytics.events.single.properties.keys, ['exam_id']);

      // Exam Date → Experience Level records the new route exactly once.
      expect(ExperienceLevelScreen.route, '/onboarding/experience-level');
      await chooseUnscheduledAndContinueToExperience(tester);
      expect(
          analytics.screenViews
              .where((r) => r == ExperienceLevelScreen.route)
              .length,
          1);
      // Still exactly one onboarding_started — Exam Date's own Continue
      // never emits it again.
      expect(analytics.events.length, 1);

      // 3. Completing the experience-level step records Main exactly
      // once.
      expect(MainShell.route, '/main');
      await chooseJustStartingAndContinue(tester);
      expect(
          analytics.screenViews.where((r) => r == MainShell.route).length, 1);

      // 4. + 6. The ordered sequence is exactly these four named routes,
      // once each, in order — proving `pushAndRemoveUntil`'s route
      // removal along the way (of Welcome, Exam Date, and Experience
      // Level from the stack) did not itself generate any extra/
      // duplicate screen-view report. ('home' following is MainShell's
      // own tab-view report for its Home tab becoming active on first
      // build — a separate, legitimate `trackScreenView('home')` call,
      // not a route/Navigator event and not a duplicate of '/main'.)
      expect(analytics.screenViews, [
        '/welcome',
        '/onboarding/exam-date',
        '/onboarding/experience-level',
        '/main',
        'home',
      ]);

      // 7. Back from Main cannot reveal Welcome, Exam Date, or
      // Experience Level, and a no-op pop attempt does not itself
      // report a duplicate screen view.
      // See the earlier tests' comment on this same lookup: explicitly
      // the root Navigator, now that MainShell's own per-tab Navigators
      // also exist in the tree.
      final NavigatorState navigator = Navigator.of(
        tester.element(find.byType(MainShell)),
        rootNavigator: true,
      );
      final bool popped = await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(popped, isFalse);
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.byType(ExamDateScreen), findsNothing);
      expect(find.byType(ExperienceLevelScreen), findsNothing);
      expect(find.byType(MainShell), findsOneWidget);
      expect(analytics.screenViews, [
        '/welcome',
        '/onboarding/exam-date',
        '/onboarding/experience-level',
        '/main',
        'home',
      ]);
    });

    testWidgets(
        '8. the "Continue for this session" path (from Experience Level) '
        'also reports /main exactly once', (tester) async {
      final analytics = FakeAnalyticsService();
      final localStore =
          _ThrowingCompletionWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrapWithNamedWelcomeRoute(
          localStore: localStore, analytics: analytics));

      await reachExamDateScreen(tester);
      await chooseUnscheduledAndContinueToExperience(tester);
      await tester.tap(find.text('Just starting'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Continue for this session'), findsOneWidget,
          reason: 'the completion save must have failed to reach this '
              'path, matching the throwing double used here');
      expect(analytics.screenViews.contains(MainShell.route), isFalse,
          reason: 'Main must not be reported yet — the save failed and '
              'nothing navigated');

      await tester.tap(find.text('Continue for this session'));
      await tester.pumpAndSettle();

      expect(
          analytics.screenViews.where((r) => r == MainShell.route).length, 1);
      // 'home' follows — MainShell's own tab-view report for its Home
      // tab becoming active, not a route event.
      expect(analytics.screenViews.last, 'home');
      expect(analytics.screenViews[analytics.screenViews.length - 2],
          MainShell.route);
    });
  });
}
