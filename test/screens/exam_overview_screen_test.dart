import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/progress_repository.dart';
import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/error_state.dart';

/// A [ProgressRepository] whose [answerAttemptsForExam] throws exactly
/// once (then behaves normally), for exercising a free-tier limit check
/// that fails to read history — and its retry succeeding once the
/// underlying read works again.
class _FlakyHistoryProgressRepository implements ProgressRepository {
  _FlakyHistoryProgressRepository(this._delegate, {this.failNextRead = false});

  final ProgressRepository _delegate;
  bool failNextRead;

  @override
  Future<List<AnswerAttempt>> answerAttemptsForExam(String examId) async {
    if (failNextRead) {
      failNextRead = false;
      throw StateError('simulated local database read failure');
    }
    return _delegate.answerAttemptsForExam(examId);
  }

  @override
  Future<void> recordAnswerAttempt(AnswerAttempt attempt) =>
      _delegate.recordAnswerAttempt(attempt);

  @override
  Future<QuestionState> questionState(String examId, String questionId) =>
      _delegate.questionState(examId, questionId);

  @override
  Future<void> saveQuestionState(QuestionState state) =>
      _delegate.saveQuestionState(state);

  @override
  Future<List<QuestionState>> questionStatesForExam(String examId) =>
      _delegate.questionStatesForExam(examId);

  @override
  Future<void> savePracticeSession(PracticeSession session) =>
      _delegate.savePracticeSession(session);

  @override
  Future<PracticeSession?> inProgressPracticeSession(String examId) =>
      _delegate.inProgressPracticeSession(examId);

  @override
  Future<void> saveMockAttempt(MockAttempt attempt) =>
      _delegate.saveMockAttempt(attempt);

  @override
  Future<MockAttempt?> mockAttempt(String attemptId) =>
      _delegate.mockAttempt(attemptId);

  @override
  Future<List<MockAttempt>> mockAttemptsForExam(String examId) =>
      _delegate.mockAttemptsForExam(examId);

  @override
  Future<void> saveReadinessSnapshot(ReadinessSnapshot snapshot) =>
      _delegate.saveReadinessSnapshot(snapshot);

  @override
  Future<ReadinessSnapshot?> latestReadinessSnapshot(String examId) =>
      _delegate.latestReadinessSnapshot(examId);

  @override
  Future<List<ReadinessSnapshot>> readinessSnapshotsForExam(String examId) =>
      _delegate.readinessSnapshotsForExam(examId);
}

