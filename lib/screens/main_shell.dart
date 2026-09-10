import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/repositories/progress_repository.dart';
import '../services/analytics_service.dart';
import '../widgets/app_bottom_navigation.dart';
import 'exam_overview_screen.dart';
import 'home_screen.dart';
import 'mock_exam_screen.dart';
import 'progress_screen.dart';

/// Single main shell for the four primary tabs: owns which tab is
/// selected, gives each tab its own [Navigator] (so a deep flow pushed
/// within one tab — Practice's question/explanation/summary chain, Mock
/// Exam's instructions/question/results chain — keeps its own history
/// independently of the others, and switching tabs never disturbs it),
/// and renders the one shared [AppBottomNavigation].
///
/// Each tab's [Navigator] lives inside the [IndexedStack] alongside its
/// root screen, so [IndexedStack] itself is what keeps every tab's
/// `NavigatorState` (and therefore its full route stack) alive across tab
/// switches — the same mechanism that already preserved each tab's own
/// scroll/local widget state before this task. [NavigatorPopHandler]
/// coordinates the system back button/gesture: it reactively tracks
/// whether the *currently visible* tab's `Navigator` can pop (via the
/// `NavigationNotification`s a `Navigator` already dispatches whenever
/// its own stack changes — not a value computed once and left stale),
/// and only when it can't does a back press fall through to whatever's
/// above this shell (Android's "exit app" default, since `MainShell` is
/// the app's own root-most screen after onboarding).
///
/// Settings is reached by `HomeScreen` pushing `ProfileSettingsScreen` on
/// the *root* navigator (`Navigator.of(context, rootNavigator: true)`),
/// not any tab's own nested one — it's a cross-cutting concern, not part
/// of Home's own stack, and staying on the root keeps it resolving
/// through `main.dart`'s named-route table exactly as before. Popping
/// back from Settings therefore always lands on whichever tab/stack state
/// this shell already had, untouched.
class MainShell extends StatefulWidget {
  static const String route = '/main';

  const MainShell({
    super.key,
    this.analytics = const NoOpAnalyticsService(),
    this.progressRepository,
  });

  final AnalyticsService analytics;

  /// Forwarded straight to [HomeScreen]. A real `DriftProgressRepository`
  /// in production (wired as `main.dart`'s default); see
  /// [HomeScreen.progressRepository]'s own doc comment for what it
  /// enables.
  final ProgressRepository? progressRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

/// What a screen deep inside one tab's own navigation stack can ask this
/// shell to do — deliberately narrow: only what
/// [PracticeSummaryScreen]'s "Back to Home" genuinely needs (leave the
/// current tab entirely and land on a different one, optionally resetting
/// the tab being left behind to its own root first), never direct access
/// to [MainShell]'s own state. A plain `Navigator.of(context)` call can no
/// longer do this once each tab owns its own [Navigator]: popping within
/// Practice's stack can never make Home the visible tab.
abstract class MainShellController {
  /// The tab currently visible in the [IndexedStack] — what a caller
  /// should pass as [goToTab]'s `resetTab` when it means "reset the tab
  /// I'm actually leaving," since a deep flow reached via a cross-tab
  /// shortcut (e.g. Home's "Start Practicing") lives on *that* tab's own
  /// nested Navigator, not necessarily the tab the flow is conceptually
  /// "about."
  AppTab get currentTab;

  /// Switches to [tab]. If [resetTab] is given, that tab's own navigation
  /// stack is popped back to its root first — e.g. leaving Practice after
  /// finishing a session, so a later visit to that tab starts at
  /// `ExamOverviewScreen` again rather than resuming mid-summary.
  void goToTab(AppTab tab, {AppTab? resetTab});
}

/// Makes the enclosing [MainShell]'s [MainShellController] available to
/// descendants, mirroring the existing `BootstrapSessionScope`/
/// `PracticeSessionScope` pattern used elsewhere in this app.
class MainShellScope extends InheritedWidget {
  const MainShellScope({
    super.key,
    required this.controller,
    this.activeTab,
    required super.child,
  });

  final MainShellController controller;

  /// Captured separately from the mutable controller so tab changes notify
  /// preserved routes that need to refresh their repository data.
  final AppTab? activeTab;

  static AppTab? activeTabOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainShellScope>()?.activeTab;

  static MainShellController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MainShellScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) =>
      !identical(controller, oldWidget.controller) ||
      activeTab != oldWidget.activeTab;
}

