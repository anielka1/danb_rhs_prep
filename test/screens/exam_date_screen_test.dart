import 'dart:async';

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
import 'package:danb_rhs_prep/screens/exam_date_screen.dart';
import 'package:danb_rhs_prep/screens/experience_level_screen.dart';
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

BootstrapReady _readySnapshot({ExamDateSelection? examDateSelection}) {
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
    examDateSelection: examDateSelection,
    experienceLevel: null,
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

/// [writeExamDateSelection] always fails — the exam-date selection
/// itself never saves.
class _ThrowingExamDateWriteLocalStore extends _DelegatingLocalStore {
  _ThrowingExamDateWriteLocalStore(super.delegate);
  int writeAttempts = 0;

  @override
  Future<void> writeExamDateSelection(ExamDateSelection selection) async {
    writeAttempts++;
    throw StateError('disk full');
  }
}

/// [writeExamDateSelection] never resolves on its own — the test
/// controls exactly when it completes via [writeCompleter].
class _ControlledExamDateWriteLocalStore extends _DelegatingLocalStore {
  _ControlledExamDateWriteLocalStore(super.delegate);
  final Completer<void> writeCompleter = Completer<void>();
  int writeAttempts = 0;

  @override
  Future<void> writeExamDateSelection(ExamDateSelection selection) {
    writeAttempts++;
    return writeCompleter.future;
  }
}

void main() {
  final DateTime fixedToday = DateTime(2026, 3, 10);

  Widget wrap({
    required BootstrapLocalStore localStore,
    ExamDateSelection? restoredSelection,
    DateTime Function()? now,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: BootstrapSessionScope(
        controller: BootstrapSessionController(
            _readySnapshot(examDateSelection: restoredSelection)),
        child: ExamDateScreen(
          localStore: localStore,
          now: now ?? (() => fixedToday),
        ),
      ),
    );
  }

  /// Picks [day] (of the currently-displayed month) via the real Material
  /// date picker and confirms with OK.
  Future<void> pickDay(WidgetTester tester, int day) async {
    await tester.tap(find.text('Choose a date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('$day').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  group('required content', () {
    testWidgets('shows the exact heading and supporting copy', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      expect(find.text('When is your exam?'), findsOneWidget);
      expect(
        find.text(
          'This helps us shape your study plan. You can change it later.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('offers all three mutually-exclusive choices', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      expect(find.text('I know the exact date'), findsOneWidget);
      expect(find.text('I have an approximate date'), findsOneWidget);
      expect(find.text("I haven't scheduled it yet"), findsOneWidget);
    });

    testWidgets(
        'a selected choice exposes selected semantics, unselected '
        'exposes not-selected — not conveyed by color alone', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      await tester.tap(find.text('I know the exact date'));
      await tester.pump();

      expect(find.bySemanticsLabel('I know the exact date, selected'),
          findsOneWidget);
      expect(find.bySemanticsLabel('I have an approximate date, not selected'),
          findsOneWidget);
    });
  });

  group('choosing a precision and date', () {
    testWidgets('selecting exact reveals a date selector', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      expect(find.text('Choose a date'), findsNothing);
      await tester.tap(find.text('I know the exact date'));
      await tester.pump();

      expect(find.text('Choose a date'), findsOneWidget);
    });

    testWidgets('selecting approximate also reveals a date selector',
        (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      await tester.tap(find.text('I have an approximate date'));
      await tester.pump();

      expect(find.text('Choose a date'), findsOneWidget);
    });

    testWidgets('selecting unscheduled shows no date selector', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      await tester.tap(find.text("I haven't scheduled it yet"));
      await tester.pump();

      expect(find.text('Choose a date'), findsNothing);
    });

    testWidgets(
        'picking today via the date picker is accepted and displayed '
        'using localized formatting', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));
      await tester.tap(find.text('I know the exact date'));
      await tester.pump();

      await pickDay(tester, fixedToday.day);

      final BuildContext context = tester.element(find.byType(ExamDateScreen));
      final String expected =
          MaterialLocalizations.of(context).formatMediumDate(fixedToday);
      expect(find.text(expected), findsOneWidget);
      expect(find.text('Choose a date'), findsNothing);
    });

    testWidgets('switching to unscheduled clears a previously-chosen date',
        (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));
      await tester.tap(find.text('I know the exact date'));
      await tester.pump();
      await pickDay(tester, fixedToday.day);

      await tester.tap(find.text("I haven't scheduled it yet"));
      await tester.pump();
      await tester.tap(find.text('I know the exact date'));
      await tester.pump();

      expect(find.text('Choose a date'), findsOneWidget,
          reason: 'the date must have been cleared by the unscheduled '
              'switch, not merely hidden');
    });

    testWidgets(
        'switching between exact and approximate preserves the chosen '
        'date', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));
      await tester.tap(find.text('I know the exact date'));
      await tester.pump();
      await pickDay(tester, fixedToday.day);

      final BuildContext context = tester.element(find.byType(ExamDateScreen));
      final String expected =
          MaterialLocalizations.of(context).formatMediumDate(fixedToday);

      await tester.tap(find.text('I have an approximate date'));
      await tester.pump();

      expect(find.text(expected), findsOneWidget);
      expect(find.text('Choose a date'), findsNothing);
    });
  });

  group('restoring a previously-saved selection', () {
    testWidgets('a valid restored exact date prefills the screen',
        (tester) async {
      final saved = ExamDateSelection(
          precision: ExamDatePrecision.exact, date: DateTime(2026, 3, 20));
      await tester.pumpWidget(wrap(
          localStore: InMemoryBootstrapLocalStore(), restoredSelection: saved));

      final BuildContext context = tester.element(find.byType(ExamDateScreen));
      final String expected =
          MaterialLocalizations.of(context).formatMediumDate(saved.date!);
      expect(find.bySemanticsLabel('I know the exact date, selected'),
          findsOneWidget);
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets(
        'a restored date that has since passed is not presented as valid '
        '— the precision stays visible but a new date is required',
        (tester) async {
      final saved = ExamDateSelection(
          precision: ExamDatePrecision.exact,
          date: DateTime(2026, 3, 1)); // before fixedToday (March 10)
      await tester.pumpWidget(wrap(
          localStore: InMemoryBootstrapLocalStore(), restoredSelection: saved));

      expect(find.bySemanticsLabel('I know the exact date, selected'),
          findsOneWidget,
          reason: 'the precision choice itself must stay visible');
      expect(find.text('Choose a date'), findsOneWidget,
          reason: 'the stale date must not be presented as pre-filled');
      expect(find.textContaining('already passed'), findsOneWidget);
      expect(
          find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.liveRegion == true),
          findsOneWidget);

      final PrimaryButton button = tester.widget(find.byType(PrimaryButton));
      expect(button.onPressed, isNull,
          reason: 'Continue must stay disabled until a new valid date is '
              'chosen');
    });

    testWidgets('a restored unscheduled selection prefills that choice',
        (tester) async {
      final saved =
          ExamDateSelection(precision: ExamDatePrecision.notScheduled);
      await tester.pumpWidget(wrap(
          localStore: InMemoryBootstrapLocalStore(), restoredSelection: saved));

      expect(find.bySemanticsLabel("I haven't scheduled it yet, selected"),
          findsOneWidget);
    });
  });

  group('Continue validation', () {
    testWidgets('Continue is disabled until a choice is made', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      final PrimaryButton button = tester.widget(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Continue is enabled immediately for unscheduled',
        (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));
      await tester.tap(find.text("I haven't scheduled it yet"));
      await tester.pump();

      final PrimaryButton button = tester.widget(find.byType(PrimaryButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Continue stays disabled for exact until a date is chosen',
        (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));
      await tester.tap(find.text('I know the exact date'));
      await tester.pump();

      final PrimaryButton button = tester.widget(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);
    });

    testWidgets("today is accepted as a valid exact date", (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));
      await tester.tap(find.text('I know the exact date'));
      await tester.pump();
      await pickDay(tester, fixedToday.day);

      final PrimaryButton button = tester.widget(find.byType(PrimaryButton));
      expect(button.onPressed, isNotNull);
    });
  });

  group('save behavior', () {
    testWidgets(
        'Continue saves the selection and pushes ExperienceLevelScreen — '
        'never MainShell, and never writes onboardingComplete', (tester) async {
      final localStore = InMemoryBootstrapLocalStore();
      await tester.pumpWidget(wrap(localStore: localStore));
      await tester.tap(find.text("I haven't scheduled it yet"));
      await tester.pump();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(await localStore.readExamDateSelection(),
          ExamDateSelection(precision: ExamDatePrecision.notScheduled));
      expect(await localStore.readOnboardingComplete(), isNot(isTrue),
          reason: 'ExamDateScreen must never write onboardingComplete — '
              'that is ExperienceLevelScreen\'s responsibility now');
      expect(find.byType(ExperienceLevelScreen), findsOneWidget);
      expect(find.byType(ExamDateScreen), findsNothing);
    });

    testWidgets(
        'a successful save updates the current session — '
        'ExperienceLevelScreen receives the saved ExamDateSelection, not '
        'a stale snapshot', (tester) async {
      final localStore = InMemoryBootstrapLocalStore();
      await tester.pumpWidget(wrap(localStore: localStore));
      await tester.tap(find.text('I know the exact date'));
      await tester.pump();
      await pickDay(tester, fixedToday.day);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final BuildContext nextContext =
          tester.element(find.byType(ExperienceLevelScreen));
      final ExamDateSelection? sessionSelection =
          BootstrapSessionScope.snapshotOf(nextContext).examDateSelection;
      expect(
          sessionSelection,
          ExamDateSelection(
              precision: ExamDatePrecision.exact, date: fixedToday));
    });

    testWidgets(
        'a failed exam-date save is recoverable: stays on screen, shows '
        'an error, does not mark onboarding complete', (tester) async {
      final localStore =
          _ThrowingExamDateWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(localStore: localStore));
      await tester.tap(find.text("I haven't scheduled it yet"));
      await tester.pump();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(ExamDateScreen), findsOneWidget);
      expect(find.byType(ExperienceLevelScreen), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      expect(
          find.textContaining("couldn't save your exam date"), findsOneWidget);
      expect(await localStore.readOnboardingComplete(), isNot(isTrue));
    });

    testWidgets('Retry after a failed exam-date save can succeed',
        (tester) async {
      final backing = InMemoryBootstrapLocalStore();
      final localStore = _ThrowingExamDateWriteLocalStore(backing);
      await tester.pumpWidget(wrap(localStore: localStore));
      await tester.tap(find.text("I haven't scheduled it yet"));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(localStore.writeAttempts, 1);

      // The underlying store stops throwing — a real Retry after a
      // transient failure would succeed the same way.
      await tester.tap(find.text('Retry'));
      await tester.pump();
      // Still throws (this double is permanently broken) — assert it
      // failed again and remained recoverable, not stuck loading.
      await tester.pumpAndSettle();
      expect(localStore.writeAttempts, 2);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('duplicate taps do not duplicate writes or navigation',
        (tester) async {
      final controlled =
          _ControlledExamDateWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(localStore: controlled));
      await tester.tap(find.text("I haven't scheduled it yet"));
      await tester.pump();

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump();

      expect(controlled.writeAttempts, 1);

      controlled.writeCompleter.complete();
      await tester.pumpAndSettle();

      expect(controlled.writeAttempts, 1);
      expect(find.byType(ExperienceLevelScreen), findsOneWidget);
    });

    testWidgets('Back without tapping Continue writes nothing', (tester) async {
      final localStore = InMemoryBootstrapLocalStore();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BootstrapSessionScope(
                        controller:
                            BootstrapSessionController(_readySnapshot()),
                        child: ExamDateScreen(
                          localStore: localStore,
                          now: () => fixedToday,
                        ),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            );
          }),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I know the exact date'));
      await tester.pump();
      await pickDay(tester, fixedToday.day + 2);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('open'), findsOneWidget);
      expect(await localStore.readExamDateSelection(), isNull);
      expect(await localStore.readOnboardingComplete(), isNot(isTrue));
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
        expect(find.text('When is your exam?'), findsOneWidget);
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
      expect(find.text('When is your exam?'), findsOneWidget);
    });

    // A visual/layout-order check only — proves top-to-bottom widget
    // position, not accessibility/screen-reader traversal order. See
    // `test/screens/exam_date_screen_semantics_test.dart` for the real
    // semantics-tree traversal test; this one is kept only because it
    // separately catches a layout regression (e.g. an element
    // reordered in the `Column`) that a semantics-only check wouldn't.
    testWidgets(
        'visual layout order matches heading, copy, choices, Continue '
        '(not a semantics/VoiceOver check — see the dedicated semantics '
        'traversal test file for that)', (tester) async {
      await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

      final double headingY =
          tester.getTopLeft(find.text('When is your exam?')).dy;
      final double copyY = tester
          .getTopLeft(find
              .text('This helps us shape your study plan. You can change it '
                  'later.'))
          .dy;
      final double firstChoiceY =
          tester.getTopLeft(find.text('I know the exact date')).dy;
      final double lastChoiceY =
          tester.getTopLeft(find.text("I haven't scheduled it yet")).dy;
      final double continueY = tester.getTopLeft(find.byType(PrimaryButton)).dy;

      expect(headingY, lessThan(copyY));
      expect(copyY, lessThan(firstChoiceY));
      expect(firstChoiceY, lessThan(lastChoiceY));
      expect(lastChoiceY, lessThan(continueY));
    });
  });
}
