import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/repositories/progress_repository.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/progress_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

class _ThrowingProgressRepository implements ProgressRepository {
  @override
  Future<List<ReadinessSnapshot>> readinessSnapshotsForExam(String examId) {
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
  Future<PracticeSession?> inProgressPracticeSession(String examId) =>
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
}

/// Wraps a real, demo-backed repository but holds
/// [readinessSnapshotsForExam] pending until [complete] is called — the
/// real in-memory repository's `Future`s (no real `await` inside) complete
/// on the next microtask, too fast for a single [WidgetTester.pump] to
/// reliably observe [ConnectionState.waiting] beforehand.
class _ControlledProgressRepository implements ProgressRepository {
  _ControlledProgressRepository()
      : _inner = DebugDemoEnvironment.buildProgressRepository();
  final ProgressRepository _inner;
  final Completer<void> _gate = Completer<void>();

  void complete() => _gate.complete();

  @override
  Future<List<ReadinessSnapshot>> readinessSnapshotsForExam(
      String examId) async {
    await _gate.future;
    return _inner.readinessSnapshotsForExam(examId);
  }

  @override
  Future<List<QuestionState>> questionStatesForExam(String examId) =>
      _inner.questionStatesForExam(examId);
  @override
  Future<List<MockAttempt>> mockAttemptsForExam(String examId) =>
      _inner.mockAttemptsForExam(examId);
  @override
  Future<void> recordAnswerAttempt(AnswerAttempt attempt) =>
      _inner.recordAnswerAttempt(attempt);
  @override
  Future<List<AnswerAttempt>> answerAttemptsForExam(String examId) =>
      _inner.answerAttemptsForExam(examId);
  @override
  Future<QuestionState> questionState(String examId, String questionId) =>
      _inner.questionState(examId, questionId);
  @override
  Future<void> saveQuestionState(QuestionState state) =>
      _inner.saveQuestionState(state);
  @override
  Future<void> savePracticeSession(PracticeSession session) =>
      _inner.savePracticeSession(session);
  @override
  Future<PracticeSession?> inProgressPracticeSession(String examId) =>
      _inner.inProgressPracticeSession(examId);
  @override
  Future<void> saveMockAttempt(MockAttempt attempt) =>
      _inner.saveMockAttempt(attempt);
  @override
  Future<MockAttempt?> mockAttempt(String attemptId) =>
      _inner.mockAttempt(attemptId);
  @override
  Future<void> saveReadinessSnapshot(ReadinessSnapshot snapshot) =>
      _inner.saveReadinessSnapshot(snapshot);
  @override
  Future<ReadinessSnapshot?> latestReadinessSnapshot(String examId) =>
      _inner.latestReadinessSnapshot(examId);
}

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.lightTheme, home: child);

  group('no repository or content (production default)', () {
    testWidgets('shows the honest "no progress yet" empty state',
        (tester) async {
      await tester.pumpWidget(wrap(const ProgressScreen()));
      await tester.pump();

      expect(find.text('No progress yet'), findsOneWidget);
      expect(find.text('Start Practicing'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('loading', () {
    testWidgets('shows a loading state while the query is in flight',
        (tester) async {
      final repository = _ControlledProgressRepository();
      await tester.pumpWidget(wrap(ProgressScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: repository,
      )));

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No progress yet'), findsNothing);

      repository.complete();
      await tester.pumpAndSettle();

      expect(find.text('READINESS TREND'), findsOneWidget);
    });
  });

  group('reproduces the audited defect', () {
    testWidgets(
        'trend, domain breakdown and mock history reflect the real '
        'repository, not a hardcoded/absent display', (tester) async {
      await tester.pumpWidget(wrap(ProgressScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: DebugDemoEnvironment.buildProgressRepository(),
      )));

      await tester.pumpAndSettle();

      // Before the fix this screen showed a fixed empty state
      // unconditionally, regardless of any real repository content — none
      // of this real, seeded demo data could ever have appeared.
      expect(find.text('READINESS TREND'), findsOneWidget);
      expect(find.text('55% · Starting'), findsOneWidget);
      expect(find.text('72% · Getting close'), findsOneWidget);
      expect(find.text('DOMAIN BREAKDOWN'), findsOneWidget);
      expect(find.text('2/2 correct'), findsOneWidget);
      expect(find.text('MOCK EXAM HISTORY'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('No progress yet'), findsNothing);
    });
  });

  group('repository present but genuinely empty', () {
    testWidgets('still shows the honest empty state, not a fabricated one',
        (tester) async {
      final repository = DebugDemoEnvironment.buildProgressRepository();
      await tester.pumpWidget(wrap(ProgressScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: EmptyOverrideRepository(repository),
      )));

      await tester.pumpAndSettle();
      expect(find.text('No progress yet'), findsOneWidget);
    });
  });

  group('repository failure', () {
    testWidgets('shows an error state with a working retry', (tester) async {
      await tester.pumpWidget(wrap(ProgressScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: _ThrowingProgressRepository(),
      )));

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Could not load your progress'), findsOneWidget);

      // Retrying against the same always-failing repository still fails
      // honestly rather than crashing or silently succeeding.
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Could not load your progress'), findsOneWidget);
    });
  });

  group('Practice More / Start Practicing', () {
    testWidgets('navigates to a real ExamOverviewScreen with real content',
        (tester) async {
      await tester.pumpWidget(wrap(ProgressScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: DebugDemoEnvironment.buildProgressRepository(),
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice More'));
      await tester.pumpAndSettle();

      expect(find.byType(ExamOverviewScreen), findsOneWidget);
      expect(find.text('Start Practice Exam'), findsOneWidget);
    });
  });
}

/// Wraps a real [ProgressRepository] but always reports empty history/
/// states/attempts — proves the "genuinely nothing yet" branch is reached
/// through a real (if empty) repository response, not just the "no
/// repository at all" branch already covered above.
class EmptyOverrideRepository implements ProgressRepository {
  EmptyOverrideRepository(this._inner);
  final ProgressRepository _inner;

  @override
  Future<List<ReadinessSnapshot>> readinessSnapshotsForExam(String examId) =>
      Future.value(const []);
  @override
  Future<List<QuestionState>> questionStatesForExam(String examId) =>
      Future.value(const []);
  @override
  Future<List<MockAttempt>> mockAttemptsForExam(String examId) =>
      Future.value(const []);

  @override
  Future<void> recordAnswerAttempt(AnswerAttempt attempt) =>
      _inner.recordAnswerAttempt(attempt);
  @override
  Future<List<AnswerAttempt>> answerAttemptsForExam(String examId) =>
      _inner.answerAttemptsForExam(examId);
  @override
  Future<QuestionState> questionState(String examId, String questionId) =>
      _inner.questionState(examId, questionId);
  @override
  Future<void> saveQuestionState(QuestionState state) =>
      _inner.saveQuestionState(state);
  @override
  Future<void> savePracticeSession(PracticeSession session) =>
      _inner.savePracticeSession(session);
  @override
  Future<PracticeSession?> inProgressPracticeSession(String examId) =>
      _inner.inProgressPracticeSession(examId);
  @override
  Future<void> saveMockAttempt(MockAttempt attempt) =>
      _inner.saveMockAttempt(attempt);
  @override
  Future<MockAttempt?> mockAttempt(String attemptId) =>
      _inner.mockAttempt(attemptId);
  @override
  Future<void> saveReadinessSnapshot(ReadinessSnapshot snapshot) =>
      _inner.saveReadinessSnapshot(snapshot);
  @override
  Future<ReadinessSnapshot?> latestReadinessSnapshot(String examId) =>
      _inner.latestReadinessSnapshot(examId);
}
