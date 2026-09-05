import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/mock_exam_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/screens/progress_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_bottom_navigation.dart';
import 'package:danb_rhs_prep/widgets/app_dialog.dart';

import '../support/practice_session_test_support.dart';

/// Finds the root [SemanticsNode] via the non-deprecated
/// [RendererBinding.rootPipelineOwner] tree: the root pipeline owner
/// itself has no [SemanticsOwner] in a multi-view test harness, so this
/// walks its children to find the per-view owner that does.
SemanticsNode _rootSemanticsNode(WidgetTester tester) {
  SemanticsNode? found;
  void visit(PipelineOwner owner) {
    found ??= owner.semanticsOwner?.rootSemanticsNode;
    if (found == null) owner.visitChildren(visit);
  }

  visit(tester.binding.rootPipelineOwner);
  return found!;
}

void main() {
  /// Depth-first order of every SemanticsNode carrying a label, matching
  /// how a screen reader's linear swipe navigation would traverse the
  /// tree — a direct, structural check of reading order, distinct from
  /// (and not a substitute for) manually swiping through with VoiceOver.
  List<String> semanticsLabelOrder(SemanticsNode root) {
    final List<String> labels = [];
    void visit(SemanticsNode node) {
      if (node.label.isNotEmpty) labels.add(node.label);
      final List<SemanticsNode> children =
          node.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder);
      for (final child in children) {
        visit(child);
      }
    }

    visit(root);
    return labels;
  }

  testWidgets(
      'PracticeQuestionScreen: question content precedes the primary action',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: PracticeSessionScope(
        controller: buildDemoPracticeSessionController(),
        child: const PracticeQuestionScreen(),
      ),
    ));

    final SemanticsNode root = _rootSemanticsNode(tester);
    final List<String> order = semanticsLabelOrder(root);

    final int optionIndex =
        order.indexWhere((label) => label.startsWith('Option A'));
    final int submitIndex = order.indexOf('Submit Answer');
    expect(optionIndex, greaterThanOrEqualTo(0));
    expect(submitIndex, greaterThanOrEqualTo(0));
    expect(optionIndex, lessThan(submitIndex),
        reason: 'the question/options must be reachable before Submit Answer');

    handle.dispose();
  });

  testWidgets(
      'MainShell: bottom navigation order is Home, Practice, Mock Exam, Progress',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    ));

    final SemanticsNode root = _rootSemanticsNode(tester);
    final List<String> order = semanticsLabelOrder(root);
    final List<String> tabOrder = order
        .where(['Home', 'Practice', 'Mock Exam', 'Progress'].contains)
        .toList();

    expect(tabOrder, ['Home', 'Practice', 'Mock Exam', 'Progress']);
    handle.dispose();
  });

  testWidgets('ProfileSettingsScreen: back action precedes page content',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: ProfileSettingsScreen(themeModeController: ThemeModeController()),
    ));

    final SemanticsNode root = _rootSemanticsNode(tester);
    final List<String> order = semanticsLabelOrder(root);

    final int backIndex = order.indexOf('Back');
    final int changePasswordIndex = order.indexOf('Change Password');
    expect(backIndex, greaterThanOrEqualTo(0));
    expect(changePasswordIndex, greaterThanOrEqualTo(0));
    expect(backIndex, lessThan(changePasswordIndex),
        reason: 'the toolbar back action should be reachable before scrolling '
            'through the page content below it');

    handle.dispose();
  });

  testWidgets('AppDialog (Material): title/message precede the actions',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => AppDialog.show<void>(
            context: context,
            title: 'Delete Attempt?',
            message: 'This cannot be undone.',
            actions: const [
              AppDialogAction(
                  label: 'Cancel',
                  value: null,
                  style: AppDialogActionStyle.cancel),
              AppDialogAction(
                  label: 'Delete',
                  value: null,
                  style: AppDialogActionStyle.destructive),
            ],
          ),
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final SemanticsNode root = _rootSemanticsNode(tester);
    final List<String> order = semanticsLabelOrder(root);

    final int titleIndex = order.indexOf('Delete Attempt?');
    final int messageIndex = order.indexOf('This cannot be undone.');
    final int cancelIndex = order.indexOf('Cancel');
    final int deleteIndex = order.indexOf('Delete');

    expect(titleIndex, greaterThanOrEqualTo(0));
    expect(messageIndex, greaterThan(titleIndex));
    expect(cancelIndex, greaterThan(messageIndex));
    expect(deleteIndex, greaterThan(messageIndex));

    handle.dispose();
  });

  group('inactive IndexedStack tabs are excluded from accessibility', () {
    testWidgets('only the active tab\'s content is reachable', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MainShell(),
      ));

      // Home is active: its content is reachable, the other three tabs'
      // screen-specific content is not.
      expect(find.bySemanticsLabel('Today'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Exam Info')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Your Progress')), findsNothing);

      handle.dispose();
    });

    testWidgets('switching tabs swaps which content is reachable',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MainShell(),
      ));

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('Your Progress')), findsOneWidget);
      // Home's own content is no longer reachable now that it's the
      // inactive tab.
      expect(find.bySemanticsLabel('Today'), findsNothing);

      handle.dispose();
    });
  });

  // Sanity checks that the underlying screens exist and render, so the
  // imports above aren't flagged unused if a future refactor trims a
  // test — keeps this file self-contained.
  testWidgets('ExamOverviewScreen, MockExamScreen and ProgressScreen render',
      (tester) async {
    for (final screen in [
      const ExamOverviewScreen(),
      const MockExamScreen(),
      const ProgressScreen(),
    ]) {
      await tester
          .pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: screen));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('AppBottomNavigation exists as the shell\'s tab bar',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    ));
    expect(find.byType(AppBottomNavigation), findsOneWidget);
  });
}
