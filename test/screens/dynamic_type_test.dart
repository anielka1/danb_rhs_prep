import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/repositories/content_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_scope.dart';
import 'package:danb_rhs_prep/screens/answer_explanation_screen.dart';
import 'package:danb_rhs_prep/screens/exam_overview_screen.dart';
import 'package:danb_rhs_prep/screens/home_screen.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/mock_exam_results_screen.dart';
import 'package:danb_rhs_prep/screens/mock_exam_screen.dart';
import 'package:danb_rhs_prep/screens/practice_question_screen.dart';
import 'package:danb_rhs_prep/screens/practice_summary_screen.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/screens/progress_screen.dart';
import 'package:danb_rhs_prep/screens/splash_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_bottom_navigation.dart';

import '../support/dynamic_type_probe.dart';
import '../support/practice_session_test_support.dart';

/// Never resolves — these tests only check the splash screen's *loading*
/// visual for layout overflow, so bootstrap never needs to actually
/// complete.
class _NeverLoadsContentRepository implements ContentRepository {
  @override
  Future<ContentPackage> loadContentPackage(String examId) =>
      Completer<ContentPackage>().future;
}

Widget _neverReadySplashScreen() {
  return SplashScreen(
    bootstrapService: AppBootstrapService(
      contentRepository: _NeverLoadsContentRepository(),
      localStore: InMemoryBootstrapLocalStore(),
    ),
    localStore: InMemoryBootstrapLocalStore(),
  );
}

