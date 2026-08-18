import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/exam_overview_screen.dart';
import 'screens/practice_question_screen.dart';
import 'screens/answer_explanation_screen.dart';
import 'screens/practice_summary_screen.dart';
import 'screens/mock_exam_results_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_settings_screen.dart';

void main() {
  runApp(const DanbRhsPrepApp());
}

class DanbRhsPrepApp extends StatelessWidget {
  const DanbRhsPrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DANB RHS Prep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: SplashScreen.route,
      routes: {
        SplashScreen.route: (_) => const SplashScreen(),
        LoginScreen.route: (_) => const LoginScreen(),
        HomeScreen.route: (_) => const HomeScreen(),
        ExamOverviewScreen.route: (_) => const ExamOverviewScreen(),
        PracticeQuestionScreen.route: (_) => const PracticeQuestionScreen(),
        AnswerExplanationScreen.route: (_) => const AnswerExplanationScreen(),
        PracticeSummaryScreen.route: (_) => const PracticeSummaryScreen(),
        MockExamResultsScreen.route: (_) => const MockExamResultsScreen(),
        ProgressScreen.route: (_) => const ProgressScreen(),
        ProfileSettingsScreen.route: (_) => const ProfileSettingsScreen(),
      },
    );
  }
}
