import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/repositories/bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_user_settings_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/user_settings_repository.dart';
import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/screens/exam_date_screen.dart';
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
    examDateSelection: null,
    experienceLevel: null,
  );
}

/// [trackEvent] always throws — proves analytics failure can never block
/// onboarding.
class _ThrowingTrackEventAnalyticsService implements AnalyticsService {
  @override
  void trackScreenView(String screenId) {}

  @override
  void trackEvent(String name, {Map<String, Object?> properties = const {}}) {
    throw StateError('analytics backend unavailable');
  }
}

void main() {
  Widget wrap({
    AnalyticsService? analytics,
    String? examName,
    ThemeData? theme,
    BootstrapLocalStore? localStore,
    UserSettingsRepository? userSettingsRepository,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: BootstrapSessionScope(
        controller:
            BootstrapSessionController(_readySnapshot(examName: examName)),
        child: WelcomeScreen(
          localStore: localStore ?? InMemoryBootstrapLocalStore(),
          analytics: analytics ?? const NoOpAnalyticsService(),
          userSettingsRepository: userSettingsRepository,
        ),
      ),
    );
  }

  group('exam identity', () {
    testWidgets('renders the exact exam name from the supplied ExamConfig',
        (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.text('DANB RHS Exam Prep'), findsOneWidget);
    });

    testWidgets(
        'a different fake exam name appears — proving there is no '
        'hardcoded screen value', (tester) async {
      await tester.pumpWidget(wrap(examName: 'Custom Test Exam XYZ'));

      expect(find.text('Custom Test Exam XYZ'), findsOneWidget);
      expect(find.text('DANB RHS Exam Prep'), findsNothing);
    });
  });

  group('required welcome content', () {
    testWidgets('shows the exact headline', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.text('A little practice.\nMore confidence.'), findsOneWidget);
    });

    testWidgets('shows the exact supporting copy', (tester) async {
      await tester.pumpWidget(wrap());

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
      await tester.pumpWidget(wrap());

      expect(find.text('Start Preparing'), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
    });

    testWidgets('no Login, Sign Up, Skip, or secondary CTA appear',
        (tester) async {
      await tester.pumpWidget(wrap());

      for (final forbidden in ['Login', 'Log In', 'Sign Up', 'Skip']) {
        expect(find.text(forbidden), findsNothing,
            reason: '"$forbidden" must not appear on the welcome screen');
      }
      expect(find.byType(SecondaryButton), findsNothing);
    });
  });

  group('accessibility and responsive behavior', () {
    testWidgets('the CTA meets the 44x44 minimum interactive size',
        (tester) async {
      await tester.pumpWidget(wrap());

      final Size size = tester.getSize(find.byType(PrimaryButton));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('renders under light and dark themes', (tester) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(wrap(theme: theme));
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
          child: wrap(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Start Preparing'), findsOneWidget);
      expect(find.text('A little practice.\nMore confidence.'), findsOneWidget);
    });
  });

  group('CTA behavior and analytics', () {
    testWidgets(
        'tapping Start Preparing emits onboarding_started exactly once, '
        'routes to ExamDateScreen, and does not mark onboarding complete',
        (tester) async {
      final analytics = FakeAnalyticsService();
      final localStore = InMemoryBootstrapLocalStore();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BootstrapSessionScope(
            controller: BootstrapSessionController(_readySnapshot()),
            child: WelcomeScreen(localStore: localStore, analytics: analytics),
          ),
        ),
      );

      await tester.tap(find.text('Start Preparing'));
      await tester.pumpAndSettle();

      expect(analytics.events.where((e) => e.name == 'onboarding_started'),
          hasLength(1));
      expect(analytics.events.first.properties['exam_id'], kDefaultExamId);
      expect(find.byType(ExamDateScreen), findsOneWidget);
      expect(find.byType(MainShell), findsNothing,
          reason: 'Welcome must no longer route directly to MainShell');
      expect(await localStore.readOnboardingComplete(), isNot(isTrue),
          reason: 'Welcome must no longer mark onboarding complete itself');
    });

    testWidgets('repeated taps do not duplicate the event or navigation',
        (tester) async {
      final analytics = FakeAnalyticsService();
      await tester.pumpWidget(wrap(analytics: analytics));

      await tester.tap(find.text('Start Preparing'));
      // Immediately again, before the push transition settles — the
      // button becomes disabled (via `_busy`) synchronously on the
      // first tap.
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(analytics.events.length, 1);
      expect(find.byType(ExamDateScreen), findsOneWidget);
    });

    testWidgets('analytics failure does not block routing to ExamDateScreen',
        (tester) async {
      await tester
          .pumpWidget(wrap(analytics: _ThrowingTrackEventAnalyticsService()));

      await tester.tap(find.text('Start Preparing'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ExamDateScreen), findsOneWidget);
    });

    testWidgets(
        'Back from ExamDateScreen returns to Welcome, and Start Preparing '
        'works again without re-emitting the event', (tester) async {
      final analytics = FakeAnalyticsService();
      await tester.pumpWidget(wrap(analytics: analytics));

      await tester.tap(find.text('Start Preparing'));
      await tester.pumpAndSettle();
      expect(find.byType(ExamDateScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(ExamDateScreen), findsNothing);
      expect(analytics.events.length, 1);

      await tester.tap(find.text('Start Preparing'));
      await tester.pumpAndSettle();

      expect(find.byType(ExamDateScreen), findsOneWidget);
      expect(analytics.events.length, 1,
          reason: 'onboarding_started must not fire a second time for the '
              'same onboarding attempt');
    });
  });

  group('userSettingsRepository forwarding (PREP-663)', () {
    testWidgets(
        'is forwarded all the way from WelcomeScreen through ExamDateScreen '
        'to ExperienceLevelScreen, which saves a real UserProfile when '
        'onboarding actually completes — proving the production wiring, '
        'not just ExperienceLevelScreen in isolation', (tester) async {
      final userSettingsRepository = InMemoryUserSettingsRepository();

      await tester
          .pumpWidget(wrap(userSettingsRepository: userSettingsRepository));
      await tester.tap(find.text('Start Preparing'));
      await tester.pumpAndSettle();
      expect(find.byType(ExamDateScreen), findsOneWidget);

      await tester.tap(find.text("I haven't scheduled it yet"));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
      final UserProfile? saved =
          await userSettingsRepository.loadProfile(kDefaultExamId);
      expect(saved, isNotNull);
      expect(saved!.experienceLevel, isNull);
      expect(saved.onboardingComplete, isTrue);
    });
  });
}