void main() {
  Widget appWith(Widget home) =>
      MaterialApp(theme: AppTheme.lightTheme, home: home);

  group('every screen at 2.0x on a small iPhone', () {
    final screens = <String, Widget>{
      'HomeScreen': const HomeScreen(),
      'ExamOverviewScreen': const ExamOverviewScreen(),
      'MockExamScreen': const MockExamScreen(),
      'ProgressScreen': const ProgressScreen(),
      'ProfileSettingsScreen':
          ProfileSettingsScreen(themeModeController: ThemeModeController()),
      'PracticeQuestionScreen': const PracticeQuestionScreen(),
      'AnswerExplanationScreen': const AnswerExplanationScreen(),
      'MockExamResultsScreen': const MockExamResultsScreen(),
      'PracticeSummaryScreen': const PracticeSummaryScreen(),
    };

    for (final entry in screens.entries) {
      testWidgets('${entry.key} has no overflow at 2.0x', (tester) async {
        await pumpAtScale(tester, appWith(entry.value),
            viewport: ProbeViewport.smallPhone, textScale: 2.0);
      });
    }

    testWidgets('MainShell has no overflow at 2.0x cycling every tab',
        (tester) async {
      await pumpAtScale(tester, appWith(const MainShell()),
          viewport: ProbeViewport.smallPhone, textScale: 2.0);

      for (final label in ['Practice', 'Mock Exam', 'Progress', 'Home']) {
        // The bottom nav switches to a horizontally scrollable layout
        // (instead of shrinking or truncating labels) whenever they
        // don't all fit as four equal columns at the current text scale
        // — ensureVisible scrolls it into position first; a no-op when
        // the bar isn't scrolling.
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason:
                'unexpected overflow/exception switching to $label at 2.0x');
      }
    });
  });

  group('critical text-heavy screens at 3.0x across viewports', () {
    final criticalScreens = <String, Widget Function()>{
      'ExamOverviewScreen': () => const ExamOverviewScreen(),
      'ProgressScreen': () => const ProgressScreen(),
      'PracticeQuestionScreen': () => const PracticeQuestionScreen(),
      'AnswerExplanationScreen': () => const AnswerExplanationScreen(),
      'MockExamResultsScreen': () => const MockExamResultsScreen(),
      'PracticeSummaryScreen': () => const PracticeSummaryScreen(),
    };
    final viewports = [
      ProbeViewport.smallPhone,
      ProbeViewport.largePhone,
      ProbeViewport.ipad,
    ];

    for (final entry in criticalScreens.entries) {
      for (final viewport in viewports) {
        testWidgets('${entry.key} has no overflow at 3.0x on $viewport',
            (tester) async {
          await pumpAtScale(tester, appWith(entry.value()),
              viewport: viewport, textScale: 3.0);
        });
      }
    }
  });

  group('essential text is never lost to overflow at large scale', () {
    testWidgets('PracticeQuestionScreen keeps the full question visible',
        (tester) async {
      await pumpAtScale(
        tester,
        appWith(PracticeSessionScope(
          controller: buildDemoPracticeSessionController(),
          child: const PracticeQuestionScreen(),
        )),
        viewport: ProbeViewport.smallPhone,
        textScale: 3.0,
      );
      expect(
        find.text(DebugDemoEnvironment.demoQuestions.first.questionText),
        findsOneWidget,
      );
    });

    testWidgets('AnswerExplanationScreen keeps the full explanation visible',
        (tester) async {
      final controller = buildDemoPracticeSessionController();
      await controller.submitAnswer(
          DebugDemoEnvironment.demoQuestions.first.correctAnswerId);
      await pumpAtScale(
        tester,
        appWith(PracticeSessionScope(
          controller: controller,
          child: const AnswerExplanationScreen(),
        )),
        viewport: ProbeViewport.smallPhone,
        textScale: 3.0,
      );
      expect(
        find.text(DebugDemoEnvironment.demoQuestions.first.explanation),
        findsOneWidget,
      );
    });

    testWidgets('PrimaryButton labels are never lost to ellipsis',
        (tester) async {
      await pumpAtScale(
        tester,
        appWith(PracticeSessionScope(
          controller: buildDemoPracticeSessionController(),
          child: const PracticeQuestionScreen(),
        )),
        viewport: ProbeViewport.smallPhone,
        textScale: 3.0,
      );
      expect(find.text('Submit Answer'), findsOneWidget);
    });
  });

  group('interactive controls remain tappable at large scale', () {
    testWidgets('bottom navigation tabs meet the 44x44 minimum at 2.0x',
        (tester) async {
      await pumpAtScale(tester, appWith(const MainShell()),
          viewport: ProbeViewport.smallPhone, textScale: 2.0);

      final inkWells = find.descendant(
        of: find.byType(AppBottomNavigation),
        matching: find.byType(InkWell),
      );
      expect(inkWells, findsNWidgets(4));
      for (final element in inkWells.evaluate()) {
        final Size size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(AppTapTarget.minInteractive));
        expect(size.height, greaterThanOrEqualTo(AppTapTarget.minInteractive));
      }
    });

    testWidgets('PrimaryButton stays at least the minimum height at 3.0x',
        (tester) async {
      await pumpAtScale(
        tester,
        appWith(PracticeSessionScope(
          controller: buildDemoPracticeSessionController(),
          child: const PracticeQuestionScreen(),
        )),
        viewport: ProbeViewport.smallPhone,
        textScale: 3.0,
      );
      final Size size = tester.getSize(find.ancestor(
        of: find.text('Submit Answer'),
        matching: find.byType(ElevatedButton),
      ));
      expect(size.height, greaterThanOrEqualTo(AppTapTarget.minInteractive));
    });
  });

  group('every screen at maximum scale (4.0x) on a small iPhone', () {
    // 4.0x is used as the "largest accessibility size" stress scale, not
    // a plain reading of iOS's category names: manual on-device testing
    // at the actual largest iOS accessibility category
    // (accessibility-extra-extra-extra-large) found real overflow that a
    // 3.0x TextScaler.linear probe did not catch — iOS's largest category
    // scales noticeably beyond a flat 3.0x for some text styles. 4.0x
    // gives headroom above that observed real-device behavior so this
    // class of regression can't come back silently. No global text-scale
    // clamping is applied anywhere in the app — every screen genuinely
    // renders at this scale.
    final screens = <String, Widget>{
      'HomeScreen': const HomeScreen(),
      'ExamOverviewScreen': const ExamOverviewScreen(),
      'MockExamScreen': const MockExamScreen(),
      'ProgressScreen': const ProgressScreen(),
      'ProfileSettingsScreen':
          ProfileSettingsScreen(themeModeController: ThemeModeController()),
      'PracticeQuestionScreen': const PracticeQuestionScreen(),
      'AnswerExplanationScreen': const AnswerExplanationScreen(),
      'MockExamResultsScreen': const MockExamResultsScreen(),
      'PracticeSummaryScreen': const PracticeSummaryScreen(),
    };

    for (final entry in screens.entries) {
      testWidgets('${entry.key} has no overflow at 4.0x', (tester) async {
        await pumpAtScale(tester, appWith(entry.value),
            viewport: ProbeViewport.smallPhone, textScale: 4.0);
      });
    }

    testWidgets(
        'MainShell (week strip + bottom nav) has no overflow at 4.0x '
        'cycling every tab', (tester) async {
      await pumpAtScale(tester, appWith(const MainShell()),
          viewport: ProbeViewport.smallPhone, textScale: 4.0);

      for (final label in ['Practice', 'Mock Exam', 'Progress', 'Home']) {
        // The bottom nav switches to a horizontally scrollable layout
        // (instead of shrinking or truncating labels) whenever they
        // don't all fit as four equal columns at the current text scale
        // — ensureVisible scrolls it into position first; a no-op when
        // the bar isn't scrolling.
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason:
                'unexpected overflow/exception switching to $label at 4.0x');
      }
    });

    testWidgets('essential text and primary actions remain present at 4.0x',
        (tester) async {
      await pumpAtScale(
        tester,
        appWith(PracticeSessionScope(
          controller: buildDemoPracticeSessionController(),
          child: const PracticeQuestionScreen(),
        )),
        viewport: ProbeViewport.smallPhone,
        textScale: 4.0,
      );
      expect(
        find.text(DebugDemoEnvironment.demoQuestions.first.questionText),
        findsOneWidget,
        reason: 'the question text must not be replaced by an ellipsis',
      );
      expect(find.text('Submit Answer'), findsOneWidget,
          reason:
              'the primary action label must not be replaced by an ellipsis');

      final controller = buildDemoPracticeSessionController();
      await controller.submitAnswer(
          DebugDemoEnvironment.demoQuestions.first.correctAnswerId);
      await pumpAtScale(
        tester,
        appWith(PracticeSessionScope(
          controller: controller,
          child: const AnswerExplanationScreen(),
        )),
        viewport: ProbeViewport.smallPhone,
        textScale: 4.0,
      );
      expect(
        find.text(DebugDemoEnvironment.demoQuestions.first.explanation),
        findsOneWidget,
        reason: 'the explanation text must not be replaced by an ellipsis',
      );
    });

    testWidgets('bottom navigation tabs remain reachable at 4.0x',
        (tester) async {
      await pumpAtScale(tester, appWith(const MainShell()),
          viewport: ProbeViewport.smallPhone, textScale: 4.0);

      final inkWells = find.descendant(
        of: find.byType(AppBottomNavigation),
        matching: find.byType(InkWell),
      );
      expect(inkWells, findsNWidgets(4));
      for (final element in inkWells.evaluate()) {
        expect(tester.getSize(find.byWidget(element.widget)).width,
            greaterThan(0));
      }
    });
  });

  group('SplashScreen at large text scale', () {
    // A single pump, not pumpAtScale (which settles): the loading splash
    // shows an indeterminate CircularProgressIndicator, which by design
    // never stops animating on its own — pumpAndSettle would time out
    // waiting for an animation that isn't supposed to finish while
    // bootstrap is still pending. One pump is enough to surface a real
    // layout overflow exception, which is all this checks for.
    Future<void> pumpSplashOnce(WidgetTester tester, double textScale) async {
      final double dpr = tester.view.devicePixelRatio;
      tester.view.physicalSize = Size(
        ProbeViewport.smallPhone.size.width * dpr,
        ProbeViewport.smallPhone.size.height * dpr,
      );
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: appWith(_neverReadySplashScreen()),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: 'unexpected overflow/exception at ${textScale}x on '
              '${ProbeViewport.smallPhone.label}');
    }

    testWidgets('has no overflow at 2.0x', (tester) async {
      await pumpSplashOnce(tester, 2.0);
    });

    testWidgets('has no overflow at 4.0x', (tester) async {
      await pumpSplashOnce(tester, 4.0);
    });
  });
}
