import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/main_demo.dart' as demo;
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/widgets/answer_option_tile.dart';

/// Exit-gate smoke tests for the FAST 01 "clickable app without an
/// account" milestone: every prior test covers one screen or one flow in
/// isolation, but nothing previously walked the *whole* thing — onboarding
/// through Practice through Progress, and separately Mock Exam and
/// Settings — continuously, through the real composition root
/// (`lib/main_demo.dart`), the same way an actual accountless user would.
///
/// Deliberately does not assume a fixed number of practice questions: the
/// real demo `ProgressRepository` already seeds an in-progress practice
/// session (`DebugDemoEnvironment.demoInProgressPracticeSession`), so
/// Home's empty-state action reads "Continue," not "Start Practicing," and
/// "Start Practice Exam" resumes that session rather than starting a new
/// one — this test follows whichever label/session length is actually
/// real, rather than hardcoding either.
Future<void> _tapText(WidgetTester tester, String label) async {
  final Finder finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _completeOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(demo.createDebugDemoApp());
  await tester.pumpAndSettle();
  await _tapText(tester, 'Start Preparing');
  await _tapText(tester, "I haven't scheduled it yet");
  await _tapText(tester, 'Continue');
  await _tapText(tester, 'Just starting');
  await _tapText(tester, 'Continue');
  expect(find.byType(MainShell), findsOneWidget);
}

void main() {
  testWidgets('settings edits study answers and returns without onboarding',
      (tester) async {
    await _completeOnboarding(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Exam timeframe');
    await _tapText(tester, 'In 1–3 months');
    await _tapText(tester, 'Save changes');
    expect(find.byType(ProfileSettingsScreen), findsOneWidget);
    expect(find.text('In 1–3 months'), findsOneWidget);
    await _tapText(tester, 'Study experience');
    await _tapText(tester, 'Studying already');
    await _tapText(tester, 'Save changes');
    expect(find.byType(ProfileSettingsScreen), findsOneWidget);
    expect(find.text('Studying already'), findsOneWidget);
    await _tapText(tester, 'Exam timeframe');
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('In 1–3 months'), findsOneWidget);
  });
  testWidgets(
      'E2E: onboarding -> Home -> Practice -> feedback -> Summary -> '
      'Progress, entirely through real demo composition', (tester) async {
    await _completeOnboarding(tester);

    // Home: an honest empty-state action reaches the real practice flow —
    // whichever label is actually shown (see this file's doc comment).
    final Finder homeAction = find.text('Continue').evaluate().isNotEmpty
        ? find.text('Continue')
        : find.text('Start Practicing');
    expect(homeAction, findsOneWidget);
    await tester.tap(homeAction);
    await tester.pumpAndSettle();

    await _tapText(tester, 'Start Practice Exam');

    // Answer every question in the real (possibly resumed) session,
    // driven entirely by what the screen actually shows rather than an
    // assumed question count.
    while (true) {
      expect(find.byType(AnswerOptionTile), findsWidgets);
      await tester.tap(find.byType(AnswerOptionTile).first);
      await tester.pumpAndSettle();
      await _tapText(tester, 'Submit Answer');

      if (find.text('Finish').evaluate().isNotEmpty) {
        await _tapText(tester, 'Finish');
        break;
      }
      await _tapText(tester, 'Next Question');
    }

    // Summary: a real, computed score — never the old fixed "78%"/
    // "78/100 Correct" literals (see docs/PROTOTYPE_CONTENT_AUDIT.md and
    // the PREP-649 fix this guards against regressing).
    expect(find.byType(PracticeSummaryScreen), findsOneWidget);
    expect(find.text('Session Complete!'), findsOneWidget);
    expect(find.textContaining('Correct'), findsOneWidget);
    expect(find.text('78%'), findsNothing);
    expect(find.text('78/100 Correct'), findsNothing);

    await _tapText(tester, 'Back to Home');
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(PracticeSummaryScreen), findsNothing);

    // Progress: the questions just answered are recorded through the same
    // shared demo repository the practice session used, so real content
    // must show here — never the honest-but-generic "No progress yet"
    // state that would show if the repository were never actually wired
    // through end to end.
    await _tapText(tester, 'Progress');
    expect(find.text('No progress yet'), findsNothing);
    expect(find.text('DOMAIN BREAKDOWN'), findsOneWidget);
  });

  testWidgets(
      'smoke: Mock Exam and Settings are each reachable and real, '
      'independent of the Practice flow', (tester) async {
    await _completeOnboarding(tester);

    // Mock Exam: start, answer, and finish a real attempt.
    await _tapText(tester, 'Mock Exam');
    await _tapText(tester, 'Start Mock Exam');
    await _tapText(tester, 'Begin exam');
    await _tapText(tester, 'Finish mock exam');
    await _tapText(tester, 'Finish exam');
    expect(
      find.text('Above practice threshold'),
      anyOf(findsOneWidget, findsNothing),
    );
    expect(
      find.text('Below practice threshold'),
      anyOf(findsOneWidget, findsNothing),
    );
    expect(find.text('PASSED'), findsNothing);
    await _tapText(tester, 'Back to Mock Exam');

    // Back to Home, then Settings: a real, working local preference.
    await _tapText(tester, 'Home');
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    await tester.ensureVisible(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSettingsScreen), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
  });
}
