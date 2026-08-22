import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';

/// WCAG 2.x relative luminance of an sRGB color, using the new
/// component-as-double [Color] API (`.r`/`.g`/`.b`, 0.0-1.0) rather than
/// the deprecated 8-bit `.red`/`.green`/`.blue` getters.
double _relativeLuminance(Color color) {
  double linear(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linear(color.r) +
      0.7152 * linear(color.g) +
      0.0722 * linear(color.b);
}

/// WCAG contrast ratio between two colors; 1.0 (none) to 21.0 (max).
double _contrastRatio(Color a, Color b) {
  final double la = _relativeLuminance(a) + 0.05;
  final double lb = _relativeLuminance(b) + 0.05;
  return la > lb ? la / lb : lb / la;
}

void main() {
  group('brightness', () {
    test('light theme has Brightness.light', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
      expect(AppTheme.lightTheme.colorScheme.brightness, Brightness.light);
    });

    test('dark theme has Brightness.dark', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
      expect(AppTheme.darkTheme.colorScheme.brightness, Brightness.dark);
    });
  });

  group('semantic colors', () {
    test('AppSemanticColors extension is present in both themes', () {
      expect(AppTheme.lightTheme.extension<AppSemanticColors>(), isNotNull);
      expect(AppTheme.darkTheme.extension<AppSemanticColors>(), isNotNull);
    });

    test('dark values are not naive inversions or copies of light values', () {
      final light = AppTheme.lightTheme.extension<AppSemanticColors>()!;
      final dark = AppTheme.darkTheme.extension<AppSemanticColors>()!;

      // Every semantic role must have its own intentional dark value.
      expect(dark.success, isNot(equals(light.success)));
      expect(dark.warning, isNot(equals(light.warning)));
      expect(dark.accent, isNot(equals(light.accent)));
      expect(dark.mutedForeground, isNot(equals(light.mutedForeground)));

      // A naive invert of the light background would be a near-black,
      // desaturated color; the real dark background is a deliberate navy.
      // Contrast ratio alone can't distinguish this (both are low-luminance
      // colors), so compare RGB channels directly instead.
      final lightSurface = AppTheme.lightTheme.colorScheme.surface;
      final naiveInvert = Color.from(
        alpha: 1,
        red: 1 - lightSurface.r,
        green: 1 - lightSurface.g,
        blue: 1 - lightSurface.b,
      );
      final darkSurface = AppTheme.darkTheme.colorScheme.surface;
      final channelDistance = math.sqrt(
        math.pow(darkSurface.r - naiveInvert.r, 2) +
            math.pow(darkSurface.g - naiveInvert.g, 2) +
            math.pow(darkSurface.b - naiveInvert.b, 2),
      );
      expect(
        channelDistance,
        greaterThan(0.05),
        reason: 'dark surface should not equal an inverted light surface',
      );
    });

    test('dark primary is lightened, not identical to the light primary', () {
      // The dark scheme brightens `primary` so it still reads clearly
      // against a dark background, instead of reusing the light value.
      final lightPrimaryLuminance =
          _relativeLuminance(AppTheme.lightTheme.colorScheme.primary);
      final darkPrimaryLuminance =
          _relativeLuminance(AppTheme.darkTheme.colorScheme.primary);
      expect(darkPrimaryLuminance, greaterThan(lightPrimaryLuminance));
    });
  });

  group('contrast', () {
    // WCAG 2.x: 4.5:1 is the floor for normal-size text. 3:1 only applies
    // to large text (>=24px, or >=19px bold) or non-text UI components
    // (icons, borders) — every 3:1 call below is annotated with which of
    // those two exceptions applies at its actual call site in the app.
    void expectReadable(String label, Color foreground, Color background,
        {double minRatio = 4.5}) {
      final ratio = _contrastRatio(foreground, background);
      expect(
        ratio,
        greaterThanOrEqualTo(minRatio),
        reason:
            '$label contrast ratio was ${ratio.toStringAsFixed(2)}, need >= $minRatio',
      );
    }

    test('light theme: normal-size text pairs meet the 4.5:1 floor', () {
      final scheme = AppTheme.lightTheme.colorScheme;
      final semantic = AppTheme.lightTheme.extension<AppSemanticColors>()!;
      expectReadable('onSurface on surface', scheme.onSurface, scheme.surface);
      expectReadable('onSurfaceVariant on surface', scheme.onSurfaceVariant,
          scheme.surface);
      expectReadable('onSurface on surfaceContainer', scheme.onSurface,
          scheme.surfaceContainer);
      expectReadable('onPrimary on primary', scheme.onPrimary, scheme.primary);
      expectReadable('onError on error', scheme.onError, scheme.error);
      expectReadable('error as text on surface', scheme.error, scheme.surface);
      expectReadable(
          'secondary as text on surface', scheme.secondary, scheme.surface);
      expectReadable(
          'success as text on surface', semantic.success, scheme.surface);
      expectReadable('mutedForeground as nav-label text on surface',
          semantic.mutedForeground, scheme.surface);
      expectReadable('onPrimaryContainer on primaryContainer',
          scheme.onPrimaryContainer, scheme.primaryContainer);
      expectReadable('onErrorContainer on errorContainer',
          scheme.onErrorContainer, scheme.errorContainer);
      expectReadable('onSuccessContainer on successContainer',
          semantic.onSuccessContainer, semantic.successContainer);
      expectReadable('onWarningContainer on warningContainer',
          semantic.onWarningContainer, semantic.warningContainer);
    });

    test('light theme: large-text/non-text exceptions meet the 3:1 floor', () {
      final scheme = AppTheme.lightTheme.colorScheme;
      final semantic = AppTheme.lightTheme.extension<AppSemanticColors>()!;
      // 24px bold stat number ("12" day streak) — WCAG large text.
      expectReadable('accent as large stat-number text on surface',
          semantic.accent, scheme.surface,
          minRatio: 3);
      // Checkmark glyph only, never rendered as text.
      expectReadable(
          'onSuccess icon on success', semantic.onSuccess, semantic.success,
          minRatio: 3);
    });

    test('dark theme: normal-size text pairs meet the 4.5:1 floor', () {
      final scheme = AppTheme.darkTheme.colorScheme;
      final semantic = AppTheme.darkTheme.extension<AppSemanticColors>()!;
      expectReadable('onSurface on surface', scheme.onSurface, scheme.surface);
      expectReadable('onSurfaceVariant on surface', scheme.onSurfaceVariant,
          scheme.surface);
      expectReadable('onSurface on surfaceContainer', scheme.onSurface,
          scheme.surfaceContainer);
      expectReadable('onPrimary on primary', scheme.onPrimary, scheme.primary);
      expectReadable('onError on error', scheme.onError, scheme.error);
      expectReadable('error as text on surface', scheme.error, scheme.surface);
      expectReadable(
          'secondary as text on surface', scheme.secondary, scheme.surface);
      expectReadable(
          'success as text on surface', semantic.success, scheme.surface);
      expectReadable('mutedForeground as nav-label text on surface',
          semantic.mutedForeground, scheme.surface);
      expectReadable('onPrimaryContainer on primaryContainer',
          scheme.onPrimaryContainer, scheme.primaryContainer);
      expectReadable('onErrorContainer on errorContainer',
          scheme.onErrorContainer, scheme.errorContainer);
      expectReadable('onSuccessContainer on successContainer',
          semantic.onSuccessContainer, semantic.successContainer);
      expectReadable('onWarningContainer on warningContainer',
          semantic.onWarningContainer, semantic.warningContainer);
    });

    test('dark theme: large-text/non-text exceptions meet the 3:1 floor', () {
      final scheme = AppTheme.darkTheme.colorScheme;
      final semantic = AppTheme.darkTheme.extension<AppSemanticColors>()!;
      expectReadable('accent as large stat-number text on surface',
          semantic.accent, scheme.surface,
          minRatio: 3);
      expectReadable(
          'onSuccess icon on success', semantic.onSuccess, semantic.success,
          minRatio: 3);
    });
  });

  group('typography', () {
    test('theme does not declare the removed unbundled font family', () {
      // ThemeData's own Material typography default ("Roboto") is expected
      // here — it's Flutter's built-in default and gracefully falls back to
      // the platform's system font where Roboto isn't installed (e.g. iOS).
      // What must never come back is the prototype's unbundled, unlicensed
      // "SF Pro Display" name, which had no corresponding font asset.
      expect(AppTheme.lightTheme.textTheme.bodyMedium?.fontFamily,
          isNot('SF Pro Display'));
      expect(AppTheme.darkTheme.textTheme.bodyMedium?.fontFamily,
          isNot('SF Pro Display'));
    });

    testWidgets(
        'AppTextStyles.of resolves colored styles with no fixed font family',
        (tester) async {
      late AppTextStyles styles;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              styles = AppTextStyles.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(styles.h1.fontFamily, isNull);
      expect(styles.body.fontFamily, isNull);
      expect(styles.h1.color, AppTheme.lightTheme.colorScheme.onSurface);
      expect(
          styles.body.color, AppTheme.lightTheme.colorScheme.onSurfaceVariant);
      expect(styles.button.color, AppTheme.lightTheme.colorScheme.onPrimary);
    });
  });

  group('token scale', () {
    test('spacing tokens match the approved 8-value scale', () {
      expect(
        [
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xxxl,
          AppSpacing.huge,
        ],
        [4, 8, 12, 16, 20, 24, 32, 40],
      );
    });

    test('minimum interactive tap target is 44 logical points', () {
      expect(AppTapTarget.minInteractive, 44);
    });
  });
}
