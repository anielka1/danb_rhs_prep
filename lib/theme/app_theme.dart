import 'package:flutter/material.dart';

/// Spacing tokens used for padding, gaps and margins across the app.
/// Values match the roadmap's approved spacing scale; use the named
/// constant that matches your layout's intent rather than a raw number.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  /// Horizontal padding applied to every screen's scrollable content.
  static const double screenPadding = xxl;
}

/// Corner-radius tokens for containers, chips, buttons and avatars.
class AppRadii {
  AppRadii._();

  static const double card = 26;
  static const double pill = 32;
  static const double button = 20;
  static const double avatar = 100;
  static const double smallIcon = 16;
}

/// Elevation tokens for surfaces that intentionally lift off the
/// background. The prototype's buttons and cards are deliberately flat
/// (elevation none); dialogs need to visibly separate from the page.
class AppElevation {
  AppElevation._();

  static const double none = 0;
  static const double card = 2;
  static const double dialog = 8;
}

/// Icon sizes used across nav items, badges and inline glyphs.
class AppIconSize {
  AppIconSize._();

  static const double small = 16;
  static const double medium = 20;
  static const double standard = 24;
  static const double large = 28;
}

/// Border widths used for outlines, focus rings and selection borders.
class AppBorderWidth {
  AppBorderWidth._();

  static const double thin = 1;
  static const double regular = 2;
  static const double thick = 2;
}

/// Minimum interactive control size, matching Apple's Human Interface
/// Guidelines 44x44pt tap-target requirement (also satisfies Material's
/// accessible tap-target guidance).
class AppTapTarget {
  AppTapTarget._();

  static const double minInteractive = 44;
}

/// Shadow color for `BoxShadow`s (e.g. the avatar and selected-pill
/// shadows on the login and profile screens). Deliberately invariant
/// across light/dark themes — unlike every other color in this file it
/// has no separate light/dark value, because it represents physical light
/// occlusion, not a surface/text/icon role that should flip with theme
/// brightness. Callers apply their own alpha via `.withValues(alpha: ...)`
/// for the shadow's intensity.
class AppShadowColors {
  AppShadowColors._();

  static const Color base = Colors.black;
}

/// App-specific semantic colors that Material's [ColorScheme] has no
/// dedicated role for (success/warning aren't part of the Material color
/// system), plus a couple of prototype accents that don't map cleanly onto
/// any standard role. Every field has an intentional, non-inverted light
/// and dark value defined in [AppTheme].
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.accent,
    required this.mutedForeground,
  });

  /// Foreground success color (badges, correct-answer icons).
  final Color success;

  /// Text/icon color to place on top of [success].
  final Color onSuccess;

  /// Soft success background (e.g. the "Passed" pill, correct-answer card).
  final Color successContainer;

  /// Text/icon color to place on top of [successContainer].
  final Color onSuccessContainer;

  /// Foreground warning color. Not yet used by any screen, but required by
  /// the roadmap as a first-class semantic role alongside success/error.
  final Color warning;

  /// Text/icon color to place on top of [warning].
  final Color onWarning;

  /// Soft warning background.
  final Color warningContainer;

  /// Text/icon color to place on top of [warningContainer].
  final Color onWarningContainer;

  /// The single playful highlight color (day-streak flame). Intentionally
  /// distinct from [warning]: it signals a positive streak, not caution.
  final Color accent;

  /// Muted foreground color for de-emphasized UI: decorative/disabled
  /// icons (locked-topic icon, chevrons) and small inactive labels (the
  /// bottom nav's unselected tab text). Named for both roles since it's
  /// rendered as text, not just icons. Merges the prototype's
  /// near-identical `lockedGrey`/`textMuted` tones into one role.
  final Color mutedForeground;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? accent,
    Color? mutedForeground,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      accent: accent ?? this.accent,
      mutedForeground: mutedForeground ?? this.mutedForeground,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      accent: Color.lerp(accent, other.accent, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
    );
  }

  // Semantic status colors remain distinct from the blue action palette.
  static const AppSemanticColors light = AppSemanticColors(
    success: Color(0xFF257D46),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFE3F6EA),
    onSuccessContainer: Color(0xFF2A7A4B),
    warning: Color(0xFFB0700E),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFBF0DD),
    onWarningContainer: Color(0xFF7A4E0A),
    accent: Color(0xFFD85A3D),
    mutedForeground: Color(0xFF606B85),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: Color(0xFF6FCB94),
    onSuccess: Color(0xFF0F2118),
    successContainer: Color(0xFF1E3A2C),
    onSuccessContainer: Color(0xFF8FE0AE),
    warning: Color(0xFFE0A94D),
    onWarning: Color(0xFF2B1D06),
    warningContainer: Color(0xFF3D2C10),
    onWarningContainer: Color(0xFFF0CE94),
    accent: Color(0xFFFF9270),
    mutedForeground: Color(0xFFB5BED5),
  );
}

/// Central place for every semantic color, text style, radius, spacing and
/// tap-target value used across the DANB RHS Prep app. Colors are grouped
/// into light and dark [ColorScheme]s plus [AppSemanticColors]; nothing in
/// this file hardcodes a "which theme is active" assumption, so screens
/// must read colors from `Theme.of(context)` (see the `BuildContext`
/// extension below) rather than from static constants.
class AppTheme {
  AppTheme._();

