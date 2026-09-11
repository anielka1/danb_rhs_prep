import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import '../study_plan/fixtures.dart';
import '../support/controlled_random.dart';

class _Repository extends InMemoryProgressRepository {
  bool fail = true;
  bool committed = false;
  @override
  Future<void> savePracticeSession(PracticeSession session) async {
    if (!fail || committed) await super.savePracticeSession(session);
    if (fail) throw StateError('Write error');
  }
}

void main() {
  for (final committed in [false, true]) {
    testWidgets(
        'ordinary practice persists order before navigation; write error committed=$committed',
        (tester) async {
      final package = fixture();
      final now = DateTime.utc(2026, 9, 11);
      final repo = _Repository()..committed = committed;
      Widget app(ControlledRandom source) => MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExamOverviewScreen(
              contentPackage: package,
              progressRepository: repo,
              entitlement: Entitlement.free(lastVerifiedAt: now),
              now: () => now,
              random: source));
      await tester.pumpWidget(app(ControlledRandom(rotate: true)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeQuestionScreen), findsNothing);
      expect(find.text('Could not save your session. Please try again.'),
          findsOneWidget);
      final before = await repo.practiceSessionsForExam(package.exam.id);
      expect(before, hasLength(committed ? 1 : 0));
      repo.fail = false;
      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeQuestionScreen), findsOneWidget);
      final saved =
          (await repo.practiceSessionsForExam(package.exam.id)).single;
      if (committed) expect(saved, before.single);
      final c = PracticeSessionScope.of(
          tester.element(find.byType(PracticeQuestionScreen)));
      expect(c.currentQuestion.answers.map((a) => a.id), ['b', 'c', 'd', 'a']);
      expect(saved.answerOrder, c.session.answerOrder);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(ControlledRandom(forbid: true)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start Practice Exam'));
      await tester.tap(find.text('Start Practice Exam'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeQuestionScreen), findsOneWidget);
      expect(
          (await repo.practiceSessionsForExam(package.exam.id)).single, saved);
    });
  }
}
