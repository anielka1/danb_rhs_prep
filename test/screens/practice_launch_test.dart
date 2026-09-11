import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/practice_session/practice_generator.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import '../study_plan/fixtures.dart';

class _LastRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

void main() {
  final now = DateTime.utc(2026, 9, 11);
  test('random selection shuffles eligible pool before taking one', () {
    final package = fixture(count: 4);
    final selection = PracticeGenerator.select(
        package: package,
        questionStates: [],
        requestedCount: 1,
        random: _LastRandom());
    expect(selection.questions.single.id, 'fixture-1');
    expect(
        PracticeGenerator.select(
                package: package, questionStates: [], requestedCount: 1)
            .questions
            .single
            .id,
        'fixture-0');
  });
  test('timed quiz restores accumulated answering time, IDs and order',
      () async {
    final package = fixture(count: 2), repo = InMemoryProgressRepository();
    var clock = now;
    final session = PracticeSession(
        id: 'timed',
        examId: package.exam.id,
        mode: PracticeMode.timedQuiz,
        questionIds: package.questions.map((q) => q.id).toList(),
        answerOrder: {
          for (final q in package.questions) q.id: ['d', 'c', 'b', 'a']
        },
        status: SessionStatus.inProgress,
        startedAt: now);
    final c = PracticeSessionController(
        session: session,
        questions: package.questions,
        progressRepository: repo,
        now: () => clock);
    await c.saveSession();
    await c.submitAnswer('a', activeDurationSeconds: 37);
    clock = now.add(const Duration(days: 1));
    final resumed = await PracticeSessionController.resume(
        session: (await repo.inProgressPracticeSession(package.exam.id))!,
        questions: package.questions,
        progressRepository: repo,
        now: () => clock);
    expect(resumed.recordedAnswerSeconds, 37);
    expect(resumed.answeredCount, 1);
    expect(resumed.session.mode, PracticeMode.timedQuiz);
    expect(resumed.session.answerOrder, session.answerOrder);
  });
  for (final cancel in [false, true]) {
    testWidgets(
        'Quick 10 confirms actual small pool before saving cancel=$cancel',
        (tester) async {
      final package = fixture(count: 3), repo = InMemoryProgressRepository();
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExamOverviewScreen(
              contentPackage: package,
              progressRepository: repo,
              launch: PracticeLaunch.quick10,
              autoStart: true,
              now: () => now)));
      await tester.pumpAndSettle();
      expect(find.text('3 questions available'), findsOneWidget);
      expect(await repo.practiceSessionsForExam(package.exam.id), isEmpty);
      await tester.tap(find.text(cancel ? 'Cancel' : 'Start 3 questions'));
      await tester.pumpAndSettle();
      expect(await repo.practiceSessionsForExam(package.exam.id),
          hasLength(cancel ? 0 : 1));
      if (!cancel) {
        expect(find.byType(PracticeQuestionScreen), findsOneWidget);
        expect(
            (await repo.inProgressPracticeSession(package.exam.id))!
                .questionIds,
            hasLength(3));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('Quick 10 respects exhausted free allowance without saving',
      (tester) async {
    final package = fixture(count: 80), repo = InMemoryProgressRepository();
    for (var i = 0; i < package.exam.freeTier.dailyPracticeQuestions; i++) {
      await repo.recordAnswerAttempt(
          answer(package.questions.first, now, id: 'cap-$i'));
    }
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: ExamOverviewScreen(
            contentPackage: package,
            progressRepository: repo,
            entitlement: Entitlement.free(lastVerifiedAt: now),
            launch: PracticeLaunch.quick10,
            autoStart: true,
            now: () => now)));
    await tester.pumpAndSettle();
    expect(find.text("You've reached today's free practice limit."),
        findsOneWidget);
    expect(await repo.practiceSessionsForExam(package.exam.id), isEmpty);
  });
}
