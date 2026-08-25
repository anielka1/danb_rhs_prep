import 'dart:async';

import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'bootstrap/app_bootstrap_service.dart';
import 'bootstrap/shared_preferences_bootstrap_local_store.dart';
import 'domain/models/user_profile.dart';
import 'domain/repositories/bootstrap_local_store.dart';
import 'features/content/data/bundled_content_repository.dart';
import 'services/analytics_service.dart';
import 'services/theme_mode_controller.dart';
import 'navigation/analytics_navigator_observer.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';
import 'screens/exam_date_screen.dart';
import 'screens/experience_level_screen.dart';
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
    BootstrapLocalStore? localStore,
    AppBootstrapService? bootstrapService,
  })  : _injectedThemeModeController = themeModeController,
        _injectedLocalStore = localStore,
        _injectedBootstrapService = bootstrapService;

  final AnalyticsService analytics;

  /// Test-only injection points, mirroring [analytics]'s pattern — let a
  /// test observe/drive these directly, or supply deterministic fakes.
  /// Null in production, where the State creates (and, for the ones it
  /// created itself, owns/disposes) its own.
  final ThemeModeController? _injectedThemeModeController;
  final BootstrapLocalStore? _injectedLocalStore;
  final AppBootstrapService? _injectedBootstrapService;

  @override
  State<DanbRhsPrepApp> createState() => _DanbRhsPrepAppState();
}

class _DanbRhsPrepAppState extends State<DanbRhsPrepApp> {
  late final ThemeModeController _themeModeController =
      widget._injectedThemeModeController ?? ThemeModeController();

  late final BootstrapLocalStore _localStore =
      widget._injectedLocalStore ?? SharedPreferencesBootstrapLocalStore();

  late final AppBootstrapService _bootstrapService =
      widget._injectedBootstrapService ??
          AppBootstrapService(
            contentRepository: BundledContentRepository(),
            localStore: _localStore,
          );

  @override
  void initState() {
    super.initState();
    _themeModeController.addListener(_persistThemeMode);
  }

  void _persistThemeMode() {
    final ThemePreference preference =
        _themePreferenceFor(_themeModeController.value);
    // Fire-and-forget: a local-storage failure must not block the theme
    // change the user just made (already applied via
    // ValueListenableBuilder below) or crash the app — it would only
    // mean the choice doesn't survive the next launch.
    unawaited(
      _localStore.writeThemePreference(preference).catchError((_) {}),
    );
  }

  /// Applies the theme preference bootstrap loaded from local storage —
  /// called once, from [SplashScreen.onReady], before the app navigates
  /// past the splash screen. Does not itself persist anything (it's
  /// applying a value that was just read from storage, not a new user
  /// choice), so the listener above staying attached during this update
  /// is harmless, just a redundant re-write of the same value.
  void _applyBootstrapTheme(BootstrapReady ready) {
    _themeModeController.value = _themeModeFor(ready.themePreference);
  }

  @override
  void dispose() {
    _themeModeController.removeListener(_persistThemeMode);
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
            SplashScreen.route: (_) => SplashScreen(
                  bootstrapService: _bootstrapService,
                  localStore: _localStore,
                  analytics: widget.analytics,
                  onReady: _applyBootstrapTheme,
                ),
            LoginScreen.route: (_) => const LoginScreen(),
            MainShell.route: (_) => MainShell(analytics: widget.analytics),
            WelcomeScreen.route: (_) => WelcomeScreen(
                  localStore: _localStore,
                  analytics: widget.analytics,
                ),
            ExamDateScreen.route: (_) => ExamDateScreen(
                  localStore: _localStore,
                  analytics: widget.analytics,
                ),
            ExperienceLevelScreen.route: (_) => ExperienceLevelScreen(
                  localStore: _localStore,
                  analytics: widget.analytics,
                ),
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

ThemePreference _themePreferenceFor(ThemeMode mode) => switch (mode) {
      ThemeMode.system => ThemePreference.system,
      ThemeMode.light => ThemePreference.light,
      ThemeMode.dark => ThemePreference.dark,
    };

ThemeMode _themeModeFor(ThemePreference preference) => switch (preference) {
      ThemePreference.system => ThemeMode.system,
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
    };
