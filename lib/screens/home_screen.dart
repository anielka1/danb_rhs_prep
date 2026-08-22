import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import 'exam_overview_screen.dart';
import 'progress_screen.dart';
import 'profile_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String route = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDayIndex = 1; // Tue is selected in the source screenshot

  static const List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  static const List<int> _dayNumbers = [17, 18, 19, 20, 21, 22, 23];

  void _onNavTap(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        break;
      case AppTab.practice:
        Navigator.of(context).pushNamed(ExamOverviewScreen.route);
        break;
      case AppTab.stats:
        Navigator.of(context).pushNamed(ProgressScreen.route);
        break;
      case AppTab.profile:
        Navigator.of(context).pushNamed(ProfileSettingsScreen.route);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding),
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
                              Text('Aug 18, 2026', style: textStyles.bodySmall),
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
                      dayNumbers: _dayNumbers,
                      onSelect: (i) => setState(() => _selectedDayIndex = i),
                    ),
                    const SizedBox(height: 22),
                    const _TaskCard(
                      title: 'Radiation Physics Review',
                      time: '9:00 AM',
                      description:
                          'Fundamental properties and x-ray tube components review.',
                    ),
                    const SizedBox(height: 14),
                    const _TaskCard(
                      title: 'Infection Control Practice',
                      time: '10:00 AM',
                      description:
                          'Calibrate barrier requirements & protective equipment.',
                    ),
                    const SizedBox(height: 14),
                    _MockExamCard(
                      onTap: () => Navigator.of(context)
                          .pushNamed(ExamOverviewScreen.route),
                    ),
                    const SizedBox(height: 14),
                    const _TaskCard(
                      title: 'Equipment Safety Quiz',
                      time: '1:00 PM',
                      description:
                          'Test proper x-ray machine settings and tube angles.',
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: AppIconSize.large),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: AppBottomNav(current: AppTab.home, onTap: _onNavTap),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(dayNames.length, (i) {
        final bool selected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected ? colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.smallIcon),
            ),
            child: Column(
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
        );
      }),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String time;
  final String description;

  const _TaskCard(
      {required this.title, required this.time, required this.description});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: colors.primary.withValues(alpha: 0.5),
                  width: AppBorderWidth.thick),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colors.onSurface)),
                    ),
                    Text(time, style: textStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Text(description, style: textStyles.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MockExamCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MockExamCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Mock Exam Session',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: colors.onPrimary)),
                      ),
                      Text('11:00 AM',
                          style: textStyles.bodySmall.copyWith(
                              color: colors.onPrimary.withValues(alpha: 0.85))),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    'Live review: biological effects & dose limitations.',
                    style: textStyles.bodySmall.copyWith(
                        color: colors.onPrimary.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: AppSpacing.md + 2),
                  Row(
                    children: [
                      SizedBox(
                        width: 84,
                        height: 28,
                        child: Stack(
                          children: List.generate(4, (i) {
                            return Positioned(
                              left: i * 20.0,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: colors.onPrimary,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: colors.primaryContainer,
                                  child: Icon(Icons.person,
                                      size: AppIconSize.small - 2,
                                      color: colors.primary),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.onPrimary.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.play_arrow_rounded,
                            color: colors.onPrimary, size: AppIconSize.medium),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
