import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/models/practice_session.dart';
import '../domain/repositories/progress_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/primary_button.dart';
import 'exam_overview_screen.dart';
import 'profile_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String route = '/home';

  const HomeScreen(
      {super.key, this.progressRepository, this.now = DateTime.now});

  /// Null in production — no real [ProgressRepository] adapter exists
  /// yet (progress/readiness wiring is explicitly deferred, see
  /// `BootstrapLocalStore`'s own doc comment), so this screen always
  /// falls back to its default "no study tasks yet" empty state there.
  /// When present (only ever `DebugDemoEnvironment.buildProgressRepository()`,
  /// wired from `lib/main_demo.dart`), this screen queries it for a
  /// resumable session and offers a real "Continue" action instead of
  /// starting a new one, exactly reflecting what the repository reports —
  /// never a fabricated or hardcoded state.
  final ProgressRepository? progressRepository;

  /// Real `DateTime.now` in production. Injectable so a test (a golden
  /// test in particular — the calendar chrome would otherwise render a
  /// different date every day it runs) can pin the "today" this screen
  /// renders, the same pattern already used by `ExamDateScreen`,
  /// `PracticeSessionController` and `MockExamController`.
  final DateTime Function() now;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  // The real current date/week, not a fixed placeholder — there is no
  // daily study schedule to show yet (see EmptyState below), but the
  // calendar chrome itself should never claim a date that isn't today.
  late final DateTime _today = widget.now();
  late final DateTime _weekStart =
      _today.subtract(Duration(days: _today.weekday - 1));
  late final List<DateTime> _weekDates =
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));
  late int _selectedDayIndex = _today.weekday - 1;

  String get _formattedToday =>
      '${_monthNames[_today.month - 1]} ${_today.day}, ${_today.year}';

  /// Null whenever [HomeScreen.progressRepository] is null (production
  /// today) — nothing to query, so the study-tasks card below skips
  /// straight to its default empty state with no async work and no
  /// loading flicker. Only set, and only queried once per screen
  /// instance, when a repository is actually present.
  Future<PracticeSession?>? _inProgressSessionFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ProgressRepository? repository = widget.progressRepository;
    if (repository == null || _inProgressSessionFuture != null) return;
    final String examId =
        BootstrapSessionScope.snapshotOf(context).selectedExamId;
    // A repository is free to fail either synchronously (throwing before
    // ever producing a Future) or asynchronously (a rejected Future) — the
    // try/catch normalizes the former into the latter so the FutureBuilder
    // below can handle both the same way, via `snapshot.hasError`, instead
    // of a synchronous throw escaping this lifecycle method uncaught.
    try {
      _inProgressSessionFuture = repository.inProgressPracticeSession(examId);
    } catch (error, stackTrace) {
      _inProgressSessionFuture = Future<PracticeSession?>.error(
        error,
        stackTrace,
      );
    }
  }

  /// Not `Navigator.pushNamed`: a screen pushed via the static route
  /// table in `main.dart` would have no `BootstrapSessionScope` ancestor
  /// (that scope only ever wraps `MainShell`'s own page, inserted once by
  /// `SplashScreen`/`ExperienceLevelScreen` — a separately-pushed route is
  /// a sibling in the `Navigator`'s `Overlay`, not a descendant of it).
  /// `ExamOverviewScreen` needs the real, already-loaded content package
  /// to offer a genuine practice session, so it's passed in directly here
  /// instead, read once from this tab's own ambient scope.
  void _openExamOverview(BuildContext context) {
    final snapshot = BootstrapSessionScope.snapshotOf(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: ExamOverviewScreen.route),
        builder: (_) => ExamOverviewScreen(
          contentPackage: snapshot.contentPackage,
          progressRepository: widget.progressRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return AppScaffold(
      actions: [
        Tooltip(
          message: 'Settings',
          child: CircleIconButton(
            icon: Icons.settings_rounded,
            semanticLabel: 'Settings',
            // The root navigator, not this tab's own nested one (see
            // MainShell's doc comment on its per-tab Navigators): Settings
            // is a cross-cutting concern, not part of Home's own stack,
            // and pushing it on the root is what keeps it resolving
            // through main.dart's named-route table (and therefore still
            // visible to the app-level AnalyticsNavigatorObserver, which
            // only observes the root navigator).
            onPressed: () => Navigator.of(context, rootNavigator: true)
                .pushNamed(ProfileSettingsScreen.route),
          ),
        ),
      ],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formattedToday, style: textStyles.bodySmall),
                      const SizedBox(height: 2),
                      Text('Today', style: textStyles.h1),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(Icons.person, color: colors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _WeekStrip(
              selectedIndex: _selectedDayIndex,
              dayNames: _dayNames,
              dayNumbers: _weekDates.map((d) => d.day).toList(),
              onSelect: (i) => setState(() => _selectedDayIndex = i),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _StudyTasksCard(
              inProgressSessionFuture: _inProgressSessionFuture,
              onGoToPractice: () => _openExamOverview(context),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
      // Disabled: this "quick add" affordance has no defined feature or
      // roadmap phase behind it yet — there is nothing for it to create.
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        backgroundColor: colors.surfaceContainer,
        foregroundColor: context.semanticColors.mutedForeground,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: AppIconSize.large),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

/// The "what should I study today" card: an honest empty state by
/// default, or — only when [inProgressSessionFuture] is non-null and
/// resolves to a real unfinished session — a "continue where you left
/// off" state instead. Both states navigate to the same real
/// [ExamOverviewScreen] destination via [onGoToPractice]; this widget
/// never invents a way to jump back into the exact question a session
/// left off on, since no screen can resume one at that granularity yet
/// — "Continue" honestly means "go back to studying," not "resume
/// exactly where you were."
class _StudyTasksCard extends StatelessWidget {
  const _StudyTasksCard({
    required this.inProgressSessionFuture,
    required this.onGoToPractice,
  });

  final Future<PracticeSession?>? inProgressSessionFuture;
  final VoidCallback onGoToPractice;

  @override
  Widget build(BuildContext context) {
    final Future<PracticeSession?>? future = inProgressSessionFuture;
    if (future == null) {
      return _emptyState(hasInProgressSession: false);
    }

    return FutureBuilder<PracticeSession?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'Checking your progress…');
        }
        // A repository failure and the natural "no session" result both
        // fall back to the same honest default — never a stack trace or
        // a broken screen, and never a fabricated session.
        final bool hasInProgressSession =
            !snapshot.hasError && snapshot.data != null;
        return _emptyState(hasInProgressSession: hasInProgressSession);
      },
    );
  }

  // No real study-schedule data exists yet (see
  // docs/PROTOTYPE_CONTENT_AUDIT.md) — an honest empty state, not
  // fabricated tasks, stands in until study planning is built.
  Widget _emptyState({required bool hasInProgressSession}) {
    return EmptyState(
      icon: Icons.event_note_rounded,
      title: hasInProgressSession
          ? 'Pick up where you left off'
          : 'No study tasks yet',
      message: hasInProgressSession
          ? "You have a practice session you haven't finished yet."
          : 'Your scheduled practice sessions will appear here once '
              'study planning is available.',
      primaryActionLabel:
          hasInProgressSession ? 'Continue' : 'Start Practicing',
      onPrimaryAction: onGoToPractice,
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final int selectedIndex;
  final List<String> dayNames;
  final List<int> dayNumbers;
  final ValueChanged<int> onSelect;

  const _WeekStrip({
    required this.selectedIndex,
    required this.dayNames,
    required this.dayNumbers,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final List<Widget> items = List.generate(dayNames.length, (i) {
      final bool selected = i == selectedIndex;
      return Semantics(
        button: true,
        selected: selected,
        label: '${dayNames[i]} ${dayNumbers[i]}',
        child: GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: context
                .reducedMotionDuration(const Duration(milliseconds: 150)),
            // The tap target (this whole AnimatedContainer, since
            // GestureDetector sizes to its child) must never shrink below
            // 44x44 regardless of how narrow a given day's name/number
            // text naturally is — at ordinary text scale, several days
            // (e.g. "Sat 5") were previously as narrow as ~31pt wide with
            // only the symmetric padding below to fall back on.
            constraints: const BoxConstraints(
              minWidth: AppTapTarget.minInteractive,
              minHeight: AppTapTarget.minInteractive,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected ? colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.smallIcon),
            ),
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayNames[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? colors.onPrimary.withValues(alpha: 0.7)
                          : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    '${dayNumbers[i]}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: selected ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    // At ordinary text sizes, seven naturally-sized days comfortably fill
    // (and are spread evenly across) the available width — the
    // ConstrainedBox's minWidth forces that even spread exactly as
    // before. At very large Dynamic Type sizes, the days' natural total
    // width can exceed the available width; instead of overflowing, the
    // row becomes horizontally scrollable at its natural (wider) size,
    // so every day stays fully visible and reachable, just not all at
    // once.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: items,
            ),
          ),
        );
      },
    );
  }
}
