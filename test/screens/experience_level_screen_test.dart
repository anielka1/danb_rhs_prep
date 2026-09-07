import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_user_settings_repository.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/experience_level.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_user_settings_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/user_settings_repository.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/screens/experience_level_screen.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/primary_button.dart';

/// A minimal, valid [ContentPackage]/[ExamConfig] — not the real bundled
/// asset, since none of these tests need real question content, only a
/// [BootstrapReady] to satisfy `BootstrapSessionScope`.
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

BootstrapReady _readySnapshot({
  ExperienceLevel? experienceLevel,
  ExamDateSelection? examDateSelection,
  ThemePreference themePreference = ThemePreference.system,
}) {
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
    themePreference: themePreference,
    readinessSnapshot: null,
    entitlement: Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1)),
    onboardingComplete: false,
    examDateSelection: examDateSelection,
    experienceLevel: experienceLevel,
  );
}

/// Forwards every [BootstrapLocalStore] method to [_delegate] unchanged —
/// a base for test doubles that override only one write method's
/// behavior.
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

/// [writeExperienceLevel] always fails — the selection itself never
/// saves.
class _ThrowingSelectionWriteLocalStore extends _DelegatingLocalStore {
  _ThrowingSelectionWriteLocalStore(super.delegate);
  int writeAttempts = 0;

  @override
  Future<void> writeExperienceLevel(ExperienceLevel level) async {
    writeAttempts++;
    throw StateError('disk full');
  }
}

/// [writeExperienceLevel] succeeds normally, but [writeOnboardingComplete]
/// always fails — the selection is durably saved, only completion fails.
class _ThrowingCompletionWriteLocalStore extends _DelegatingLocalStore {
  _ThrowingCompletionWriteLocalStore(super.delegate);

  @override
  Future<void> writeOnboardingComplete(bool complete) async {
    throw StateError('disk full');
  }
}

/// [writeExperienceLevel] never resolves on its own — the test controls
/// exactly when it completes via [writeCompleter].
class _ControlledSelectionWriteLocalStore extends _DelegatingLocalStore {
  _ControlledSelectionWriteLocalStore(super.delegate);
  final Completer<void> writeCompleter = Completer<void>();
  int writeAttempts = 0;

  @override
  Future<void> writeExperienceLevel(ExperienceLevel level) {
    writeAttempts++;
    return writeCompleter.future;
  }
}

