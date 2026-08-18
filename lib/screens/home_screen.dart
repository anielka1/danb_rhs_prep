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

  static const List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Aug 18, 2026', style: AppTextStyles.bodySmall),
                              SizedBox(height: 2),
                              Text('Today', style: AppTextStyles.h1),
                            ],
                          ),
                        ),
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.lavenderContainer,
                          child: Icon(Icons.person, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _WeekStrip(
                      selectedIndex: _selectedDayIndex,
                      dayNames: _dayNames,
                      dayNumbers: _dayNumbers,
                      onSelect: (i) => setState(() => _selectedDayIndex = i),
                    ),
                    const SizedBox(height: 22),
                    _TaskCard(
                      title: 'Radiation Physics Review',
                      time: '9:00 AM',
                      description: 'Fundamental properties and x-ray tube components review.',
                    ),
                    const SizedBox(height: 14),
                    _TaskCard(
                      title: 'Infection Control Practice',
                      time: '10:00 AM',
                      description: 'Calibrate barrier requirements & protective equipment.',
                    ),
                    const SizedBox(height: 14),
                    _MockExamCard(
                      onTap: () => Navigator.of(context).pushNamed(ExamOverviewScreen.route),
                    ),
                    const SizedBox(height: 14),
                    _TaskCard(
                      title: 'Equipment Safety Quiz',
                      time: '1:00 PM',
                      description: 'Test proper x-ray machine settings and tube angles.',
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
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(dayNames.length, (i) {
        final bool selected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  dayNames[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${dayNumbers[i]}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.navy,
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

  const _TaskCard({required this.title, required this.time, required this.description});

  @override
  Widget build(BuildContext context) {
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
              border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.6),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy)),
                    ),
                    Text(time, style: AppTextStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                Text(description, style: AppTextStyles.bodySmall),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: const Icon(Icons.circle, color: Colors.white, size: 0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Mock Exam Session',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                      ),
                      Text('11:00 AM',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.85))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Live review: biological effects & dose limitations.',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 14),
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
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.lavenderContainer,
                                  child: Icon(Icons.person, size: 14, color: AppColors.primary),
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
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
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