AnswerAttempt _practiceAttemptToday(String id, DateTime answeredAt) {
  return AnswerAttempt(
    id: id,
    examId: DebugDemoEnvironment.demoExamId,
    questionId: DebugDemoEnvironment.demoQuestions.first.id,
    domainId: 'demo_domain',
    topicId: 'demo_topic',
    difficulty: 1,
    sessionId: 'seed-session',
    sessionType: AttemptSessionType.practice,
    selectedAnswerId: 'a',
    isCorrect: true,
    answeredAt: answeredAt,
  );
}

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.lightTheme, home: child);

  group('no content available', () {
    testWidgets('"Start Practice Exam" is disabled with a clear reason',
        (tester) async {
      await tester.pumpWidget(wrap(const ExamOverviewScreen()));

      final ElevatedButton button = tester.widget(find.ancestor(
        of: find.text('Start Practice Exam'),
        matching: find.byType(ElevatedButton),
      ));
      expect(button.onPressed, isNull);
      expect(find.textContaining("aren't available"), findsOneWidget);
    });
  });

  group('reproduces the audited defect', () {
    testWidgets(
        'starting a session uses the real content package, not the fake '
        '100-question/5-topic blueprint', (tester) async {
      await tester.pumpWidget(wrap(ExamOverviewScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
      )));

      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeQuestionScreen), findsOneWidget);
      final PracticeSessionController controller = PracticeSessionScope.of(
          tester.element(find.byType(PracticeQuestionScreen)));
      expect(
          controller.totalQuestions, DebugDemoEnvironment.demoQuestions.length);
      expect(controller.session.examId, DebugDemoEnvironment.demoExamId);
      expect(
        controller.questions.map((q) => q.id).toList(),
        DebugDemoEnvironment.demoQuestions.map((q) => q.id).toList(),
      );
      expect(
        controller.session.contentVersion,
        DebugDemoEnvironment.demoContentPackage.contentVersion,
        reason: 'a newly-created session (PREP-664) must record which '
            'content version its questions were drawn from',
      );
    });
  });

  group('no approved questions (PREP-667)', () {
    testWidgets(
        "today's real bundled DANB RHS content is entirely draft — "
        'tapping Start Practice Exam shows an honest unavailable reason '
        'instead of silently starting a session with unapproved '
        'questions', (tester) async {
      final ContentPackage package = const ExamContentCodec().decode(
          File('assets/content/danb_rhs/content.json').readAsStringSync());
      expect(package.approvedQuestions, isEmpty,
          reason: 'this test specifically exercises the current, '
              'accepted all-draft state — see '
              'docs/PROTOTYPE_CONTENT_AUDIT.md; once real content is '
              'approved, this assertion (and this test) will need '
              'updating right alongside it');

      await tester
          .pumpWidget(wrap(ExamOverviewScreen(contentPackage: package)));

      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeQuestionScreen), findsNothing);
      expect(find.textContaining('no eligible questions'), findsOneWidget);
      final ElevatedButton button = tester.widget(find.ancestor(
        of: find.text('Start Practice Exam'),
        matching: find.byType(ElevatedButton),
      ));
      expect(button.onPressed, isNotNull,
          reason: 'the button itself stays enabled — a retry with '
              'different content should be possible without navigating '
              'away and back');
    });
  });

  group('with an existing in-progress session', () {
    testWidgets('resumes it instead of starting a second one', (tester) async {
      final repository = DebugDemoEnvironment.buildProgressRepository();
      await tester.pumpWidget(wrap(ExamOverviewScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: repository,
      )));

      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();

      final PracticeSessionController controller = PracticeSessionScope.of(
          tester.element(find.byType(PracticeQuestionScreen)));
      expect(controller.session.id,
          DebugDemoEnvironment.demoInProgressPracticeSession.id);

      final PracticeSession? stillOnlyOneInProgress = await repository
          .inProgressPracticeSession(DebugDemoEnvironment.demoExamId);
      expect(stillOnlyOneInProgress?.id,
          DebugDemoEnvironment.demoInProgressPracticeSession.id);
    });
  });

  group('free-tier daily practice limit (PREP-667 correction)', () {
    // DebugDemoEnvironment.demoContentPackage.exam.freeTier
    //     .dailyPracticeQuestions == 10; demoQuestions has exactly 5
    // questions (all eligible in demo mode), so a maxCount at or above 5
    // is indistinguishable from "no cap" in these tests — every scenario
    // below deliberately keeps maxCount below 5 (or removes the cap
    // entirely for premium) so the resulting question count is real
    // evidence of which branch actually ran.
    final DateTime fixedNow = DateTime.utc(2026, 3, 5, 12);
    DateTime nowOverride() => fixedNow;

    test('sanity: the demo free tier daily limit is 10', () {
      expect(
        DebugDemoEnvironment
            .demoContentPackage.exam.freeTier.dailyPracticeQuestions,
        10,
      );
    });

    testWidgets(
        'a free user who has partially used today\'s limit gets only the '
        'remaining question count, not the full requested count',
        (tester) async {
      final repository = InMemoryProgressRepository(
        seedAnswerAttempts: List.generate(
          7,
          (i) => _practiceAttemptToday('seed-$i', fixedNow),
        ),
      );

      await tester.pumpWidget(wrap(ExamOverviewScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: repository,
        entitlement: Entitlement.free(lastVerifiedAt: fixedNow),
        now: nowOverride,
      )));

      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeQuestionScreen), findsOneWidget);
      final PracticeSessionController controller = PracticeSessionScope.of(
          tester.element(find.byType(PracticeQuestionScreen)));
      expect(controller.totalQuestions, 3,
          reason: '10 daily limit - 7 already answered today = 3 '
              'remaining, well below the 5-question demo pool, so this '
              'can only be the free-tier cap taking effect');
    });

    testWidgets(
        'a free user who has used up today\'s limit does not start a '
        'session at all', (tester) async {
      final repository = InMemoryProgressRepository(
        seedAnswerAttempts: List.generate(
          10,
          (i) => _practiceAttemptToday('seed-$i', fixedNow),
        ),
      );

      await tester.pumpWidget(wrap(ExamOverviewScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: repository,
        entitlement: Entitlement.free(lastVerifiedAt: fixedNow),
        now: nowOverride,
      )));

      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeQuestionScreen), findsNothing);
      expect(find.textContaining('limit'), findsOneWidget);
    });

    testWidgets(
        'an active premium entitlement has no daily limit, even with '
        'many attempts already recorded today', (tester) async {
      final repository = InMemoryProgressRepository(
        seedAnswerAttempts: List.generate(
          20,
          (i) => _practiceAttemptToday('seed-$i', fixedNow),
        ),
      );
      final entitlement = Entitlement(
        tier: EntitlementTier.premium,
        source: EntitlementSource.purchase,
        lastVerifiedAt: fixedNow,
      );

      await tester.pumpWidget(wrap(ExamOverviewScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: repository,
        entitlement: entitlement,
        now: nowOverride,
      )));

      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeQuestionScreen), findsOneWidget);
      final PracticeSessionController controller = PracticeSessionScope.of(
          tester.element(find.byType(PracticeQuestionScreen)));
      expect(controller.totalQuestions, 5,
          reason: 'the full 5-question demo pool, uncapped — 20 recorded '
              'attempts today would have driven a free user\'s remaining '
              'allowance to 0, so this proves premium truly bypasses the '
              'check rather than merely getting a generous cap');
    });

    testWidgets(
        "a free user whose attempt history can't be read does not get an "
        'unlimited session — a real, distinct error state is shown '
        'instead, and its Retry actually re-attempts the check',
        (tester) async {
      final flaky = _FlakyHistoryProgressRepository(
        InMemoryProgressRepository(),
        failNextRead: true,
      );

      await tester.pumpWidget(wrap(ExamOverviewScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: flaky,
        entitlement: Entitlement.free(lastVerifiedAt: fixedNow),
        now: nowOverride,
      )));

      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeQuestionScreen), findsNothing,
          reason: "an unreadable history must never be treated as "
              "'no limit' for a free user");
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text("Can't check your practice limit"), findsOneWidget);

      // The underlying read now succeeds (failNextRead was consumed by
      // the failed attempt above) — tapping the ErrorState's own retry
      // re-runs the whole flow, including the limit check, for real.
      await tester.ensureVisible(find.text('Try Again'));
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeQuestionScreen), findsOneWidget);
      expect(find.byType(ErrorState), findsNothing);
    });
  });
}
