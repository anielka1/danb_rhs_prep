import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/analytics_service.dart';
import 'services/theme_mode_controller.dart';
import 'navigation/analytics_navigator_observer.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/exam_overview_screen.dart';
import 'screens/practice_question_screen.dart';
import 'screens/answer_explanation_screen.dart';
import 'screens/practice_summary_screen.dart';
import 'screens/mock_exam_results_screen.dart';
import 'screens/mock_exam_screen.dart';
import 'screens/profile_settings_screen.dart';

void main() {
  runApp(const DanbRhsPrepApp());
}

class DanbRhsPrepApp extends StatefulWidget {
  const DanbRhsPrepApp({
    super.key,
    this.analytics = const NoOpAnalyticsService(),
    ThemeModeController? themeModeController,
  }) : _injectedThemeModeController = themeModeController;

  final AnalyticsService analytics;

  /// Test-only injection point, mirroring [analytics]'s pattern — allows
  /// a test to observe/drive the controller directly. Null in production,
  /// where the State creates (and owns/disposes) its own.
  final ThemeModeController? _injectedThemeModeController;

  @override
  State<DanbRhsPrepApp> createState() => _DanbRhsPrepAppState();
}

class _DanbRhsPrepAppState extends State<DanbRhsPrepApp> {
  late final ThemeModeController _themeModeController =
      widget._injectedThemeModeController ?? ThemeModeController();

  @override
  void dispose() {
    // Only dispose a controller this State created itself; a
    // caller-injected controller remains the caller's to dispose.
    if (widget._injectedThemeModeController == null) {
      _themeModeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeController,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'DANB RHS Prep',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          restorationScopeId: 'danb_rhs_prep_root',
          navigatorObservers: [AnalyticsNavigatorObserver(widget.analytics)],
          initialRoute: SplashScreen.route,
          routes: {
            SplashScreen.route: (_) => const SplashScreen(),
            LoginScreen.route: (_) => const LoginScreen(),
            MainShell.route: (_) => MainShell(analytics: widget.analytics),
            ExamOverviewScreen.route: (_) => const ExamOverviewScreen(),
            PracticeQuestionScreen.route: (_) => const PracticeQuestionScreen(),
            AnswerExplanationScreen.route: (_) =>
                const AnswerExplanationScreen(),
            PracticeSummaryScreen.route: (_) => const PracticeSummaryScreen(),
            MockExamResultsScreen.route: (_) => const MockExamResultsScreen(),
            MockExamScreen.route: (_) => const MockExamScreen(),
            ProfileSettingsScreen.route: (_) => ProfileSettingsScreen(
                themeModeController: _themeModeController),
          },
        );
      },
    );
  }
}