class _MainShellState extends State<MainShell>
    with RestorationMixin
    implements MainShellController {
  // Restoration scope is deliberately limited to "which tab is selected."
  // Nothing else about this phase's app state is worth restoring yet: no
  // practice/mock session exists to resume (Phase 6/8), and there is no
  // user-specific or sensitive data anywhere in the shell. A single
  // RestorableInt fully captures the shell's only piece of state, so a
  // heavier restoration strategy would be overengineering for what this
  // phase actually needs. Each tab's own navigation stack is intentionally
  // not restored across a full app restart — only its in-memory state
  // survives (per [IndexedStack]) while the app is running.
  final RestorableInt _tabIndex = RestorableInt(AppTab.home.index);

  /// One key per tab, in [AppTab] enum order — never recreated, so each
  /// `Navigator`'s identity (and therefore its whole route stack) survives
  /// every rebuild of this widget.
  final List<GlobalKey<NavigatorState>> _tabNavigatorKeys =
      List.generate(AppTab.values.length, (_) => GlobalKey<NavigatorState>());

  bool _initialViewReported = false;

  AppTab get _currentTab => tabForIndex(_tabIndex.value);

  @override
  AppTab get currentTab => _currentTab;

  @override
  String get restorationId => 'main_shell';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_tabIndex, 'selected_tab_index');

    // A restored index that's out of range (e.g. from a future app version
    // with a different tab set) falls back to Home rather than indexing
    // out of bounds into AppTab.values.
    _tabIndex.value = tabForIndex(_tabIndex.value).index;

    // restoreState can in principle run again later in this State's
    // lifetime; only the very first call represents "the app's initial
    // screen view" and should be reported.
    if (!_initialViewReported) {
      _initialViewReported = true;
      _reportView(_currentTab);
    }
  }

  void _reportView(AppTab tab) {
    // Analytics must never be able to break navigation.
    try {
      widget.analytics.trackScreenView(_analyticsIdFor(tab));
    } catch (_) {
      // Intentionally swallowed.
    }
  }

  void _onTabSelected(AppTab tab) {
    if (tab == _currentTab) {
      // Re-selecting the already-active tab pops its own stack back to
      // root — the standard, expected mobile pattern, and distinct from
      // switching to a *different* tab (which never resets anything, so
      // each tab's history is genuinely preserved).
      _tabNavigatorKeys[tab.index]
          .currentState
          ?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _tabIndex.value = tab.index);
    _reportView(tab);
  }

  @override
  void goToTab(AppTab tab, {AppTab? resetTab}) {
    if (resetTab != null) {
      _tabNavigatorKeys[resetTab.index]
          .currentState
          ?.popUntil((route) => route.isFirst);
    }
    if (tab != _currentTab) {
      setState(() => _tabIndex.value = tab.index);
      _reportView(tab);
    }
  }

  Widget _tabNavigator(AppTab tab, Widget root) {
    return Navigator(
      key: _tabNavigatorKeys[tab.index],
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => root,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Read once here rather than inside ExamOverviewScreen itself: it's
    // pushed as its own route elsewhere (Home's "Start Practicing"), and
    // a separately-pushed route is a sibling in the Navigator's Overlay,
    // not a descendant of MainShell — it cannot see this ambient scope,
    // so its content is threaded in as a plain constructor value instead.
    //
    // The nullable, non-asserting lookup, not `snapshotOf`: MainShell is
    // always wrapped in a real BootstrapSessionScope in the running app,
    // but plenty of existing tests construct a bare MainShell on its own
    // to check unrelated things (tab layout, dynamic type, ...) — that
    // must keep working, with ExamOverviewScreen simply falling back to
    // its own honest "not available" state (null contentPackage) rather
    // than every such test having to grow bootstrap scaffolding it has
    // nothing to do with.
    final session = BootstrapSessionScope.maybeControllerOf(context);
    final contentPackage = session?.snapshot.contentPackage;
    final progressRepository =
        widget.progressRepository ?? session?.progressRepository;
    final entitlement = session?.snapshot.entitlement;

    return MainShellScope(
      controller: this,
      activeTab: _currentTab,
      child: NavigatorPopHandler(
        onPopWithResult: (Object? result) {
          _tabNavigatorKeys[_currentTab.index].currentState?.pop(result);
        },
        child: Scaffold(
          body: IndexedStack(
            index: _currentTab.index,
            children: [
              _tabNavigator(
                AppTab.home,
                HomeScreen(progressRepository: progressRepository),
              ),
              _tabNavigator(
                AppTab.practice,
                ExamOverviewScreen(
                  contentPackage: contentPackage,
                  progressRepository: progressRepository,
                  entitlement: entitlement,
                ),
              ),
              _tabNavigator(
                AppTab.mockExam,
                MockExamScreen(
                  contentPackage: contentPackage,
                  progressRepository: progressRepository,
                ),
              ),
              _tabNavigator(
                AppTab.progress,
                ProgressScreen(
                  contentPackage: contentPackage,
                  progressRepository: progressRepository,
                ),
              ),
            ],
          ),
          bottomNavigationBar:
              AppBottomNavigation(current: _currentTab, onTap: _onTabSelected),
        ),
      ),
    );
  }
}

/// Maps a raw tab index to the corresponding [AppTab], falling back to
/// [AppTab.home] for any value outside the valid range — e.g. a restored
/// index left over from a future app version with a different tab set.
/// Exposed at the top level (rather than kept private) so this fallback
/// behavior can be unit-tested directly, without having to fake a restored
/// value through the platform restoration channel.
AppTab tabForIndex(int index) {
  const List<AppTab> values = AppTab.values;
  return index >= 0 && index < values.length ? values[index] : AppTab.home;
}

/// Stable, non-user-facing analytics identifiers for each tab. Deliberately
/// distinct from the tab's display label (which is translated UI text).
String _analyticsIdFor(AppTab tab) {
  switch (tab) {
    case AppTab.home:
      return 'home';
    case AppTab.practice:
      return 'practice';
    case AppTab.mockExam:
      return 'mock_exam';
    case AppTab.progress:
      return 'progress';
  }
}
