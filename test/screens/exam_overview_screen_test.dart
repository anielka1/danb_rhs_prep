import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

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
}
