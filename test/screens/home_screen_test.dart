import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/progress_repository.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

/// Always throws — proves HomeScreen falls back to its honest default
/// empty state on a repository failure rather than crashing or hanging.
class _ThrowingProgressRepository implements ProgressRepository {
  @override
  Future<PracticeSession?> inProgressPracticeSession(String examId) {
    throw StateError('progress repository unavailable');
  }

  @override
  Future<void> recordAnswerAttempt(AnswerAttempt attempt) =>
      throw UnimplementedError();
  @override
  Future<List<AnswerAttempt>> answerAttemptsForExam(String examId) =>
      throw UnimplementedError();
  @override
  Future<QuestionState> questionState(String examId, String questionId) =>
      throw UnimplementedError();
  @override
  Future<void> saveQuestionState(QuestionState state) =>
      throw UnimplementedError();
  @override
  Future<List<QuestionState>> questionStatesForExam(String examId) =>
      throw UnimplementedError();
  @override
  Future<void> savePracticeSession(PracticeSession session) =>
      throw UnimplementedError();
  @override
  Future<void> saveMockAttempt(MockAttempt attempt) =>
      throw UnimplementedError();
  @override
  Future<MockAttempt?> mockAttempt(String attemptId) =>
      throw UnimplementedError();
  @override
  Future<List<MockAttempt>> mockAttemptsForExam(String examId) =>
      throw UnimplementedError();
  @override
  Future<void> saveReadinessSnapshot(ReadinessSnapshot snapshot) =>
      throw UnimplementedError();
  @override
  Future<ReadinessSnapshot?> latestReadinessSnapshot(String examId) =>
      throw UnimplementedError();
  @override
  Future<List<ReadinessSnapshot>> readinessSnapshotsForExam(String examId) =>
      throw UnimplementedError();
}

/// Lets a test hold [inProgressPracticeSession] pending until it has
/// asserted the loading state, then resolve it under explicit control —
/// the real in-memory repository's `Future` (no real `await` inside)
/// completes on the next microtask, too fast for a single [WidgetTester
/// .pump] to reliably observe [ConnectionState.waiting] beforehand.
class _ControlledProgressRepository implements ProgressRepository {
  final Completer<PracticeSession?> _completer = Completer<PracticeSession?>();

  void complete(PracticeSession? session) => _completer.complete(session);

  @override
  Future<PracticeSession?> inProgressPracticeSession(String examId) =>
      _completer.future;

  @override
  Future<void> recordAnswerAttempt(AnswerAttempt attempt) =>
      throw UnimplementedError();
  @override
  Future<List<AnswerAttempt>> answerAttemptsForExam(String examId) =>
      throw UnimplementedError();
  @override
  Future<QuestionState> questionState(String examId, String questionId) =>
      throw UnimplementedError();
  @override
  Future<void> saveQuestionState(QuestionState state) =>
      throw UnimplementedError();
  @override
  Future<List<QuestionState>> questionStatesForExam(String examId) =>
      throw UnimplementedError();
  @override
  Future<void> savePracticeSession(PracticeSession session) =>
      throw UnimplementedError();
  @override
  Future<void> saveMockAttempt(MockAttempt attempt) =>
      throw UnimplementedError();
  @override
  Future<MockAttempt?> mockAttempt(String attemptId) =>
      throw UnimplementedError();
  @override
  Future<List<MockAttempt>> mockAttemptsForExam(String examId) =>
      throw UnimplementedError();
  @override
  Future<void> saveReadinessSnapshot(ReadinessSnapshot snapshot) =>
      throw UnimplementedError();
  @override
  Future<ReadinessSnapshot?> latestReadinessSnapshot(String examId) =>
      throw UnimplementedError();
  @override
  Future<List<ReadinessSnapshot>> readinessSnapshotsForExam(String examId) =>
      throw UnimplementedError();
}

