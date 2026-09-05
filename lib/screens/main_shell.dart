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
/// selected, renders all four tab roots inside an [IndexedStack] (so
/// switching tabs never recreates a previously-opened tab's widget/scroll
/// state), and renders the one shared [AppBottomNavigation].
///
/// This widget intentionally contains no business logic — it only tracks
/// selection and reports that a tab became visible. Settings is reached
/// by each screen pushing `ProfileSettingsScreen` directly via the normal
/// `Navigator` (see `HomeScreen`'s toolbar icon), on top of this shell;
/// popping back to the shell leaves its state untouched automatically,
/// since the shell is never removed from the widget tree while Settings
/// is open.
class MainShell extends StatefulWidget {
  static const String route = '/main';

  const MainShell({
    super.key,
    this.analytics = const NoOpAnalyticsService(),
    this.progressRepository,
  });

  final AnalyticsService analytics;

  /// Forwarded straight to [HomeScreen]. Null in production (no real
  /// adapter exists yet); see [HomeScreen.progressRepository]'s own doc
  /// comment for what it enables.
  final ProgressRepository? progressRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with RestorationMixin {
  // Restoration scope is deliberately limited to "which tab is selected."
  // Nothing else about this phase's app state is worth restoring yet: no
  // practice/mock session exists to resume (Phase 6/8), and there is no
  // user-specific or sensitive data anywhere in the shell. A single
  // RestorableInt fully captures the shell's only piece of state, so a
  // heavier restoration strategy would be overengineering for what this
  // phase actually needs.
  final RestorableInt _tabIndex = RestorableInt(AppTab.home.index);

  bool _initialViewReported = false;

  AppTab get _currentTab => tabForIndex(_tabIndex.value);

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
    // Re-selecting the already-active tab is a documented no-op: there is
    // no per-tab navigation stack to pop-to-root in this phase, and doing
    // nothing avoids an unintended scroll/selection reset.
    if (tab == _currentTab) return;
    setState(() => _tabIndex.value = tab.index);
    _reportView(tab);
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
    final contentPackage = BootstrapSessionScope.maybeControllerOf(context)
        ?.snapshot
        .contentPackage;
    return Scaffold(
      body: IndexedStack(
        index: _currentTab.index,
        children: [
          HomeScreen(progressRepository: widget.progressRepository),
          ExamOverviewScreen(
            contentPackage: contentPackage,
            progressRepository: widget.progressRepository,
          ),
          MockExamScreen(progressRepository: widget.progressRepository),
          ProgressScreen(progressRepository: widget.progressRepository),
        ],
      ),
      bottomNavigationBar:
          AppBottomNavigation(current: _currentTab, onTap: _onTabSelected),
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
