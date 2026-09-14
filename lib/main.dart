import 'subscription/premium_access.dart';
import 'domain/repositories/subscription_repository.dart';
import 'screens/subscription_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'bootstrap/app_bootstrap_service.dart';
import 'bootstrap/bootstrap_session_controller.dart';
import 'bootstrap/bootstrap_session_scope.dart';
import 'domain/repositories/progress_session_repository.dart';
import 'bootstrap/shared_preferences_bootstrap_local_store.dart';
import 'data/local/app_database.dart';
import 'data/repositories/drift_progress_repository.dart';
import 'data/repositories/drift_user_settings_repository.dart';
import 'domain/models/user_profile.dart';
import 'domain/repositories/bootstrap_local_store.dart';
import 'domain/repositories/user_settings_repository.dart';
import 'domain/repositories/progress_repository.dart';
import 'features/content/data/bundled_content_repository.dart';
import 'services/analytics_service.dart';
import 'services/theme_mode_controller.dart';
import 'navigation/analytics_navigator_observer.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';
import 'screens/exam_date_screen.dart';
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
    this.subscriptionRepository,
    ThemeModeController? themeModeController,
    BootstrapLocalStore? localStore,
    AppBootstrapService? bootstrapService,
    AppDatabase? database,
    this.progressRepository,
    this.userSettingsRepository,
  })  : _injectedThemeModeController = themeModeController,
        _injectedLocalStore = localStore,
        _injectedBootstrapService = bootstrapService,
        _injectedDatabase = database;

  final SubscriptionRepository? subscriptionRepository;
  final AnalyticsService analytics;
  final UserSettingsRepository? userSettingsRepository;

  /// Test and demo-entrypoint injection points, mirroring [analytics]'s
  /// pattern — let a test observe/drive these directly, or supply
  /// deterministic fakes; `lib/main_demo.dart` (run explicitly via
  /// `flutter run -t lib/main_demo.dart`, never by plain `flutter run` or
  /// a release build) is the one non-test caller that supplies
  /// [bootstrapService] itself. Null in production, where the State
  /// creates (and, for the ones it created itself, owns/disposes) its
  /// own — this file must never import or reference
  /// `DebugDemoEnvironment` (see `lib/main_demo.dart` and
  /// `test/main_test.dart`'s isolation check).
  final ThemeModeController? _injectedThemeModeController;
  final BootstrapLocalStore? _injectedLocalStore;
  final AppBootstrapService? _injectedBootstrapService;

  /// A test-only escape hatch: a widget test that constructs
  /// `DanbRhsPrepApp` directly (rather than going through `main()`) has no
  /// real on-device documents directory to open a database in — injecting
  /// an in-memory `AppDatabase.forTesting(NativeDatabase.memory())` avoids
  /// that entirely. Null in production and in `lib/main_demo.dart` (the
  /// demo entrypoint deliberately uses the same in-memory
  /// `InMemoryProgressRepository` it always has, via [progressRepository]
  /// below, not this database — see that file's own doc comment for why
  /// its state is intentionally reset on every run).
  final AppDatabase? _injectedDatabase;

  /// Threaded straight to [MainShell]/[HomeScreen]. Null in production
  /// (where the State builds a real [DriftProgressRepository] over its own
  /// database instead — see [_DanbRhsPrepAppState._progressRepository]);
  /// only ever non-null when a caller explicitly wants to override that,
  /// which today is just `lib/main_demo.dart` supplying
  /// `DebugDemoEnvironment.buildProgressRepository()` so the "continue an
  /// in-progress session" path stays demonstrable with fixed, synthetic
  /// data rather than this device's real (and initially empty) history.
  final ProgressRepository? progressRepository;

  @override
  State<DanbRhsPrepApp> createState() => _DanbRhsPrepAppState();
}

class _DanbRhsPrepAppState extends State<DanbRhsPrepApp> {
  late final ThemeModeController _themeModeController =
      widget._injectedThemeModeController ?? ThemeModeController();

  late final BootstrapLocalStore _localStore =
      widget._injectedLocalStore ?? SharedPreferencesBootstrapLocalStore();

  /// Null whenever a real database wasn't created by this State itself
  /// (i.e. [widget._injectedDatabase] was supplied), so [dispose] never
  /// closes a database a caller still owns.
  AppDatabase? _ownedDatabase;

  AppDatabase get _database =>
      widget._injectedDatabase ?? (_ownedDatabase ??= AppDatabase());

