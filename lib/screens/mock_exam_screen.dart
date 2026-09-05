import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/repositories/progress_repository.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import 'exam_overview_screen.dart';

/// Root content for the Mock Exam tab.
///
/// The real mock-exam generator/timer/session engine (Phase 8) doesn't
/// exist yet, and neither of the two existing exam-flavored screens is an
/// honest stand-in for it: `ExamOverviewScreen`'s copy ("Practice Exam
/// Prep", "Start Practice Exam") is specifically about practice, and
/// `MockExamResultsScreen` shows a completed attempt's score, which would
/// misrepresent an exam the user hasn't taken. Showing either verbatim
/// under a "Mock Exam" tab would be inaccurate content, not just a
/// placeholder. This screen is an honest "not built yet" state instead,
/// composed from the existing `EmptyState` component.
class MockExamScreen extends StatelessWidget {
  static const String route = '/mock-exam';
  const MockExamScreen({super.key, this.progressRepository});

  /// Forwarded to the `ExamOverviewScreen` this screen's own "View Exam
  /// Info" pushes — see `MainShell.progressRepository`'s doc comment for
  /// what it enables. Null in production today.
  final ProgressRepository? progressRepository;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: EmptyState(
        icon: Icons.assignment_rounded,
        title: 'Mock Exam',
        message: 'The full timed mock exam is coming soon. In the meantime, '
            'you can review the exam info and blueprint.',
        primaryActionLabel: 'View Exam Info',
        onPrimaryAction: () => _openExamOverview(context),
      ),
    );
  }

  // Not `Navigator.pushNamed`: see `HomeScreen._openExamOverview`'s doc
  // comment for why `ExamOverviewScreen` needs its content threaded in
  // directly rather than read from an ambient scope.
  void _openExamOverview(BuildContext context) {
    final snapshot = BootstrapSessionScope.snapshotOf(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: ExamOverviewScreen.route),
        builder: (_) => ExamOverviewScreen(
          contentPackage: snapshot.contentPackage,
          progressRepository: progressRepository,
        ),
      ),
    );
  }
}
