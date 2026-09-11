import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

void main() {
  testWidgets('returning to Progress reads answers saved on another tab',
      (tester) async {
    final repository = InMemoryProgressRepository();
    final package = DebugDemoEnvironment.demoContentPackage;
    final session = BootstrapSessionController(BootstrapReady(
      selectedExamId: package.exam.id,
      contentPackage: package,
      profile: null,
      themePreference: ThemePreference.system,
      readinessSnapshot: null,
      entitlement: Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 9, 8)),
      examDateSelection: null,
      experienceLevel: null,
      onboardingComplete: true,
    ));
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: BootstrapSessionScope(
            controller: session,
            child: MainShell(progressRepository: repository))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('No progress yet'), findsOneWidget);
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    await repository.saveQuestionState(QuestionState.unseen(
      examId: package.exam.id,
      questionId: package.questions.first.id,
    ).withAttempt(isCorrect: true, answeredAt: DateTime.utc(2026, 9, 8)));
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('No progress yet'), findsNothing);
    expect(find.text('DOMAIN BREAKDOWN'), findsOneWidget);
    final practice = DebugDemoEnvironment.demoInProgressPracticeSession;
    await repository.savePracticeSession(practice);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    await repository.savePracticeSession(practice.copyWith(
      status: SessionStatus.completed,
      completedAt: DateTime.utc(2026, 9, 8),
    ));
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Browse practice modes'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });
}
