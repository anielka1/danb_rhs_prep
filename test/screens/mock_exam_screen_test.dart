import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

void main() {
  testWidgets('shows an honest "coming soon" placeholder, not fake exam data',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const MockExamScreen(),
    ));

    expect(find.text('Mock Exam'), findsOneWidget);
    expect(find.textContaining('coming soon'), findsOneWidget);
    expect(find.text('View Exam Info'), findsOneWidget);
  });

  testWidgets('"View Exam Info" opens the existing exam overview screen',
      (tester) async {
    // MockExamScreen is always reached as a MainShell tab in the real
    // app, which is always wrapped in a BootstrapSessionScope — this
    // wrapper mirrors that, since "View Exam Info" now reads it to pass
    // the real content package into ExamOverviewScreen (see
    // `MockExamScreen._openExamOverview`'s doc comment for why).
    final controller = BootstrapSessionController(
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

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      routes: {
        MockExamScreen.route: (_) => BootstrapSessionScope(
              controller: controller,
              child: const MockExamScreen(),
            ),
        ExamOverviewScreen.route: (_) => const ExamOverviewScreen(),
      },
      initialRoute: MockExamScreen.route,
    ));

    await tester.tap(find.text('View Exam Info'));
    await tester.pumpAndSettle();

    expect(find.text('Exam Info'), findsOneWidget);
  });
}
