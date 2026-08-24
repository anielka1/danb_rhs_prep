import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/navigation/analytics_navigator_observer.dart';
import 'package:danb_rhs_prep/screens/exam_date_screen.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/welcome_screen.dart';
import 'package:danb_rhs_prep/services/analytics_service.dart';
import 'package:danb_rhs_prep/services/fakes/fake_analytics_service.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

/// Verifies the full onboarding navigation stack across `WelcomeScreen`
/// and `ExamDateScreen` together — the individual screens' own test
/// files each verify their local behavior in isolation, but only a real,
/// multi-route `Navigator` can prove what the stack itself ends up
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
}

/// [writeExamDateSelection] always fails.
class _ThrowingExamDateWriteLocalStore extends _DelegatingLocalStore {
  _ThrowingExamDateWriteLocalStore(super.delegate);
  @override
  Future<void> writeExamDateSelection(ExamDateSelection selection) async {
    throw StateError('disk full');
  }
}

/// [writeExamDateSelection] succeeds, but [writeOnboardingComplete] always
/// fails.
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
        snapshot: _readySnapshot(),
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

  Future<void> chooseUnscheduledAndContinue(WidgetTester tester) async {
    await tester.tap(find.text("I haven't scheduled it yet"));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Welcome → Exam Date → successful completion reaches Main, with '
      'Main as the only remaining route', (tester) async {
    final localStore = InMemoryBootstrapLocalStore();
    await tester.pumpWidget(wrap(localStore: localStore));

    await reachExamDateScreen(tester);
    await chooseUnscheduledAndContinue(tester);

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(ExamDateScreen), findsNothing);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    expect(navigator.canPop(), isFalse,
        reason: 'MainShell must be the sole, root route after onboarding '
            'completes');
  });

  testWidgets('attempting Back from Main does not reveal onboarding',
      (tester) async {
    final localStore = InMemoryBootstrapLocalStore();
    await tester.pumpWidget(wrap(localStore: localStore));
    await reachExamDateScreen(tester);
    await chooseUnscheduledAndContinue(tester);
    expect(find.byType(MainShell), findsOneWidget);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    final bool popped = await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(popped, isFalse,
        reason: 'there must be nothing left in the stack to pop to');
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(ExamDateScreen), findsNothing);
  });

  testWidgets(
      'explicit "Continue for this session" also clears the onboarding '
      'stack down to Main only', (tester) async {
    final localStore =
        _ThrowingCompletionWriteLocalStore(InMemoryBootstrapLocalStore());
    await tester.pumpWidget(wrap(localStore: localStore));
    await reachExamDateScreen(tester);
    await chooseUnscheduledAndContinue(tester);

    expect(find.text('Continue for this session'), findsOneWidget);
    await tester.tap(find.text('Continue for this session'));
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });

  testWidgets(
      'a save failure does not clear or otherwise change the stack — Back '
      'from Exam Date still reaches Welcome', (tester) async {
    final localStore =
        _ThrowingExamDateWriteLocalStore(InMemoryBootstrapLocalStore());
    await tester.pumpWidget(wrap(localStore: localStore));
    await reachExamDateScreen(tester);
    await chooseUnscheduledAndContinue(tester);

    expect(find.byType(ExamDateScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    expect(navigator.canPop(), isTrue,
        reason: 'Welcome must still be underneath Exam Date on the stack');

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets(
      'route analytics reports Exam Date and Main, with the correct '
      'route names, as the stack-clearing navigation happens', (tester) async {
    final analytics = FakeAnalyticsService();
    final localStore = InMemoryBootstrapLocalStore();
    await tester.pumpWidget(wrap(localStore: localStore, analytics: analytics));

    await reachExamDateScreen(tester);
    expect(analytics.screenViews.contains(ExamDateScreen.route), isTrue);

    await chooseUnscheduledAndContinue(tester);
    expect(analytics.screenViews.contains(MainShell.route), isTrue);
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
                snapshot: _readySnapshot(),
                child: WelcomeScreen(
                  localStore: localStore,
                  analytics: analytics,
                ),
              ),
        },
      );
    }

    testWidgets(
        'the full Welcome → Exam Date → Main flow reports the exact, '
        'ordered, deduplicated named-route sequence, with '
        'onboarding_started emitted exactly once as a generic event',
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

      // 3. Completing the exam-date step records Main exactly once.
      expect(MainShell.route, '/main');
      await chooseUnscheduledAndContinue(tester);
      expect(
          analytics.screenViews.where((r) => r == MainShell.route).length, 1);

      // 4. + 6. The ordered sequence is exactly these three named routes,
      // once each, in order — proving `pushAndRemoveUntil`'s route
      // removal along the way (of Welcome and Exam Date from the stack)
      // did not itself generate any extra/duplicate screen-view report.
      // ('home' following is MainShell's own tab-view report for its
      // Home tab becoming active on first build — a separate,
      // legitimate `trackScreenView('home')` call, not a route/Navigator
      // event and not a duplicate of '/main'.)
      expect(analytics.screenViews,
          ['/welcome', '/onboarding/exam-date', '/main', 'home']);

      // 7. Back from Main cannot reveal Welcome or Exam Date, and a
      // no-op pop attempt does not itself report a duplicate screen view.
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      final bool popped = await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(popped, isFalse);
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.byType(ExamDateScreen), findsNothing);
      expect(find.byType(MainShell), findsOneWidget);
      expect(analytics.screenViews,
          ['/welcome', '/onboarding/exam-date', '/main', 'home']);
    });

    testWidgets(
        '8. the "Continue for this session" path also reports /main '
        'exactly once', (tester) async {
      final analytics = FakeAnalyticsService();
      final localStore =
          _ThrowingCompletionWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrapWithNamedWelcomeRoute(
          localStore: localStore, analytics: analytics));

      await reachExamDateScreen(tester);
      await chooseUnscheduledAndContinue(tester);
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
