import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/radiation_icon.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String route = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.route);
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Background fading toward the primary-container tint, matching
          // the prototype's cream-to-periwinkle splash gradient using
          // theme-aware roles instead of a bespoke fixed color.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surface, colors.surface, colors.primaryContainer],
            stops: const [0.0, 0.62, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
            child: Column(
              children: [
                const SizedBox(height: 160),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.5),
                      width: AppBorderWidth.regular,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const RadiationIcon(size: 46),
                ),
                const SizedBox(height: 28),
                Text(
                  'DANB RHS Prep',
                  textAlign: TextAlign.center,
                  style: textStyles.h1,
                ),
                const SizedBox(height: 10),
                Text(
                  'Ace Your Radiation Health and Safety Exam',
                  textAlign: TextAlign.center,
                  style: textStyles.body.copyWith(
                    color: colors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
