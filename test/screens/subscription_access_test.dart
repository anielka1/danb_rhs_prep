import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_free_practice_store.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/main.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/repositories/subscription_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_content_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_user_settings_repository.dart';
import 'package:danb_rhs_prep/screens/subscription_screen.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/screens/answer_explanation_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_results_screen.dart';
import 'package:danb_rhs_prep/screens/saved_questions_screen.dart';
import 'package:danb_rhs_prep/subscription/premium_access.dart';
import '../study_plan/fixtures.dart';
import 'package:danb_rhs_prep/widgets/subscription_product_card.dart';
import 'package:danb_rhs_prep/widgets/primary_button.dart';

Future<void> tap(WidgetTester tester, String label) async {
  final f = find.text(label);
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> close(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Close subscription'));
  await tester.pumpAndSettle();
}

class ControlledSubscriptions implements SubscriptionRepository {
  Completer<Entitlement> read = Completer();
  final events = StreamController<Entitlement>.broadcast();
  @override
  Future<Entitlement> currentEntitlement() => read.future;
  @override
  Stream<Entitlement> entitlementChanges() => events.stream;
}

Entitlement premium({DateTime? expires}) => Entitlement(
    tier: EntitlementTier.premium,
    source: EntitlementSource.promotional,
    lastVerifiedAt: DateTime.utc(2026),
    expiresAt: expires);

class _UnreadableSavedSession extends InMemoryProgressRepository {
  @override
  Future<PracticeSession?> inProgressPracticeSession(String examId) async {
    throw const FormatException('old session record');
  }

  @override
  Future<List<MockAttempt>> mockAttemptsForExam(String examId) async {
    throw const FormatException('old mock history');
  }
}

void main() {
  for (final paid in [false, true]) {
    testWidgets('bundled mixed practice survives history errors: paid=$paid',
        (tester) async {
      final package = fixture(count: 80);
      final history = _UnreadableSavedSession();
      final old = PracticeSession(
        id: 'old-session',
        examId: package.exam.id,
        mode: PracticeMode.quickPractice,
        questionIds: [package.questions.first.id],
        status: SessionStatus.inProgress,
        startedAt: DateTime.utc(2026),
      );
      await history.savePracticeSession(old);
      final store = InMemoryBootstrapLocalStore();
      await store.writeOnboardingComplete(true);
      final subscriptions = ControlledSubscriptions();
      subscriptions.read.complete(
        paid ? premium() : Entitlement.free(lastVerifiedAt: DateTime.utc(2026)),
      );
      final trial = InMemoryFreePracticeStore();
      if (!paid) {
        await trial.registerSession('session-1');
        for (var i = 0; i < 4; i++) {
          final attempt = answer(
            package.questions[i],
            DateTime.utc(2026),
            id: 'trial-$i',
          );
          await trial.record(attempt, () async {});
        }
      }
      addTearDown(subscriptions.events.close);
      final settings = InMemoryUserSettingsRepository();
      await tester.pumpWidget(DanbRhsPrepApp(
        subscriptionRepository: subscriptions,
        localStore: store,
        freePracticeStore: trial,
        progressRepository: history,
        userSettingsRepository: settings,
        bootstrapService: AppBootstrapService(
          localStore: store,
          userSettingsRepository: settings,
          contentRepository:
              InMemoryContentRepository({package.exam.id: package}),
          defaultExamId: package.exam.id,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      await tap(tester, 'Practise questions');
      expect(find.byType(PracticeQuestionScreen), findsOneWidget);
      final controller = PracticeSessionScope.of(
        tester.element(find.byType(PracticeQuestionScreen)),
      );
      expect(controller.totalQuestions, paid ? 20 : 1);
      expect((await trial.read()).remaining, paid ? 5 : 1);
      expect(await history.practiceSessionsForExam(package.exam.id),
          contains(old));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Home waits for access without flashing a Premium lock',
      (tester) async {
    final package = fixture(count: 80);
    final store = InMemoryBootstrapLocalStore();
    await store.writeOnboardingComplete(true);
    final repo = ControlledSubscriptions();
    addTearDown(repo.events.close);
    final settings = InMemoryUserSettingsRepository();
    await tester.pumpWidget(DanbRhsPrepApp(
      subscriptionRepository: repo,
      localStore: store,
      freePracticeStore: InMemoryFreePracticeStore(),
      progressRepository: InMemoryProgressRepository(),
      userSettingsRepository: settings,
      bootstrapService: AppBootstrapService(
        localStore: store,
        userSettingsRepository: settings,
        contentRepository:
            InMemoryContentRepository({package.exam.id: package}),
        defaultExamId: package.exam.id,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Checking access...'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    await tester.tap(find.text('Practise questions'));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionScreen), findsNothing);
    expect(find.byType(ExamOverviewScreen), findsNothing);
    repo.read.complete(premium());
    await tester.pumpAndSettle();
    expect(find.text('Checking access...'), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    await tap(tester, 'Practice by topics');
    expect(find.byType(ExamOverviewScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('empty approved bank does not consume the free trial',
      (tester) async {
    final package = fixture(count: 0);
    final store = InMemoryBootstrapLocalStore();
    final settings = InMemoryUserSettingsRepository();
    final trial = InMemoryFreePracticeStore();
    await tester.pumpWidget(DanbRhsPrepApp(
      localStore: store,
      freePracticeStore: trial,
      progressRepository: InMemoryProgressRepository(),
      userSettingsRepository: settings,
      bootstrapService: AppBootstrapService(
        localStore: store,
        userSettingsRepository: settings,
        contentRepository:
            InMemoryContentRepository({package.exam.id: package}),
        defaultExamId: package.exam.id,
      ),
    ));
    await tester.pumpAndSettle();
    await tap(tester, 'Start Preparing');
    await tap(tester, "I haven't scheduled it yet");
    await tap(tester, 'Continue');
    await tap(tester, 'Practise questions');
    expect(
        find.text('No approved questions are available yet.'), findsOneWidget);
    expect((await trial.read()).remaining, 5);
    expect((await trial.read()).sessionIds, isEmpty);
    expect(find.byType(SubscriptionScreen), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final scheduled in [false, true]) {
    testWidgets(
        'first run date=$scheduled unconfigured offer, restart and every locked tile',
        (tester) async {
      final package = fixture(count: 80);
      final store = InMemoryBootstrapLocalStore();
      final history = InMemoryProgressRepository();
      final trial = InMemoryFreePracticeStore();
      final original = answer(package.questions.first, DateTime.utc(2026));
      await history.recordAnswerAttempt(original);
      final settings = InMemoryUserSettingsRepository();
      Widget app() => DanbRhsPrepApp(
          localStore: store,
          freePracticeStore: trial,
          progressRepository: history,
          userSettingsRepository: settings,
          bootstrapService: AppBootstrapService(
              localStore: store,
              userSettingsRepository: settings,
              contentRepository:
                  InMemoryContentRepository({package.exam.id: package}),
              defaultExamId: package.exam.id));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tap(tester, 'Start Preparing');
      if (scheduled) {
        await tap(tester, 'I know the exact date');
        await tap(tester, 'Choose a date');
        await tap(tester, 'OK');
      } else {
        await tap(tester, "I haven't scheduled it yet");
      }
      await tap(tester, 'Continue');
      expect(find.byType(SubscriptionScreen), findsNothing);
      expect(await store.readOnboardingComplete(), true);
      final savedDate = await store.readExamDateSelection();
      expect(savedDate, isNotNull);
      expect(find.text('Try 5 free questions'), findsOneWidget);
      await tap(tester, 'Practise questions');
      final semantics = tester.ensureSemantics();
      await tester.tap(find.bySemanticsLabel('Bookmark question'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Remove bookmark'), findsOneWidget);
      expect(find.byType(SubscriptionScreen), findsNothing);
      expect((await trial.read()).answeredCount, 0);
      semantics.dispose();
      // Leaving an opened question without answering must preserve all slots.
      expect((await trial.read()).answeredCount, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Try 5 free questions'), findsOneWidget);
      await tap(tester, 'Practise questions');
      await tap(tester, 'Resume session');
      for (var i = 0; i < 5; i++) {
        await tap(tester, 'Correct fixture answer');
        await tap(tester, 'Submit Answer');
        expect((await trial.read()).answeredCount, i + 1);
        expect(find.byType(AnswerExplanationScreen), findsOneWidget);
        if (i == 0) {
          final semantics = tester.ensureSemantics();
          expect(find.bySemanticsLabel('Remove bookmark'), findsOneWidget);
          await tester.tap(find.bySemanticsLabel('Remove bookmark'));
          await tester.pumpAndSettle();
          expect(find.bySemanticsLabel('Bookmark question'), findsOneWidget);
          expect(find.byType(SubscriptionScreen), findsNothing);
          semantics.dispose();
        }
        await tap(tester, i == 4 ? 'Finish' : 'Next Question');
        if (i == 2) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpWidget(app());
          await tester.pumpAndSettle();
          expect(find.byType(SubscriptionScreen), findsNothing);
          expect(find.text('Try 2 free questions'), findsOneWidget);
          await tap(tester, 'Practise questions');
          await tap(tester, 'Resume session');
        }
      }
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      expect((await trial.read()).completionPaywallShown, true);
      expect(find.byType(SubscriptionProductCard), findsNothing);
      expect(find.text('Subscriptions are not configured for this build.'),
          findsOneWidget);
      expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
          isNull);
      await tap(tester, 'Retry');
      await tap(tester, 'Restore purchases');
      expect(await store.readEntitlementSnapshot(), isNull);
      await close(tester);
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(5));
      expect(
          find.byWidgetPredicate((w) =>
              w is Semantics && w.properties.label == 'Premium required'),
          findsNWidgets(5));
      for (final label in [
        'Practise questions',
        'Practice by topics',
        'Saved questions',
        'Review mistakes',
        'Mock exam'
      ]) {
        await tap(tester, label);
        expect(find.byType(SubscriptionScreen), findsOneWidget);
        await close(tester);
        expect(find.byType(MainShell), findsOneWidget);
      }
      for (final route in [
        ExamOverviewScreen.route,
        PracticeQuestionScreen.route,
        AnswerExplanationScreen.route,
        PracticeSummaryScreen.route,
        MockExamScreen.route,
        MockExamResultsScreen.route
      ]) {
        Navigator.of(tester.element(find.byType(MainShell)),
                rootNavigator: true)
            .pushNamed(route);
        await tester.pumpAndSettle();
        expect(find.byType(SubscriptionScreen), findsOneWidget);
        await close(tester);
      }
      expect(await store.readExamDateSelection(), savedDate);
      expect(await history.answerAttemptsForExam(package.exam.id),
          contains(original));
      expect((await trial.read()).answeredCount, 5);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(SubscriptionScreen), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(5));
      expect(
          find.byWidgetPredicate((w) =>
              w is Semantics && w.properties.label == 'Premium required'),
          findsNWidgets(5));
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
      await tap(tester, 'Exam timeframe');
      await tap(tester, 'Later');
      await tap(tester, 'Save changes');
      expect(find.byType(SubscriptionScreen), findsNothing);
      expect(find.text('Settings'), findsWidgets);
      expect(await store.readOnboardingComplete(), true);
      expect(await history.answerAttemptsForExam(package.exam.id),
          contains(original));
      expect((await trial.read()).answeredCount, 5);
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      await tap(tester, 'Progress');
      expect(find.text('Your Progress'), findsOneWidget);
      expect(find.byType(SubscriptionScreen), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
      'all alternate screen entries fail closed; pending, failed, expired and valid repository state',
      (tester) async {
    var now = DateTime.utc(2026, 9, 13);
    final repo = ControlledSubscriptions();
    final access = PremiumAccessController(repo, now: () => now);
    addTearDown(access.dispose);
    addTearDown(repo.events.close);
    final package = fixture(count: 80);
    final history = InMemoryProgressRepository();
    final screens = <Widget>[
      ExamOverviewScreen(
          autoStart: true,
          contentPackage: package,
          progressRepository: history),
      const PracticeQuestionScreen(),
      const AnswerExplanationScreen(),
      const PracticeSummaryScreen(),
      const MockExamScreen(),
      const MockExamResultsScreen(),
      const SavedQuestionsScreen(),
    ];
    Widget wrap(Widget page) => MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (_, child) =>
            PremiumAccessScope(controller: access, child: child!),
        home: page);
    await tester.pumpWidget(wrap(screens.first));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.read.completeError(StateError('temporary'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    repo.read = Completer();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    repo.read.complete(Entitlement.free(lastVerifiedAt: now));
    await tester.pumpAndSettle();
    for (final screen in screens) {
      await tester.pumpWidget(wrap(screen));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(await history.practiceSessionsForExam(package.exam.id), isEmpty);
    repo.events.add(premium(expires: now.add(const Duration(seconds: 5))));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionScreen), findsNothing);
    now = now.add(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('valid existing Premium skips initial offer and preserves access',
      (tester) async {
    final package = fixture(count: 80);
    final store = InMemoryBootstrapLocalStore(entitlement: premium());
    final settings = InMemoryUserSettingsRepository();
    await tester.pumpWidget(DanbRhsPrepApp(
        localStore: store,
        progressRepository: InMemoryProgressRepository(),
        userSettingsRepository: settings,
        bootstrapService: AppBootstrapService(
            localStore: store,
            userSettingsRepository: settings,
            contentRepository:
                InMemoryContentRepository({package.exam.id: package}),
            defaultExamId: package.exam.id)));
    await tester.pumpAndSettle();
    for (final label in [
      'Start Preparing',
      "I haven't scheduled it yet",
      'Continue'
    ]) {
      await tap(tester, label);
    }
    expect(find.byType(SubscriptionScreen), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    await tap(tester, 'Practice by topics');
    expect(find.byType(ExamOverviewScreen), findsOneWidget);
    expect(find.byType(SubscriptionScreen), findsNothing);
    expect((await store.readEntitlementSnapshot())!.isPremium, true);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
