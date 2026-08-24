import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import 'exam_overview_screen.dart';
import 'profile_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String route = '/home';
  const HomeScreen({super.key});

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
  final DateTime _today = DateTime.now();
  late final DateTime _weekStart =
      _today.subtract(Duration(days: _today.weekday - 1));
  late final List<DateTime> _weekDates =
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));
  late int _selectedDayIndex = _today.weekday - 1;

  String get _formattedToday =>
      '${_monthNames[_today.month - 1]} ${_today.day}, ${_today.year}';

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
            onPressed: () =>
                Navigator.of(context).pushNamed(ProfileSettingsScreen.route),
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
            // No real study-schedule data exists yet (see
            // docs/PROTOTYPE_CONTENT_AUDIT.md) — an honest empty state,
            // not fabricated tasks, stands in until study planning is
            // built. "Start Practicing" is a real, working action.
            EmptyState(
              icon: Icons.event_note_rounded,
              title: 'No study tasks yet',
              message: 'Your scheduled practice sessions will appear here once '
                  'study planning is available.',
              primaryActionLabel: 'Start Practicing',
              onPrimaryAction: () =>
                  Navigator.of(context).pushNamed(ExamOverviewScreen.route),
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
