import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/repositories/progress_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import 'exam_overview_screen.dart';

/// No real progress/attempt data exists yet — no progress repository is
/// wired to this screen (only an in-memory fake exists, meant for tests).
/// The weekly-activity chart, accuracy/streak stats, weekly goal, and
/// subject-mastery rows previously here were all fabricated numbers
/// presented as if they were the current user's real activity. An honest
/// "no progress yet" state replaces them; see
/// docs/PROTOTYPE_CONTENT_AUDIT.md.
class ProgressScreen extends StatelessWidget {
  static const String route = '/progress';
  const ProgressScreen({super.key, this.progressRepository});

  /// Forwarded to the `ExamOverviewScreen` this screen's own "Start
  /// Practicing" pushes — see `MainShell.progressRepository`'s doc
  /// comment for what it enables. Null in production today.
  final ProgressRepository? progressRepository;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text('Your Progress', style: textStyles.h1),
            const SizedBox(height: AppSpacing.xxl + 2),
            EmptyState(
              icon: Icons.insights_rounded,
              title: 'No progress yet',
              message: 'Your activity, accuracy, and subject mastery will '
                  'appear here once you start practicing.',
              primaryActionLabel: 'Start Practicing',
              onPrimaryAction: () => _openExamOverview(context),
            ),
            const SizedBox(height: 90),
          ],
        ),
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