Widget _wrap(Widget home) {
  final BootstrapSessionController controller = BootstrapSessionController(
    BootstrapReady(
      selectedExamId: DebugDemoEnvironment.demoExamId,
      contentPackage: DebugDemoEnvironment.demoContentPackage,
      profile: null,
      themePreference: ThemePreference.system,
      readinessSnapshot: null,
      entitlement: Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1)),
      onboardingComplete: true,
      examDateSelection: null,
      experienceLevel: null,
    ),
  );
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: BootstrapSessionScope(controller: controller, child: home),
    routes: {
      ExamOverviewScreen.route: (_) => const ExamOverviewScreen(),
    },
  );
}

void main() {
  group('no progress repository (production default)', () {
    testWidgets(
        'shows the honest "no study tasks yet" empty state immediately, '
        'with no loading flash', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      // A single pump (not pumpAndSettle): if this ever showed a loading
      // state first, it would still be visible right here.
      await tester.pump();

      expect(find.text('Build your confidence'), findsOneWidget);
      expect(find.text('Start Practicing'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Start Practicing navigates to ExamOverviewScreen',
        (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Practicing'));
      await tester.pumpAndSettle();

      expect(find.byType(ExamOverviewScreen), findsOneWidget);
    });
  });

  group('progress repository with a real in-progress session', () {
    testWidgets(
        'shows a loading state while the query is in flight, then the '
        'resolved session — never a flash of the wrong (empty) content',
        (tester) async {
      final repository = _ControlledProgressRepository();
      await tester
          .pumpWidget(_wrap(HomeScreen(progressRepository: repository)));

      // The query is still pending — a loading state, not a flash of the
      // wrong (empty) content.
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Build your confidence'), findsNothing);

      repository.complete(DebugDemoEnvironment.demoInProgressPracticeSession);
      await tester.pumpAndSettle();

      expect(find.text('Pick up where you left off'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Build your confidence'), findsNothing);
      expect(find.text('Start Practicing'), findsNothing);
    });

    testWidgets(
        'reproduces the audited defect: HomeScreen must reflect a real '
        'unfinished session as "Continue", not the generic empty state',
        (tester) async {
      await tester.pumpWidget(_wrap(
        HomeScreen(
            progressRepository: DebugDemoEnvironment.buildProgressRepository()),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Pick up where you left off'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Build your confidence'), findsNothing);
      expect(find.text('Start Practicing'), findsNothing);
    });

    testWidgets('Continue navigates to the same real ExamOverviewScreen',
        (tester) async {
      await tester.pumpWidget(_wrap(
        HomeScreen(
            progressRepository: DebugDemoEnvironment.buildProgressRepository()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(ExamOverviewScreen), findsOneWidget);
    });
  });

  group('progress repository present but no in-progress session', () {
    testWidgets('still shows the honest empty state, not a fabricated one',
        (tester) async {
      // A repository seeded with only a *completed* session (no
      // in-progress one) — every SeedX field left at its default empty
      // list except the practice-session one, so this stays independent
      // of DebugDemoEnvironment's in-progress fixture. Reusing the real
      // InMemoryProgressRepository, not a second fake implementation.
      final repository = DebugDemoEnvironment.buildProgressRepository();
      // Drain the seeded in-progress session so only the completed one
      // remains — proves the "no session" branch, not just "no
      // repository at all".
      await repository.savePracticeSession(
        DebugDemoEnvironment.demoInProgressPracticeSession
            .copyWith(status: SessionStatus.abandoned),
      );

      await tester
          .pumpWidget(_wrap(HomeScreen(progressRepository: repository)));
      await tester.pumpAndSettle();

      expect(find.text('Build your confidence'), findsOneWidget);
      expect(find.text('Start Practicing'), findsOneWidget);
    });
  });

  group('progress repository failure', () {
    testWidgets('falls back to the honest empty state, never crashes',
        (tester) async {
      await tester.pumpWidget(
        _wrap(HomeScreen(progressRepository: _ThrowingProgressRepository())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Build your confidence'), findsOneWidget);
      expect(find.text('Start Practicing'), findsOneWidget);
    });
  });
}
