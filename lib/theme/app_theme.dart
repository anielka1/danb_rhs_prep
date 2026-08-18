import 'package:flutter/material.dart';

/// Central place for every color, text style, radius and spacing value
/// used across the DANB RHS Prep app, pulled from the source screenshots.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFFFBF8EC); // warm cream
  static const Color backgroundGradientEnd = Color(0xFFAEC0EE); // splash bottom fade
  static const Color card = Color(0xFFFFFFFF);
  static const Color lavenderContainer = Color(0xFFE3E8FA); // light lavender chip/box bg

  // Brand / primary
  static const Color primary = Color(0xFF8CA0E8); // periwinkle buttons
  static const Color primaryDark = Color(0xFF5D71C9); // pressed / accents
  static const Color navy = Color(0xFF3B4A8C); // headline text
  static const Color navyDeep = Color(0xFF2E3A73);

  // Text
  static const Color textPrimary = Color(0xFF3B4A8C);
  static const Color textSecondary = Color(0xFF8E96B8);
  static const Color textMuted = Color(0xFFB0B7D6);

  // Status
  static const Color success = Color(0xFF3FAE6B);
  static const Color successBg = Color(0xFFE3F6EA);
  static const Color error = Color(0xFFDD5353);
  static const Color errorBg = Color(0xFFFBE7E7);
  static const Color lockedGrey = Color(0xFF9AA0B4);

  // Misc
  static const Color divider = Color(0xFFE9E6D8);
  static const Color inputBorder = Color(0xFFE3DFCB);
  static const Color streakOrange = Color(0xFFEF6C4D);
}

class AppRadii {
  AppRadii._();
  static const double card = 20;
  static const double pill = 32;
  static const double button = 28;
  static const double avatar = 100;
  static const double smallIcon = 16;
}

class AppSpacing {
  AppSpacing._();
  static const double screenPadding = 24;
}

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'SF Pro Display';

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.navy,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.navy,
    height: 1.25,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.navy,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.6,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle statNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.navy,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        headlineSmall: AppTextStyles.h3,
        bodyMedium: AppTextStyles.body,
        labelLarge: AppTextStyles.label,
      ),
    );
  }
}
