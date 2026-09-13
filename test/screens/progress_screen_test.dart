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
import 'package:danb_rhs_prep/features/questions/domain/question.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/progress_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/error_state.dart';

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

/// Always fails, like [_ThrowingProgressRepository], but counts how many
/// times [readinessSnapshotsForExam] — the first call `ProgressScreen`
/// makes per load — was actually invoked, to prove a guard against
/// concurrent duplicate loads.
class _CountingProgressRepository implements ProgressRepository {
  int readinessCalls = 0;

  @override
  Future<List<ReadinessSnapshot>> readinessSnapshotsForExam(
      String examId) async {
    readinessCalls++;
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

  group('chronologicalReadinessHistory', () {
    test('sorts oldest first regardless of input order', () {
      final ReadinessSnapshot oldest =
          DebugDemoEnvironment.demoReadinessSnapshotEarlier; // Dec 2025
      final ReadinessSnapshot newest =
          DebugDemoEnvironment.demoReadinessSnapshot; // Jan 2026

      expect(
        chronologicalReadinessHistory([newest, oldest]),
        [oldest, newest],
      );
      expect(
        chronologicalReadinessHistory([oldest, newest]),
        [oldest, newest],
      );
    });

    test('does not mutate the list it was given', () {
      final List<ReadinessSnapshot> input = [
        DebugDemoEnvironment.demoReadinessSnapshot,
        DebugDemoEnvironment.demoReadinessSnapshotEarlier,
      ];
      final List<ReadinessSnapshot> original = List.of(input);
      chronologicalReadinessHistory(input);
      expect(input, original);
    });
  });

  group('completedMockHistory', () {
    test('excludes an in-progress attempt and sorts newest first', () {
      final MockAttempt earlier = DebugDemoEnvironment.demoMockAttemptEarlier;
      final MockAttempt recent = DebugDemoEnvironment.demoMockAttempt;
      final MockAttempt inProgress = MockAttempt(
        id: 'in-progress',
        examId: DebugDemoEnvironment.demoExamId,
        questionIds: const ['demo-question-1', 'demo-question-2'],
        answers: const {},
        flaggedQuestionIds: const {},
        status: MockAttemptStatus.inProgress,
        startedAt: DateTime.utc(2026, 6, 1),
        durationMinutes: 10,
      );

      final List<MockAttempt> result =
          completedMockHistory([earlier, inProgress, recent]);

      expect(result, [recent, earlier]);
      expect(
          result.any((a) => a.status != MockAttemptStatus.completed), isFalse);
    });
  });

  group('aggregateDomainBreakdown', () {
    test('sums correct/seen per domain across multiple states', () {
      final List<Question> questions = DebugDemoEnvironment.demoQuestions;
      final List<QuestionState> states = [
        QuestionState(
          examId: DebugDemoEnvironment.demoExamId,
          questionId: questions[0].id,
          bookmarked: false,
          timesSeen: 2,
          timesCorrect: 1,
          timesIncorrect: 1,
          consecutiveCorrect: 0,
          lastAnsweredAt: DateTime.utc(2026, 1, 1),
        ),
        QuestionState(
          examId: DebugDemoEnvironment.demoExamId,
          questionId: questions[1].id,
          bookmarked: false,
          timesSeen: 3,
          timesCorrect: 3,
          timesIncorrect: 0,
          consecutiveCorrect: 3,
          lastAnsweredAt: DateTime.utc(2026, 1, 1),
        ),
      ];

      final result = aggregateDomainBreakdown(states, questions);

      // All demo questions share the same domain (demo_domain), so both
      // states' counts land in a single, summed row.
      expect(result, hasLength(1));
      expect(result.single.domainId, questions[0].domainId);
      expect(result.single.correct, 4);
      expect(result.single.seen, 5);
    });

    test(
        'skips a QuestionState whose question id is missing/retired, '
        'without throwing', () {
      final List<Question> questions = DebugDemoEnvironment.demoQuestions;
      final QuestionState retired = QuestionState(
        examId: DebugDemoEnvironment.demoExamId,
        questionId: 'retired-question-not-in-content',
        bookmarked: false,
        timesSeen: 4,
        timesCorrect: 4,
        timesIncorrect: 0,
        consecutiveCorrect: 4,
        lastAnsweredAt: DateTime.utc(2026, 1, 1),
      );

      expect(
        () => aggregateDomainBreakdown([retired], questions),
        returnsNormally,
      );
      expect(aggregateDomainBreakdown([retired], questions), isEmpty);
    });

    test('an unseen QuestionState contributes nothing', () {
      final List<Question> questions = DebugDemoEnvironment.demoQuestions;
      final QuestionState unseen = QuestionState.unseen(
        examId: DebugDemoEnvironment.demoExamId,
        questionId: questions[0].id,
      );

      expect(aggregateDomainBreakdown([unseen], questions), isEmpty);
    });
  });

  group('DomainStats.accuracy', () {
    test('is 0, not NaN or an exception, when seen is 0', () {
      const stats = DomainStats('any_domain', 0, 0);
      expect(stats.accuracy, 0);
      expect(stats.accuracy.isNaN, isFalse);
    });

    test('divides correct by seen otherwise', () {
      const stats = DomainStats('any_domain', 3, 4);
      expect(stats.accuracy, 0.75);
    });
  });

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

      expect(find.text('Daily activity'), findsOneWidget);
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
      expect(find.text('Daily activity'), findsOneWidget);
      expect(find.text('55% · Starting'), findsNothing);
      expect(find.text('72% · Getting close'), findsNothing);
      expect(find.text('Progress by subject'), findsOneWidget);
      expect(find.textContaining('correct ·'), findsWidgets);
      expect(find.text('MOCK EXAM HISTORY'), findsOneWidget);
      expect(find.textContaining('1/2 ·'), findsOneWidget);
      expect(find.textContaining('2/2 ·'), findsOneWidget);
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
      expect(find.text('No answers recorded yet.'), findsOneWidget);
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

    testWidgets(
        'rapid repeated retries before the first settles start only one '
        'load', (tester) async {
      final repository = _CountingProgressRepository();
      await tester.pumpWidget(wrap(ProgressScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: repository,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Could not load your progress'), findsOneWidget);
      expect(repository.readinessCalls, 1);

      // Two synchronous, back-to-back invocations of the same retry
      // callback with no pump in between — simulating a user tapping
      // "Try Again" twice before the first attempt has had any chance to
      // settle or even rebuild.
      final ErrorState errorState =
          tester.widget<ErrorState>(find.byType(ErrorState));
      errorState.onRetry!();
      errorState.onRetry!();
      await tester.pumpAndSettle();

      expect(repository.readinessCalls, 2,
          reason: 'the second, overlapping retry call must be a no-op, '
              'not a second concurrent load');
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

      await tester.ensureVisible(find.text('Practice More'));
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
      Future.value(const []);
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