void main() {
  Widget wrap({
    required BootstrapLocalStore localStore,
    ExperienceLevel? restoredSelection,
    ThemeData? theme,
    UserSettingsRepository? userSettingsRepository,
    ExamDateSelection? examDateSelection,
    ThemePreference themePreference = ThemePreference.system,
    DateTime Function()? now,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: BootstrapSessionScope(
        controller: BootstrapSessionController(_readySnapshot(
          experienceLevel: restoredSelection,
          examDateSelection: examDateSelection,
          themePreference: themePreference,
        )),
        child: ExperienceLevelScreen(
          localStore: localStore,
          userSettingsRepository: userSettingsRepository,
          now: now,
        ),
      ),
    );
  }

  group('required content', () {
    testWidgets('shows the exact heading and supporting copy', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      expect(find.text('Where are you in your preparation?'), findsOneWidget);
      expect(
        find.text('Choose the option that best describes you right now.'),
        findsOneWidget,
      );
    });

    testWidgets('offers exactly the three required labels', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      expect(find.text('Just starting'), findsOneWidget);
      expect(find.text('Studying already'), findsOneWidget);
      expect(find.text('Taking the exam again'), findsOneWidget);
    });

    testWidgets('no option is preselected on a fresh install', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      expect(
          find.bySemanticsLabel('Just starting, not selected'), findsOneWidget);
      expect(find.bySemanticsLabel('Studying already, not selected'),
          findsOneWidget);
      expect(find.bySemanticsLabel('Taking the exam again, not selected'),
          findsOneWidget);
    });
  });

  group('selecting an option', () {
    testWidgets(
        'selecting each option exposes selected semantics, others stay '
        'not-selected — not conveyed by color alone', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      await tester.tap(find.text('Studying already'));
      await tester.pump();

      expect(
          find.bySemanticsLabel('Studying already, selected'), findsOneWidget);
      expect(
          find.bySemanticsLabel('Just starting, not selected'), findsOneWidget);
      expect(find.bySemanticsLabel('Taking the exam again, not selected'),
          findsOneWidget);
    });

    testWidgets('a saved selection prefills the screen', (tester) async {
      await tester.pumpWidget(wrap(
        localStore: InMemoryBootstrapLocalStore(),
        restoredSelection: ExperienceLevel.retakingExam,
      ));

      expect(find.bySemanticsLabel('Taking the exam again, selected'),
          findsOneWidget);
    });
  });

  group('Continue validation', () {
    testWidgets('Continue is disabled until a choice is made', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      final PrimaryButton button = tester.widget(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Continue is enabled once a choice is made', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));
      await tester.tap(find.text('Just starting'));
      await tester.pump();

      final PrimaryButton button = tester.widget(find.byType(PrimaryButton));
      expect(button.onPressed, isNotNull);
    });
  });

  group('save behavior', () {
    testWidgets(
        'Continue saves the selection and reaches MainShell only after '
        'both writes succeed', (tester) async {
      final localStore = InMemoryBootstrapLocalStore();
      await tester.pumpWidget(wrap(localStore: localStore));
      await tester.tap(find.text('Just starting'));
      await tester.pump();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(
          await localStore.readExperienceLevel(), ExperienceLevel.justStarting);
      expect(await localStore.readOnboardingComplete(), isTrue);
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets(
        'a failed experience-level save is recoverable: stays on screen, '
        'shows an error, does not mark onboarding complete', (tester) async {
      final localStore =
          _ThrowingSelectionWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(localStore: localStore));
      await tester.tap(find.text('Just starting'));
      await tester.pump();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(ExperienceLevelScreen), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining("couldn't save this"), findsOneWidget);
      expect(await localStore.readOnboardingComplete(), isNot(isTrue));
    });

    testWidgets('Retry after a failed selection save can succeed',
        (tester) async {
      final backing = InMemoryBootstrapLocalStore();
      final localStore = _ThrowingSelectionWriteLocalStore(backing);
      await tester.pumpWidget(wrap(localStore: localStore));
      await tester.tap(find.text('Just starting'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(localStore.writeAttempts, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(localStore.writeAttempts, 2);
      // This double is permanently broken — it fails again, remaining
      // recoverable rather than stuck loading.
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets(
        'a failed onboarding-completion save after a successful '
        'experience-level save is recoverable, with a session-only '
        'continuation available', (tester) async {
      final localStore =
          _ThrowingCompletionWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(localStore: localStore));
      await tester.tap(find.text('Just starting'));
      await tester.pump();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Continue for this session'), findsOneWidget);
      expect(
          await localStore.readExperienceLevel(), ExperienceLevel.justStarting,
          reason: 'the experience-level selection itself already saved '
              'successfully');
      expect(await localStore.readOnboardingComplete(), isNot(isTrue));

      await tester.tap(find.text('Continue for this session'));
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
      expect(await localStore.readOnboardingComplete(), isNot(isTrue),
          reason: 'session-only continuation must not claim persistence '
              'succeeded');
    });

    testWidgets('duplicate taps do not duplicate writes or navigation',
        (tester) async {
      final controlled =
          _ControlledSelectionWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(localStore: controlled));
      await tester.tap(find.text('Just starting'));
      await tester.pump();

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump();

      expect(controlled.writeAttempts, 1);

      controlled.writeCompleter.complete();
      await tester.pumpAndSettle();

      expect(controlled.writeAttempts, 1);
      expect(find.byType(MainShell), findsOneWidget);
    });
  });

  group('accessibility and responsive behavior', () {
    testWidgets('Continue meets the 44x44 minimum interactive size',
        (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      final Size size = tester.getSize(find.byType(PrimaryButton));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('renders under light and dark themes', (tester) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
            wrap(localStore: InMemoryBootstrapLocalStore(), theme: theme));
        expect(find.text('Where are you in your preparation?'), findsOneWidget);
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
          child: wrap(localStore: InMemoryBootstrapLocalStore()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Where are you in your preparation?'), findsOneWidget);
      expect(find.text('Just starting'), findsOneWidget);
    });

    // A visual/layout-order check only — proves top-to-bottom widget
    // position, not accessibility/screen-reader traversal order. See
    // `test/screens/experience_level_screen_semantics_test.dart` for the
    // real semantics-tree traversal test.
    testWidgets(
        'visual layout order matches heading, copy, choices, Continue '
        '(not a semantics/VoiceOver check — see the dedicated semantics '
        'traversal test file for that)', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      final double headingY =
          tester.getTopLeft(find.text('Where are you in your preparation?')).dy;
      final double copyY = tester
          .getTopLeft(
              find.text('Choose the option that best describes you right now.'))
          .dy;
      final double firstChoiceY =
          tester.getTopLeft(find.text('Just starting')).dy;
      final double lastChoiceY =
          tester.getTopLeft(find.text('Taking the exam again')).dy;
      final double continueY = tester.getTopLeft(find.byType(PrimaryButton)).dy;

      expect(headingY, lessThan(copyY));
      expect(copyY, lessThan(firstChoiceY));
      expect(firstChoiceY, lessThan(lastChoiceY));
      expect(lastChoiceY, lessThan(continueY));
    });
  });

  group('durable UserProfile (PREP-663)', () {
    testWidgets(
        'fresh install: completing onboarding saves a real UserProfile '
        'reflecting the exam date, experience level, and theme already '
        'known this session', (tester) async {
      final userSettingsRepository = InMemoryUserSettingsRepository();
      final examDateSelection = ExamDateSelection(
        precision: ExamDatePrecision.exact,
        date: DateTime(2026, 6, 1),
      );

      await tester.pumpWidget(wrap(
        localStore: InMemoryBootstrapLocalStore(),
        userSettingsRepository: userSettingsRepository,
        examDateSelection: examDateSelection,
        themePreference: ThemePreference.dark,
        now: () => DateTime.utc(2026, 3, 1),
      ));
      await tester.tap(find.text('Just starting'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final UserProfile? saved =
          await userSettingsRepository.loadProfile('danb_rhs');
      expect(saved, isNotNull);
      expect(saved!.experienceLevel, ExperienceLevel.justStarting);
      expect(saved.examDatePrecision, ExamDatePrecision.exact);
      expect(saved.examDate, DateTime.utc(2026, 6, 1));
      expect(saved.themePreference, ThemePreference.dark);
      expect(saved.onboardingComplete, isTrue);
      expect(saved.dailyGoalQuestions, kDefaultDailyGoalQuestions);
      expect(saved.notificationsEnabled, isFalse);
      expect(saved.createdAt, DateTime.utc(2026, 3, 1));
      expect(saved.updatedAt, DateTime.utc(2026, 3, 1));
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets(
        'a null userSettingsRepository (default, matching every other '
        'test in this file) skips the save entirely — no crash, no '
        'behavior change from before PREP-663', (tester) async {
      await tester.pumpWidget(wrap(
        localStore: InMemoryBootstrapLocalStore(),
        examDateSelection: ExamDateSelection(
          precision: ExamDatePrecision.notScheduled,
        ),
      ));
      await tester.tap(find.text('Just starting'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets(
        'a saveProfile failure is best-effort: onboarding still completes '
        'and reaches MainShell normally, exactly like a null repository',
        (tester) async {
      final userSettingsRepository = _ThrowingSaveUserSettingsRepository();

      await tester.pumpWidget(wrap(
        localStore: InMemoryBootstrapLocalStore(),
        userSettingsRepository: userSettingsRepository,
        examDateSelection: ExamDateSelection(
          precision: ExamDatePrecision.notScheduled,
        ),
      ));
      await tester.tap(find.text('Just starting'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MainShell), findsOneWidget);
      expect(userSettingsRepository.saveAttempts, 1);
    });

    testWidgets(
        're-running onboarding (e.g. local storage was reset without the '
        'database also being cleared) keeps the existing profile\'s '
        'createdAt and daily goal, updating the answers onboarding does '
        'collect', (tester) async {
      final existing = UserProfile(
        examId: 'danb_rhs',
        experienceLevel: ExperienceLevel.justStarting,
        examDatePrecision: ExamDatePrecision.notScheduled,
        dailyGoalQuestions: 30,
        notificationsEnabled: true,
        themePreference: ThemePreference.light,
        onboardingComplete: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final userSettingsRepository =
          InMemoryUserSettingsRepository(seedProfile: existing);

      await tester.pumpWidget(wrap(
        localStore: InMemoryBootstrapLocalStore(),
        userSettingsRepository: userSettingsRepository,
        examDateSelection: ExamDateSelection(
          precision: ExamDatePrecision.exact,
          date: DateTime(2026, 7, 1),
        ),
        themePreference: ThemePreference.dark,
        now: () => DateTime.utc(2026, 4, 1),
      ));
      await tester.tap(find.text('Taking the exam again'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final UserProfile? saved =
          await userSettingsRepository.loadProfile('danb_rhs');
      expect(saved!.createdAt, DateTime.utc(2026, 1, 1),
          reason: 'the original creation time must survive re-onboarding');
      expect(saved.dailyGoalQuestions, 30,
          reason: 'onboarding does not collect a daily goal — the prior '
              'answer must survive re-onboarding, not reset to the default');
      expect(saved.experienceLevel, ExperienceLevel.retakingExam);
      expect(saved.examDate, DateTime.utc(2026, 7, 1));
      expect(saved.themePreference, ThemePreference.dark);
      expect(saved.updatedAt, DateTime.utc(2026, 4, 1));
    });

    testWidgets(
        'restart durability: a profile saved through a real, database-backed '
        'DriftUserSettingsRepository is readable back by a brand new '
        'repository instance over the same database — not merely held in '
        'the widget\'s own in-memory object', (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final userSettingsRepository = DriftUserSettingsRepository(database);

      await tester.pumpWidget(wrap(
        localStore: InMemoryBootstrapLocalStore(),
        userSettingsRepository: userSettingsRepository,
        examDateSelection: ExamDateSelection(
          precision: ExamDatePrecision.approximate,
          date: DateTime(2026, 8, 1),
        ),
        now: () => DateTime.utc(2026, 3, 15),
      ));
      await tester.tap(find.text('Studying already'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // A fresh repository instance over the *same* database — the way
      // the next app launch's AppBootstrapService would construct one —
      // proves this is durable, not an artifact of reusing one Dart
      // object across the save and the read.
      final reloaded = DriftUserSettingsRepository(database);
      final UserProfile? saved = await reloaded.loadProfile('danb_rhs');

      expect(saved, isNotNull);
      expect(saved!.experienceLevel, ExperienceLevel.studyingAlready);
      expect(saved.examDatePrecision, ExamDatePrecision.approximate);
      expect(saved.examDate, DateTime.utc(2026, 8, 1));
      expect(saved.onboardingComplete, isTrue);
    });
  });
}

/// [saveProfile] always fails; [loadProfile] always returns null (no
/// existing profile) — proves a persistence failure never blocks
/// onboarding completion.
class _ThrowingSaveUserSettingsRepository implements UserSettingsRepository {
  int saveAttempts = 0;

  @override
  Future<UserProfile?> loadProfile(String examId) async => null;

  @override
  Future<void> saveProfile(UserProfile profile) async {
    saveAttempts++;
    throw StateError('disk full');
  }
}
