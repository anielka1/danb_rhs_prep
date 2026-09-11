import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/screens/diagnostic_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/screens/saved_questions_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_screen.dart';
import '../study_plan/fixtures.dart';

class _Repo extends InMemoryProgressRepository {
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<PracticeSession?> inProgressPracticeSession(String id) async {
    if (fail) throw StateError('read error');
    await gate?.future;
    return super.inProgressPracticeSession(id);
  }
}

void main() {
  final now = DateTime.utc(2026, 9, 11);
  final package = fixture(count: 80);
  late _Repo repo;
  setUp(() {
    repo = _Repo();
  });
  BootstrapSessionController bootstrap(
          {bool empty = false, DateTime? examDate}) =>
      BootstrapSessionController(
          BootstrapReady(
              profile: null,
              selectedExamId: package.exam.id,
              contentPackage: empty ? fixture(count: 0) : package,
              themePreference: ThemePreference.system,
              readinessSnapshot: null,
              entitlement: Entitlement.free(lastVerifiedAt: now),
              onboardingComplete: true,
              examDateSelection: examDate == null
                  ? null
                  : ExamDateSelection(
                      precision: ExamDatePrecision.exact, date: examDate),
              experienceLevel: null),
          progressRepository: repo);
  Widget app(
          {bool empty = false,
          bool dark = false,
          double scale = 1,
          DateTime? examDate}) =>
      MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: BootstrapSessionScope(
                  controller: bootstrap(empty: empty, examDate: examDate),
                  child:
                      HomeScreen(progressRepository: repo, now: () => now))));
  Future<PracticeSession> seed(
      {PracticeMode mode = PracticeMode.planned}) async {
    final qs = package.questions.take(3).toList();
    final s = PracticeSession(
        id: 'legacy-session',
        examId: package.exam.id,
        mode: mode,
        questionIds: qs.map((q) => q.id).toList(),
        answerOrder: {
          for (final q in qs) q.id: q.answers.reversed.map((a) => a.id).toList()
        },
        status: SessionStatus.inProgress,
        startedAt: now,
        planDate: '2026-09-10');
    await repo.savePracticeSession(s);
    final c = PracticeSessionController(
        session: s, questions: qs, progressRepository: repo, now: () => now);
    await c.submitAnswer(qs.first.correctAnswerId);
    return s;
  }

  for (final offset in [-1, 0, 30]) {
    testWidgets('exam date state offset=$offset', (tester) async {
      await tester.pumpWidget(app(examDate: DateTime(2026, 9, 11 + offset)));
      await tester.pumpAndSettle();
      expect(
          find.text(offset < 0
              ? 'Update date'
              : offset == 0
                  ? 'Exam today'
                  : '30'),
          findsOneWidget);
    });
  }
  testWidgets('today card is honest when no answers or measured time exist',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Today’s progress'), findsOneWidget);
    expect(find.text('Not available'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('No mistakes to review'), findsOneWidget);
  });
  testWidgets('empty history has no invented statistics or calendar',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Today’s progress'), findsOneWidget);
    expect(find.text('Answer accuracy'), findsNothing);
    expect(find.text('Study calendar'), findsNothing);
    expect(find.text('No mistakes to review'), findsOneWidget);
    expect(find.text('Continue session'), findsNothing);
    await tester.ensureVisible(find.text('Quick 10'));
    await tester.tap(find.text('Quick 10'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeQuestionScreen), findsOneWidget);
    expect(await repo.practiceSessionsForExam(package.exam.id), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('no content disables start but saved library remains accessible',
      (tester) async {
    await tester.pumpWidget(app(empty: true));
    await tester.pumpAndSettle();
    expect(find.text('Continue session'), findsNothing);
    expect(
        find.textContaining('No approved practice questions'), findsOneWidget);
    await tester.ensureVisible(find.text('Saved questions'));
    await tester.tap(find.text('Saved questions'));
    await tester.pumpAndSettle();
    expect(find.byType(SavedQuestionsScreen), findsOneWidget);
  });
  testWidgets(
      'loading never flashes a new session and read error retries safely',
      (tester) async {
    final s = await seed();
    repo.gate = Completer<void>();
    await tester.pumpWidget(app());
    await tester.pump();
    expect(find.text('Continue session'), findsNothing);
    repo.fail = true;
    repo.gate!.complete();
    await tester.pumpAndSettle();
    // Reconstruct to exercise the failing read, not an empty repository.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('Your first answer'), findsNothing);
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Continue session'), findsOneWidget);
    expect((await repo.inProgressPracticeSession(package.exam.id))!.id, s.id);
  });
  testWidgets(
      'legacy planned session resumes exact saved answers and order after restart',
      (tester) async {
    final s = await seed();
    for (var i = 0; i < 2; i++) {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
      await tester.tap(find.text('Continue session'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeQuestionScreen), findsOneWidget);
      final c = PracticeSessionScope.of(
          tester.element(find.byType(PracticeQuestionScreen)));
      expect(c.answeredCount, 1);
      expect(c.session.id, s.id);
      expect(c.session.answerOrder, s.answerOrder);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    expect(await repo.practiceSessionsForExam(package.exam.id), hasLength(1));
    expect(await repo.answerAttemptsForExam(package.exam.id), hasLength(1));
  });
  testWidgets(
      'active starting check opens diagnostic rather than another practice',
      (tester) async {
    await seed(mode: PracticeMode.diagnostic);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue session'));
    await tester.pumpAndSettle();
    expect(find.byType(DiagnosticScreen), findsOneWidget);
    expect(find.text('Resume diagnostic'), findsOneWidget);
    expect(await repo.practiceSessionsForExam(package.exam.id), hasLength(1));
  });
  testWidgets('random tile creates one question, not generic setup',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Random question'));
    await tester.tap(find.text('Random question'));
    await tester.pumpAndSettle();
    final c = PracticeSessionScope.of(
        tester.element(find.byType(PracticeQuestionScreen)));
    expect(c.totalQuestions, 1);
    expect(c.session.answerOrder, isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('timed tile starts a stopwatch session', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Timed quiz'));
    await tester.tap(find.text('Timed quiz'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No automatic submission'), findsOneWidget);
    await tester.tap(find.text('Start Timed quiz'));
    await tester.pumpAndSettle();
    final c = PracticeSessionScope.of(
        tester.element(find.byType(PracticeQuestionScreen)));
    expect(c.session.mode, PracticeMode.timedQuiz);
    expect(c.totalQuestions, 10);
    expect(find.text('Timed quiz · active answering time'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('topic tile requires and applies actual topic selection',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Practice by topic'));
    await tester.tap(find.text('Practice by topic'));
    await tester.pumpAndSettle();
    final topic = package.exam.domains.first.topics.first;
    await tester.ensureVisible(find.text(topic.name));
    await tester.tap(find.text(topic.name));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start Practice by topic'));
    await tester.tap(find.text('Start Practice by topic'));
    await tester.pumpAndSettle();
    final c = PracticeSessionScope.of(
        tester.element(find.byType(PracticeQuestionScreen)));
    expect(c.questions.every((q) => q.topicId == topic.id), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('mistakes tile selects only previously wrong questions',
      (tester) async {
    final c = PracticeSessionController(
        session: PracticeSession(
            id: 'wrong',
            examId: package.exam.id,
            mode: PracticeMode.quickPractice,
            questionIds: [package.questions.first.id],
            status: SessionStatus.inProgress,
            startedAt: now),
        questions: [package.questions.first],
        progressRepository: repo,
        now: () => now);
    await c.submitAnswer('b');
    await c.complete();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Review mistakes'));
    await tester.tap(find.text('Review mistakes'));
    await tester.pumpAndSettle();
    final review = PracticeSessionScope.of(
        tester.element(find.byType(PracticeQuestionScreen)));
    expect(review.session.mode, PracticeMode.incorrectQuestions);
    expect(review.session.questionIds, [package.questions.first.id]);
    expect((await repo.answerAttemptsForExam(package.exam.id)).length, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('unfinished mock also offers Continue session and keeps answers',
      (tester) async {
    final q = package.questions.first;
    final mock = MockAttempt(
        id: 'active-mock',
        examId: package.exam.id,
        questionIds: [q.id],
        answers: {q.id: 'b'},
        flaggedQuestionIds: {q.id},
        status: MockAttemptStatus.inProgress,
        startedAt: now,
        durationMinutes: 15,
        answerOrder: {
          q.id: ['d', 'c', 'b', 'a']
        });
    await repo.saveMockAttempt(mock);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Continue session'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue session'));
    await tester.tap(find.text('Continue session'));
    await tester.pumpAndSettle();
    expect(find.byType(MockExamScreen), findsOneWidget);
    final saved = await repo.mockAttempt(mock.id);
    expect(saved!.answers, mock.answers);
    expect(saved.answerOrder, mock.answerOrder);
  });
  testWidgets('mock tile opens the existing mock flow with bootstrap scope',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mock exam'));
    await tester.tap(find.text('Mock exam'));
    await tester.pumpAndSettle();
    expect(find.byType(MockExamScreen), findsOneWidget);
    expect(find.byType(ExamOverviewScreen), findsNothing);
  });
  for (final dark in [false, true]) {
    testWidgets('starting check selection and save at 4x text dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(4)),
                child: DiagnosticScreen(session: bootstrap()))));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Start diagnostic'));
        await tester.tap(find.text('Start diagnostic'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Correct fixture answer'));
        await tester.tap(find.text('Correct fixture answer'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save and continue'));
        await tester.tap(find.text('Save and continue'));
        await tester.pumpAndSettle();
        expect(find.text('Question 2 of 15'), findsOneWidget);
        expect(
            (await repo.answerAttemptsForExam(package.exam.id))
                .single
                .isCorrect,
            isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  for (final dark in [false, true]) {
    testWidgets('small screen large text dark=$dark', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(app(dark: dark, scale: 4));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      await tester.ensureVisible(find.text('Optional starting check'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