  late final UserSettingsRepository _userSettingsRepository =
      widget.userSettingsRepository ?? DriftUserSettingsRepository(_database);

  /// Current UI generation's lease over the injected or SQLite repository.
  /// A successful reset replaces it; old controllers retain a retired lease.
  late ProgressSessionRepository _effectiveProgressRepository =
      ProgressSessionRepository(
          widget.progressRepository ?? DriftProgressRepository(_database));

  late final AppBootstrapService _bootstrapService =
      widget._injectedBootstrapService ??
          AppBootstrapService(
            contentRepository: BundledContentRepository(),
            localStore: _localStore,
            userSettingsRepository: _userSettingsRepository,
          );

  late final PremiumAccessController _access = PremiumAccessController(
      widget.subscriptionRepository ??
          CachedSubscriptionRepository(_localStore));

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
    _access.dispose();
    _themeModeController.removeListener(_persistThemeMode);
    // Only dispose a controller this State created itself; a
    // caller-injected controller remains the caller's to dispose.
    if (widget._injectedThemeModeController == null) {
      _themeModeController.dispose();
    }
    // Same reasoning: only close a database this State opened itself —
    // `widget._injectedDatabase` (a test's in-memory database) remains
    // that test's to close.
    _ownedDatabase?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeController,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'DANB RHS Prep',
          builder: (_, child) =>
              PremiumAccessScope(controller: _access, child: child!),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          restorationScopeId: 'danb_rhs_prep_root',
          navigatorObservers: [AnalyticsNavigatorObserver(widget.analytics)],
          initialRoute: SplashScreen.route,
          routes: {
            SubscriptionScreen.route: (_) => const SubscriptionScreen(),
            SplashScreen.route: (_) => SplashScreen(
                  bootstrapService: _bootstrapService,
                  localStore: _localStore,
                  analytics: widget.analytics,
                  onReady: _applyBootstrapTheme,
                  progressRepository: _effectiveProgressRepository,
                ),
            MainShell.route: (_) => MainShell(
                  analytics: widget.analytics,
                  progressRepository: _effectiveProgressRepository,
                ),
            WelcomeScreen.route: (_) => WelcomeScreen(
                  localStore: _localStore,
                  analytics: widget.analytics,
                  userSettingsRepository: _userSettingsRepository,
                ),
            ExamDateScreen.route: (_) => ExamDateScreen(
                  localStore: _localStore,
                  analytics: widget.analytics,
                  userSettingsRepository: _userSettingsRepository,
                ),
            ExamOverviewScreen.route: (_) => const ExamOverviewScreen(),
            PracticeQuestionScreen.route: (_) => const PracticeQuestionScreen(),
            AnswerExplanationScreen.route: (_) =>
                const AnswerExplanationScreen(),
            PracticeSummaryScreen.route: (_) => const PracticeSummaryScreen(),
            MockExamResultsScreen.route: (_) => const MockExamResultsScreen(),
            MockExamScreen.route: (_) => const MockExamScreen(),
            '/settings/exam-date': (context) {
              final argument = ModalRoute.of(context)?.settings.arguments;
              final session =
                  argument is BootstrapSessionController ? argument : null;
              return BootstrapSessionScope.carry(
                  session,
                  ExamDateScreen(
                      localStore: _localStore,
                      userSettingsRepository: _userSettingsRepository,
                      editing: true));
            },
            ProfileSettingsScreen.route: (context) {
              final argument = ModalRoute.of(context)?.settings.arguments;
              final session =
                  argument is BootstrapSessionController ? argument : null;
              return ProfileSettingsScreen(
                themeModeController: _themeModeController,
                session: session,
                localStore: _localStore,
                userSettingsRepository: _userSettingsRepository,
                onResetProgress: session != null &&
                        _effectiveProgressRepository.supportsReset
                    ? () async {
                        final next = await _effectiveProgressRepository
                            .reset(session.snapshot.selectedExamId);
                        _effectiveProgressRepository = next;
                        session.replaceProgressRepository(next);
                        if (!context.mounted) return;
                        Navigator.of(context, rootNavigator: true)
                            .pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            settings:
                                const RouteSettings(name: MainShell.route),
                            builder: (_) => BootstrapSessionScope(
                              controller: session,
                              child: MainShell(
                                  analytics: widget.analytics,
                                  progressRepository: next),
                            ),
                          ),
                          (_) => false,
                        );
                      }
                    : null,
              );
            },
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
