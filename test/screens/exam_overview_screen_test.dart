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
import 'package:danb_rhs_prep/features/questions/domain/question.dart';
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
        unorderedEquals(DebugDemoEnvironment.demoQuestions.map((q) => q.id)),
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

  group('a freshly-started session', () {
    testWidgets(
        "is stamped with this screen's injected clock, not the real "
        'device clock (PREP-457)', (tester) async {
      final DateTime fixedNow = DateTime.utc(2026, 1, 1, 9);

      await tester.pumpWidget(wrap(ExamOverviewScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        now: () => fixedNow,
      )));

      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();

      final PracticeSessionController controller = PracticeSessionScope.of(
          tester.element(find.byType(PracticeQuestionScreen)));
      expect(controller.session.startedAt, fixedNow,
          reason: 'a session created here must be stamped with the '
              'injected clock so its own elapsed timer stays consistent '
              'with it for the rest of this session, exactly like a '
              'resumed session (see the sibling test above)');
      expect(controller.elapsed, Duration.zero,
          reason: 'no real time has passed between the injected startedAt '
              'and this same injected now');
    });
  });

  group('real exam stats and topic coverage (PREP-460)', () {
    ContentPackage realPackage() => const ExamContentCodec().decode(
        File('assets/content/danb_rhs/content.json').readAsStringSync());

    Question approved(Question q) => Question(
          id: q.id,
          examId: q.examId,
          domainId: q.domainId,
          topicId: q.topicId,
          questionText: q.questionText,
          answers: q.answers,
          correctAnswerId: q.correctAnswerId,
          explanation: q.explanation,
          references: q.references,
          difficulty: q.difficulty,
          status: QuestionStatus.approved,
          version: q.version,
          updatedAt: q.updatedAt,
          sourceVersion: q.sourceVersion,
          tags: q.tags,
        );

    ContentPackage withApprovedQuestions(
      ContentPackage package,
      List<Question> questions,
    ) =>
        ContentPackage(
          exam: package.exam,
          contentVersion: package.contentVersion,
          sourceVersion: package.sourceVersion,
          generatedAt: package.generatedAt,
          questions: questions,
        );

    testWidgets(
        'shows the real exam duration/question count from ExamConfig, '
        'never the old hardcoded 1.5 Hours / 100 Questions / Intermediate',
        (tester) async {
      final ContentPackage package = realPackage();
      expect(package.exam.mockExam.durationMinutes, 60,
          reason: 'sanity check against the real, current content.json');
      expect(package.exam.mockExam.questionCount, 75,
          reason: 'sanity check against the real, current content.json');

      await tester
          .pumpWidget(wrap(ExamOverviewScreen(contentPackage: package)));

      expect(find.text('5 questions'), findsOneWidget);
      expect(find.text('10 questions'), findsOneWidget);
      expect(find.text('20 questions'), findsOneWidget);
      expect(find.textContaining('100 Questions'), findsNothing);
      expect(find.textContaining('1.5 Hours'), findsNothing);
      expect(find.textContaining('Intermediate'), findsNothing,
          reason: 'no difficulty-label field exists anywhere in '
              'ExamConfig — this was always a fabricated value with no '
              'backing data, not merely a stale one');
    });

    testWidgets(
        "shows the real exam's domain names under Topics Covered, never "
        'the old invented 5-topic list', (tester) async {
      final ContentPackage base = realPackage();
      // At least one approved question per domain, so the domain list
      // renders instead of the zero-approved empty state (covered by
      // its own test below) — this test is specifically about the
      // domain *names*, not the empty-bank behavior.
      final ContentPackage package =
          withApprovedQuestions(base, base.questions.map(approved).toList());

      await tester
          .pumpWidget(wrap(ExamOverviewScreen(contentPackage: package)));

      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      for (final domain in package.exam.domains) {
        expect(find.text(domain.name), findsWidgets,
            reason: 'every configured domain should be listed');
      }
      expect(find.text('Radiation Physics & Characteristics'), findsNothing);
      expect(find.text('Radiation Biology & Safety'), findsNothing);
      expect(find.text('Radiation Protection Standards'), findsNothing);
      expect(find.text('Equipment Operation & Imaging'), findsNothing);
      expect(find.text('Patient Management & Procedures'), findsNothing);
    });

    testWidgets(
        'shows an honest empty state under Topics Covered when the exam '
        'has zero approved questions, not zero-count rows for invented '
        'topics', (tester) async {
      final ContentPackage package = realPackage();
      expect(package.approvedQuestions, isEmpty,
          reason: "today's real bundled content is entirely draft — see "
              'docs/PROTOTYPE_CONTENT_AUDIT.md');

      await tester
          .pumpWidget(wrap(ExamOverviewScreen(contentPackage: package)));

      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();
      expect(find.textContaining('no eligible questions'), findsOneWidget);
      for (final domain in package.exam.domains) {
        expect(find.text(domain.name), findsNothing,
            reason: 'an empty bank should not render a domain list with '
                'zero-count rows');
      }
    });

    testWidgets(
        'shows a real per-domain approved-question count once questions '
        'are actually approved', (tester) async {
      final ContentPackage package = realPackage();
      final Question firstQuestion = package.questions.first;
      final ContentPackage packageWithOneApproved = withApprovedQuestions(
        package,
        [
          for (final q in package.questions)
            if (q.id == firstQuestion.id) approved(q) else q,
        ],
      );
      final String approvedDomainName = package.exam.domains
          .firstWhere((d) => d.id == firstQuestion.domainId)
          .name;

      await tester.pumpWidget(
          wrap(ExamOverviewScreen(contentPackage: packageWithOneApproved)));

      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text(approvedDomainName), findsWidgets);
      await tester.tap(find.text(approvedDomainName).last);
      await tester.pumpAndSettle();
      expect(find.textContaining('No approved questions'), findsNothing);
      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();
      final controller = PracticeSessionScope.of(
          tester.element(find.byType(PracticeQuestionScreen)));
      expect(controller.totalQuestions, 1);
      expect(controller.currentQuestion.domainId, firstQuestion.domainId);
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

    testWidgets(
        "a resumed session's elapsed timer is measured against this "
        'screen\'s injected clock, not the real device clock (PREP-457)',
        (tester) async {
      // demoInProgressPracticeSession.startedAt is a fixed fictional date
      // (2026-01-01 13:00 UTC) — exactly the kind of fixture the demo
      // entrypoint's own fixed `now` (also 2026-01-01) is meant to agree
      // with. Before this fix, `_startOrResumePractice` never passed its
      // `now` through to `PracticeSessionController.resume`, so `elapsed`
      // was silently measured against the real device clock instead —
      // many months of real elapsed time for this fixture, immediately
      // clamped to `_formatElapsed`'s display ceiling and making the
      // on-screen timer look permanently frozen there.
      final repository = DebugDemoEnvironment.buildProgressRepository();
      final DateTime fixedNow = DateTime.utc(2026, 1, 1, 14, 30);

      await tester.pumpWidget(wrap(ExamOverviewScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: repository,
        now: () => fixedNow,
      )));

      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();

      final PracticeSessionController controller = PracticeSessionScope.of(
          tester.element(find.byType(PracticeQuestionScreen)));
      expect(
        controller.elapsed,
        fixedNow.difference(
            DebugDemoEnvironment.demoInProgressPracticeSession.startedAt),
        reason: 'must equal exactly the injected now minus the session\'s '
            'real startedAt — any dependency on the real device clock '
            'would make this assertion flaky at best, wildly wrong (and '
            'silently clamped) at worst',
      );
    });

    testWidgets(
        "the real HomeScreen -> ExamOverviewScreen wiring (no injected "
        "now on this screen) still shows a small, sensible elapsed time "
        'for the seeded demo in-progress session, given the freshened '
        'repository main_demo.dart actually builds (PREP-457)', (tester) async {
      // No `now:` passed to ExamOverviewScreen here — this is exactly how
      // HomeScreen._openExamOverview constructs it in the real app, and
      // exactly why the sibling test above (which does inject `now`)
      // isn't, by itself, evidence this works end to end: nothing in the
      // real navigation path ever injects a clock into this screen.
      // What actually keeps the on-screen timer sensible in that real
      // path is main_demo.dart building its ProgressRepository with
      // buildProgressRepository(now: DateTime.now) — freshening the
      // seeded session's startedAt to a few minutes ago in real time,
      // instead of its own fixed 2026-01-01 literal.
      final repository =
          DebugDemoEnvironment.buildProgressRepository(now: DateTime.now);

      await tester.pumpWidget(wrap(ExamOverviewScreen(
        contentPackage: DebugDemoEnvironment.demoContentPackage,
        progressRepository: repository,
      )));

      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();

      final PracticeSessionController controller = PracticeSessionScope.of(
          tester.element(find.byType(PracticeQuestionScreen)));
      expect(controller.elapsed, lessThan(const Duration(minutes: 15)),
          reason: 'freshened to ~12 minutes ago regardless of today\'s '
              'real date — nowhere near _formatElapsed\'s ~999-minute '
              'display ceiling, so the on-screen timer reads as a '
              'normal, just-started session and keeps ticking upward, '
              'not stuck at a frozen maximum');
      expect(controller.elapsed, greaterThan(Duration.zero));
    });

    testWidgets(
        'shows an honest unavailable reason instead of crashing when a '
        "question in the in-progress session's questionIds is no longer "
        'in the current content package (PREP-668)', (tester) async {
      final repository = DebugDemoEnvironment.buildProgressRepository();
      final ContentPackage packageMissingAQuestion = ContentPackage(
        exam: DebugDemoEnvironment.demoContentPackage.exam,
        contentVersion: DebugDemoEnvironment.demoContentPackage.contentVersion,
        sourceVersion: DebugDemoEnvironment.demoContentPackage.sourceVersion,
        generatedAt: DebugDemoEnvironment.demoContentPackage.generatedAt,
        // demoInProgressPracticeSession.questionIds names all three of
        // demoQuestions[2..4]; dropping one of them here simulates it
        // having since been retired from the active content package,
        // while the persisted session still references it.
        questions: DebugDemoEnvironment.demoQuestions
            .where((q) =>
                q.id !=
                DebugDemoEnvironment
                    .demoInProgressPracticeSession.questionIds.first)
            .toList(),
      );

      await tester.pumpWidget(wrap(ExamOverviewScreen(
        contentPackage: packageMissingAQuestion,
        progressRepository: repository,
      )));

      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'a missing session question must be handled, never an '
              'uncaught StateError from firstWhere');
      expect(find.byType(PracticeQuestionScreen), findsNothing);
      expect(find.textContaining("can't be resumed"), findsOneWidget);
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
