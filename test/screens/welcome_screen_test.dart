import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/welcome_screen.dart';
import 'package:danb_rhs_prep/services/analytics_service.dart';
import 'package:danb_rhs_prep/services/fakes/fake_analytics_service.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/primary_button.dart';

/// The real bundled DANB RHS content, decoded once — the same
/// `File(...).readAsStringSync()` + `ExamContentCodec` pattern used
/// throughout `test/bootstrap/`, not a fabricated fixture.
final ContentPackage _realPackage = () {
  final String source =
      File('assets/content/danb_rhs/content.json').readAsStringSync();
  return const ExamContentCodec().decode(source);
}();

/// A [ContentPackage] identical to [_realPackage] except [name] replaces
/// the exam's display name — used to prove `WelcomeScreen` renders
/// whatever `ExamConfig.name` it's given rather than a hardcoded DANB
/// string.
ContentPackage _packageWithExamName(String name) {
  final ExamConfig realExam = _realPackage.exam;
  final ExamConfig customExam = ExamConfig(
    id: realExam.id,
    name: name,
    provider: realExam.provider,
    examVersion: realExam.examVersion,
    contentVersion: realExam.contentVersion,
    domains: realExam.domains,
    mockExam: realExam.mockExam,
    officialScoring: realExam.officialScoring,
    readiness: realExam.readiness,
    subscriptionProductIds: realExam.subscriptionProductIds,
    freeTier: realExam.freeTier,
    disclaimer: realExam.disclaimer,
  );
  return ContentPackage(
    exam: customExam,
    contentVersion: _realPackage.contentVersion,
    sourceVersion: _realPackage.sourceVersion,
    generatedAt: _realPackage.generatedAt,
    questions: _realPackage.questions,
  );
}

BootstrapReady _readySnapshot({String? examName}) {
  return BootstrapReady(
    selectedExamId: kDefaultExamId,
    contentPackage:
        examName == null ? _realPackage : _packageWithExamName(examName),
    profile: null,
    themePreference: ThemePreference.system,
    readinessSnapshot: null,
    entitlement: Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1)),
    onboardingComplete: false,
  );
}

/// Forwards every [BootstrapLocalStore] method to [_delegate] unchanged —
/// a base for test doubles below that need to override only
/// [writeOnboardingComplete]'s behavior.
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
}

/// [writeOnboardingComplete] always fails — simulates a persistent local
/// storage failure (e.g. disk full).
class _ThrowingWriteLocalStore extends _DelegatingLocalStore {
  _ThrowingWriteLocalStore(super.delegate);
  int writeAttempts = 0;

  @override
  Future<void> writeOnboardingComplete(bool complete) async {
    writeAttempts++;
    throw StateError('disk full');
  }
}

/// [writeOnboardingComplete] fails on its first call, then genuinely
/// succeeds on every call after — simulates a transient failure a
/// user-initiated Retry can recover from.
class _FlakyWriteLocalStore extends _DelegatingLocalStore {
  _FlakyWriteLocalStore(super.delegate);
  int writeAttempts = 0;

  @override
  Future<void> writeOnboardingComplete(bool complete) {
    writeAttempts++;
    if (writeAttempts == 1) {
      return Future<void>.error(StateError('disk full'));
    }
    return super.writeOnboardingComplete(complete);
  }
}

/// [writeOnboardingComplete] never resolves on its own — the test
/// controls exactly when it completes via [writeCompleter], for
/// deterministic control of an in-flight save (no `pump(Duration(...))`
/// guessing).
class _ControlledWriteLocalStore extends _DelegatingLocalStore {
  _ControlledWriteLocalStore(super.delegate);
  final Completer<void> writeCompleter = Completer<void>();
  int writeAttempts = 0;

  @override
  Future<void> writeOnboardingComplete(bool complete) {
    writeAttempts++;
    return writeCompleter.future;
  }
}

/// [trackEvent] always throws — proves analytics failure can never block
/// onboarding. [trackScreenView] is left working normally since nothing
/// here exercises route-level analytics.
class _ThrowingTrackEventAnalyticsService implements AnalyticsService {
  @override
  void trackScreenView(String screenId) {}

  @override
  void trackEvent(String name, {Map<String, Object?> properties = const {}}) {
    throw StateError('analytics backend unavailable');
  }
}