  // Blue/lavender palette: airy surfaces, saturated actions and navy ink.
  static const ColorScheme _lightScheme = ColorScheme.light(
    brightness: Brightness.light,
    primary: Color(0xFF4659DB),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEEF0FF),
    onPrimaryContainer: Color(0xFF4659DB),
    secondary: Color(0xFF4659DB),
    onSecondary: Color(0xFFFFFFFF),
    error: Color(0xFFC03E3E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFBE7E7),
    onErrorContainer: Color(0xFFB83D3D),
    surface: Color(0xFFF7F9FF),
    onSurface: Color(0xFF19223D),
    surfaceContainer: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFF606B85),
    outline: Color(0xFFE8ECF7),
    outlineVariant: Color(0xFFE8ECF7),
  );

  // Dark surfaces retain the same blue identity with brighter actions.
  static const ColorScheme _darkScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: Color(0xFFB3BEFF),
    onPrimary: Color(0xFF17204E),
    primaryContainer: Color(0xFF2B3565),
    onPrimaryContainer: Color(0xFFDDE3FF),
    secondary: Color(0xFFB3BEFF),
    onSecondary: Color(0xFF17204E),
    error: Color(0xFFE98080),
    onError: Color(0xFF3B1414),
    errorContainer: Color(0xFF4A2432),
    onErrorContainer: Color(0xFFF3B4B4),
    surface: Color(0xFF13192C),
    onSurface: Color(0xFFF1F4FF),
    surfaceContainer: Color(0xFF202941),
    onSurfaceVariant: Color(0xFFB5BED5),
    outline: Color(0xFF56617D),
    outlineVariant: Color(0xFF34405E),
  );

  static ThemeData get lightTheme =>
      _build(_lightScheme, AppSemanticColors.light);

  static ThemeData get darkTheme => _build(_darkScheme, AppSemanticColors.dark);

  static ThemeData _build(ColorScheme colorScheme, AppSemanticColors semantic) {
    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [semantic],
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: AppBorderWidth.thin,
        space: AppBorderWidth.thin,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: AppBorderWidth.thick,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        // The thumb stays a constant contrasting surface color in both
        // on/off states, matching the prototype; the track switches
        // between the primary and primary-container roles when enabled.
        // A disabled switch (no backing feature yet — see
        // ProfileSettingsScreen's Push Notifications/Sound Effects rows)
        // falls back to the same `mutedForeground` role already used to
        // dim disabled *text* elsewhere on that screen: without this, the
        // track kept its full-vividness "on" color even when disabled,
        // so a permanently-off preference was visually indistinguishable
        // from a real, tappable, currently-enabled control.
        thumbColor: WidgetStateProperty.all(colorScheme.surfaceContainer),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return semantic.mutedForeground.withValues(alpha: 0.35);
          }
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.primaryContainer;
        }),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            AppTapTarget.minInteractive,
            AppTapTarget.minInteractive,
          ),
          foregroundColor: colorScheme.onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: AppElevation.card,
          shadowColor: colorScheme.primary.withValues(alpha: 0.22),
          minimumSize: const Size(
            double.infinity,
            AppTapTarget.minInteractive,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          minimumSize: const Size(
            double.infinity,
            AppTapTarget.minInteractive,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.secondary,
          minimumSize: const Size(
            AppTapTarget.minInteractive,
            AppTapTarget.minInteractive,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: AppElevation.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        elevation: AppElevation.dialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
    );
  }
}

/// Colorless, reusable type-scale definitions. These never bake in a
/// color, since the correct color depends on which theme brightness is
/// active — call [AppTextStyles.of] to get a copy with the current theme's
/// semantic text colors applied.
class AppTextStyles {
  const AppTextStyles._({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.body,
    required this.bodySmall,
    required this.label,
    required this.button,
    required this.statNumber,
  });

  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle body;
  final TextStyle bodySmall;
  final TextStyle label;
  final TextStyle button;
  final TextStyle statNumber;

  static const TextStyle _h1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle _h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const TextStyle _h3 =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
  static const TextStyle _body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  static const TextStyle _bodySmall =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
  static const TextStyle _label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );
  static const TextStyle _button =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
  static const TextStyle _statNumber =
      TextStyle(fontSize: 30, fontWeight: FontWeight.w700);

  /// Resolves every named style against the active theme's semantic text
  /// colors. Headlines and stat numbers use [ColorScheme.onSurface]
  /// (primary text); body/label copy uses [ColorScheme.onSurfaceVariant]
  /// (secondary text); [button] uses [ColorScheme.onPrimary], since it is
  /// only ever drawn on a primary-colored button background.
  static AppTextStyles of(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppTextStyles._(
      h1: _h1.copyWith(color: colorScheme.onSurface),
      h2: _h2.copyWith(color: colorScheme.onSurface),
      h3: _h3.copyWith(color: colorScheme.onSurface),
      body: _body.copyWith(color: colorScheme.onSurfaceVariant),
      bodySmall: _bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
      label: _label.copyWith(color: colorScheme.onSurfaceVariant),
      button: _button.copyWith(color: colorScheme.onPrimary),
      statNumber: _statNumber.copyWith(color: colorScheme.onSurface),
    );
  }
}

/// Convenience accessors so screens can write `context.colors.primary`
/// and `context.semanticColors.success` instead of the more verbose
/// `Theme.of(context).colorScheme...` / `...extension<AppSemanticColors>()`.
extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;

  AppTextStyles get textStyles => AppTextStyles.of(this);

  /// Respects the system Reduce Motion preference: returns [Duration.zero]
  /// when [MediaQuery.disableAnimations] is set, so an `AnimatedContainer`
  /// (or similar implicit animation) jumps straight to its end state
  /// instead of animating, and [duration] unchanged otherwise.
  Duration reducedMotionDuration(Duration duration) =>
      MediaQuery.of(this).disableAnimations ? Duration.zero : duration;
}
