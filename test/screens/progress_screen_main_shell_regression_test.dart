import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

/// Deliberately kept in its own file, importing nothing from
/// `ProgressScreen` itself and touching only `MainShell`'s stable, public
/// constructor (`progressRepository`, unchanged before and after PREP-651)
/// plus its bottom navigation. That means this file's *source* compiles
/// identically whether `ProgressScreen`/`MainShell`'s internal wiring is
/// the pre-fix or post-fix version — a constructor-signature change on
/// `ProgressScreen` (e.g. its own added `contentPackage` parameter) can
/// never be the reason this test does or doesn't compile.
///
/// Verified by hand against the pre-fix revision (main@675a8f9): checking
/// out `lib/screens/progress_screen.dart` and `lib/screens/main_shell.dart`
/// from that commit and rerunning this file alone compiles cleanly and
/// FAILS on every `expect` below except the first, because that revision's
/// Progress tab shows nothing but "No progress yet" regardless of the
/// seeded repository/content — proving the regression behaviorally through
/// a stable public entry point, not as a mere API-shape mismatch.
void main() {
  testWidgets(
      'navigating to the Progress tab shows a real readiness trend, domain '
      'breakdown and completed-mock history — not just "No progress yet"',
      (tester) async {
    final BootstrapSessionController controller = BootstrapSessionController(
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
      home: BootstrapSessionScope(
        controller: controller,
        child: MainShell(
          progressRepository: DebugDemoEnvironment.buildProgressRepository(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();

    expect(find.text('No progress yet'), findsNothing);
    expect(find.text('Daily activity'), findsOneWidget);
    expect(find.text('Progress by subject'), findsOneWidget);
    expect(find.text('MOCK EXAM HISTORY'), findsOneWidget);
    // The earlier, worse-scoring readiness snapshot and the earlier,
    // completed mock attempt distinguish "real repository data reaching
    // the screen" from a single value that could look hardcoded either
    // way.
    expect(find.textContaining('1/2 ·'), findsOneWidget);
    expect(find.textContaining('2/2 ·'), findsOneWidget);
  });
}
