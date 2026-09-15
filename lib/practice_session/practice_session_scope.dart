import 'package:flutter/widgets.dart';

import 'practice_session_controller.dart';

/// Makes the shared [PracticeSessionController] for the current practice
/// run available to descendants, mirroring `BootstrapSessionScope`.
///
/// Each screen in the flow (`PracticeQuestionScreen`,
/// `AnswerExplanationScreen`, `PracticeSummaryScreen`) is reached via an
/// explicit `Navigator.push`/`pushReplacement` that re-wraps its builder
/// in this same scope with the *same* controller instance — routes are
/// siblings in the `Navigator`'s `Overlay`, not descendants of each
/// other, so an `InheritedWidget` inserted only once (e.g. around
/// `ExamOverviewScreen`) would not reach a screen pushed afterward as its
/// own separate route.
class PracticeSessionScope extends InheritedWidget {
  const PracticeSessionScope({
    super.key,
    required this.controller,
    this.returnToTopics,
    required super.child,
  });

  final PracticeSessionController controller;
  final VoidCallback? returnToTopics;

  static PracticeSessionController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PracticeSessionScope>()
        ?.controller;
  }

  static PracticeSessionController of(BuildContext context) {
    final PracticeSessionController? controller = maybeOf(context);
    assert(controller != null, 'No PracticeSessionScope found in context.');
    return controller!;
  }

  @override
  bool updateShouldNotify(PracticeSessionScope oldWidget) =>
      !identical(controller, oldWidget.controller);
}
