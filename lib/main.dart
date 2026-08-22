import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/analytics_service.dart';
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

class DanbRhsPrepApp extends StatelessWidget {
  const DanbRhsPrepApp({
    super.key,
    this.analytics = const NoOpAnalyticsService(),
  });

  final AnalyticsService analytics;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DANB RHS Prep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // No deliberate user preference exists yet (Settings persistence is
      // out of scope for this task), so the app follows the OS setting.
      themeMode: ThemeMode.system,
      restorationScopeId: 'danb_rhs_prep_root',
      navigatorObservers: [AnalyticsNavigatorObserver(analytics)],
      initialRoute: SplashScreen.route,
      routes: {
        SplashScreen.route: (_) => const SplashScreen(),
        LoginScreen.route: (_) => const LoginScreen(),
        MainShell.route: (_) => MainShell(analytics: analytics),
        ExamOverviewScreen.route: (_) => const ExamOverviewScreen(),
        PracticeQuestionScreen.route: (_) => const PracticeQuestionScreen(),
        AnswerExplanationScreen.route: (_) => const AnswerExplanationScreen(),
        PracticeSummaryScreen.route: (_) => const PracticeSummaryScreen(),
        MockExamResultsScreen.route: (_) => const MockExamResultsScreen(),
        MockExamScreen.route: (_) => const MockExamScreen(),
        ProfileSettingsScreen.route: (_) => const ProfileSettingsScreen(),
      },
    );
  }
}