void main() {
  Widget wrap(
    BootstrapLocalStore localStore, {
    AnalyticsService? analytics,
    String? examName,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: BootstrapSessionScope(
        snapshot: _readySnapshot(examName: examName),
        child: WelcomeScreen(
          localStore: localStore,
          analytics: analytics ?? const NoOpAnalyticsService(),
        ),
      ),
    );
  }

  group('exam identity', () {
    testWidgets('renders the exact exam name from the supplied ExamConfig',
        (tester) async {
      await tester.pumpWidget(wrap(InMemoryBootstrapLocalStore()));

      expect(find.text('DANB RHS Exam Prep'), findsOneWidget);
    });

    testWidgets(
        'a different fake exam name appears — proving there is no '
        'hardcoded screen value', (tester) async {
      await tester.pumpWidget(wrap(InMemoryBootstrapLocalStore(),
          examName: 'Custom Test Exam XYZ'));

      expect(find.text('Custom Test Exam XYZ'), findsOneWidget);
      expect(find.text('DANB RHS Exam Prep'), findsNothing);
    });

    testWidgets('the screen source never queries JSON or rootBundle directly',
        (tester) async {
      final String source =
          File('lib/screens/welcome_screen.dart').readAsStringSync();
      expect(source.contains('rootBundle'), isFalse);
      expect(source.contains('dart:convert'), isFalse);
      expect(source.contains("import 'dart:io'"), isFalse);
    });
  });

  group('required welcome content', () {
    testWidgets('shows the exact headline', (tester) async {
      await tester.pumpWidget(wrap(InMemoryBootstrapLocalStore()));

      expect(find.text("Know when you're ready to pass."), findsOneWidget);
    });

    testWidgets('shows the exact supporting copy', (tester) async {
      await tester.pumpWidget(wrap(InMemoryBootstrapLocalStore()));

      expect(
        find.text(
          'Build confidence with focused practice, clear explanations, '
          'and progress you can understand.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('exactly one primary CTA, labeled Start Preparing',
        (tester) async {
      await tester.pumpWidget(wrap(InMemoryBootstrapLocalStore()));

      expect(find.text('Start Preparing'), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
    });

    testWidgets('no Login, Sign Up, Skip, or secondary CTA appear',
        (tester) async {
      await tester.pumpWidget(wrap(InMemoryBootstrapLocalStore()));

      for (final forbidden in ['Login', 'Log In', 'Sign Up', 'Skip']) {
        expect(find.text(forbidden), findsNothing,
            reason: '"$forbidden" must not appear on the welcome screen');
      }
      // No secondary CTA in the default (non-error) state.
      expect(find.byType(SecondaryButton), findsNothing);
    });

    testWidgets('reading order matches the required visual order',
        (tester) async {
      await tester.pumpWidget(wrap(InMemoryBootstrapLocalStore()));

      final double identityY =
          tester.getTopLeft(find.text('DANB RHS Exam Prep')).dy;
      final double headlineY =
          tester.getTopLeft(find.text("Know when you're ready to pass.")).dy;
      final double copyY = tester
          .getTopLeft(find.text(
              'Build confidence with focused practice, clear explanations, '
              'and progress you can understand.'))
          .dy;
      final double ctaY = tester.getTopLeft(find.byType(PrimaryButton)).dy;

      expect(identityY, lessThan(headlineY));
      expect(headlineY, lessThan(copyY));
      expect(copyY, lessThan(ctaY));
    });
  });

  group('accessibility and responsive behavior', () {
    testWidgets('the CTA meets the 44x44 minimum interactive size',
        (tester) async {
      await tester.pumpWidget(wrap(InMemoryBootstrapLocalStore()));

      final Size size = tester.getSize(find.byType(PrimaryButton));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('the CTA exposes a clear button semantic', (tester) async {
      await tester.pumpWidget(wrap(InMemoryBootstrapLocalStore()));

      expect(
          find.ancestor(
              of: find.text('Start Preparing'),
              matching: find.byWidgetPredicate(
                  (w) => w is Semantics && w.properties.button == true)),
          findsWidgets,
          reason: 'the CTA must expose an explicit button semantic');
    });

    testWidgets('renders under light and dark themes', (tester) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester
            .pumpWidget(wrap(InMemoryBootstrapLocalStore(), theme: theme));
        expect(find.text('Start Preparing'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('4.0x text at 320x568 renders without exceptions or truncation',
        (tester) async {
      final double dpr = tester.view.devicePixelRatio;
      tester.view.physicalSize = Size(320 * dpr, 568 * dpr);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(4.0)),
          child: wrap(InMemoryBootstrapLocalStore()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Start Preparing'), findsOneWidget);
      expect(find.text("Know when you're ready to pass."), findsOneWidget);
    });
  });

  group('CTA behavior and analytics', () {
    testWidgets(
        'tapping Start Preparing emits onboarding_started exactly once '
        'and reaches MainShell', (tester) async {
      final analytics = FakeAnalyticsService();
      await tester.pumpWidget(
          wrap(InMemoryBootstrapLocalStore(), analytics: analytics));

      await tester.tap(find.text('Start Preparing'));
      await tester.pumpAndSettle();

      expect(analytics.events.where((e) => e.name == 'onboarding_started'),
          hasLength(1));
      expect(analytics.events.first.properties['exam_id'], kDefaultExamId,
          reason: 'only the non-sensitive exam ID may be included, '
              'sourced from ExamConfig, never hardcoded');
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('repeated taps do not duplicate the event or navigation',
        (tester) async {
      final controlled =
          _ControlledWriteLocalStore(InMemoryBootstrapLocalStore());
      final analytics = FakeAnalyticsService();
      await tester.pumpWidget(wrap(controlled, analytics: analytics));

      await tester.tap(find.text('Start Preparing'));
      await tester.pump();
      // Button is now loading/disabled — attempt a second tap anyway to
      // prove the guard, not just the UI's disabled state.
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump();

      expect(controlled.writeAttempts, 1);
      expect(analytics.events.length, 1);

      controlled.writeCompleter.complete();
      await tester.pumpAndSettle();

      expect(analytics.events.length, 1);
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('a persistence Retry does not emit the event again',
        (tester) async {
      final flaky = _FlakyWriteLocalStore(InMemoryBootstrapLocalStore());
      final analytics = FakeAnalyticsService();
      await tester.pumpWidget(wrap(flaky, analytics: analytics));

      await tester.tap(find.text('Start Preparing'));
      await tester.pumpAndSettle();
      expect(analytics.events.length, 1);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(flaky.writeAttempts, 2);
      expect(analytics.events.length, 1,
          reason: 'Retry continues the same already-reported attempt, '
              'it must not fire onboarding_started a second time');
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('analytics failure does not block onboarding', (tester) async {
      await tester.pumpWidget(wrap(InMemoryBootstrapLocalStore(),
          analytics: _ThrowingTrackEventAnalyticsService()));

      await tester.tap(find.text('Start Preparing'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets(
        'the successful flow reaches the current next destination '
        '(MainShell) via the documented temporary bridge', (tester) async {
      final localStore = InMemoryBootstrapLocalStore();
      await tester.pumpWidget(wrap(localStore));

      await tester.tap(find.text('Start Preparing'));
      await tester.pumpAndSettle();

      expect(await localStore.readOnboardingComplete(), isTrue);
      expect(find.byType(MainShell), findsOneWidget);
    });
  });

  group('onboarding-save failure remains recoverable', () {
    testWidgets(
        'a failed save shows a recoverable, accessible error and does not '
        'navigate', (tester) async {
      final localStore =
          _ThrowingWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(localStore));

      await tester.tap(find.text('Start Preparing'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining("couldn't save"), findsOneWidget);
      expect(
          find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.liveRegion == true),
          findsOneWidget);
      expect(await localStore.readOnboardingComplete(), isNot(isTrue));
    });

    testWidgets('"Continue for this session" navigates without persisting',
        (tester) async {
      final localStore =
          _ThrowingWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(localStore));

      await tester.tap(find.text('Start Preparing'));
      await tester.pumpAndSettle();
      expect(find.text('Continue for this session'), findsOneWidget);

      await tester.tap(find.text('Continue for this session'));
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
      expect(await localStore.readOnboardingComplete(), isNot(isTrue));
    });

    testWidgets('disposing while a save is outstanding causes no exception',
        (tester) async {
      final controlled =
          _ControlledWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(controlled));

      await tester.tap(find.text('Start Preparing'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      controlled.writeCompleter.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
