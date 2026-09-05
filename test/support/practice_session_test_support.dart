import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';

/// A deterministic [PracticeSessionController] over
/// [DebugDemoEnvironment]'s 5 demo questions, positioned at the first
/// question and not yet answered — for widget/golden tests that need a
/// real active practice session without going through
/// ExamOverviewScreen's own tap-to-start flow. No [ProgressRepository]
/// is attached; tests that need one can construct their own
/// [PracticeSessionController] directly.
PracticeSessionController buildDemoPracticeSessionController() {
  final PracticeSession session = PracticeSession(
    id: 'test-practice-session',
    examId: DebugDemoEnvironment.demoExamId,
    mode: PracticeMode.quickPractice,
    questionIds: DebugDemoEnvironment.demoQuestions.map((q) => q.id).toList(),
    status: SessionStatus.inProgress,
    startedAt: DateTime.utc(2026, 1, 1, 9),
  );
  return PracticeSessionController(
    session: session,
    questions: DebugDemoEnvironment.demoQuestions,
    now: () => DateTime.utc(2026, 1, 1, 9, 5),
  );
}
