import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dynamic_type_probe.dart' show ProbeViewport;

/// Text scale presets every golden test in the matrix is rendered at.
///
/// [ax5] reuses `dynamic_type_test.dart`'s own established proxy (4.0x,
/// not a literal reading of iOS's "Accessibility5" category name) for
/// the largest Dynamic Type accessibility size — see that file's doc
/// comment for why a flat 3.0x undershoots what real devices render at
/// that category. Golden coverage at the same scale that suite already
/// treats as authoritative keeps the two forms of regression protection
/// (pixel-diff here, overflow/exception there) aimed at the same target
/// instead of silently drifting apart.
enum GoldenTextScale {
  normal(1.0, 'normal'),
  ax5(4.0, 'ax5');

  const GoldenTextScale(this.scale, this.label);
  final double scale;
  final String label;
}

/// Pumps [child] for a golden-image comparison under fully controlled
/// conditions — every axis a golden test is sensitive to is pinned
/// explicitly, rather than left to whatever a given machine happens to
/// default to:
///
/// - **Device**: [ProbeViewport.smallPhone] (375x667, iPhone SE-class),
///   the same reference viewport `dynamic_type_test.dart` already probes
///   layout against, at a fixed `devicePixelRatio` of 1 — pinned
///   explicitly (not left at whatever `flutter_test`'s own default
///   happens to be) so the golden image's pixel dimensions can never
///   shift out from under it if that framework default ever changes.
/// - **Font**: the real, vendored Roboto — `test/flutter_test_config.dart`
///   already loads it globally, for every test in this suite, golden or
///   not (see that file's own doc comment). Golden tests need nothing
///   further here; this comment exists so that dependency is visible
///   from the golden tests themselves, not just discoverable by reading
///   unrelated test-support code.
/// - **Locale**: pinned explicitly to `en_US` — the app's only supported
///   locale today, but pinned rather than left implicit so a golden
///   image is never silently sensitive to whatever locale a given
///   machine's test environment happens to default to.
/// - **Motion**: disabled (`disableAnimations: true`) — a golden image is
///   a single frame; mid-transition it would be arbitrary which frame
///   that was.
/// - **Theme + text scale**: whichever [theme]/[textScale] the caller
///   asks for.
///
/// Cross-platform note: golden images in this repo were generated on
/// macOS (Flutter 3.41.2, matching CI's pinned version exactly — see
/// `.github/workflows/ci.yml`), since this development environment has
/// no Linux host to generate them on directly. All of the above is
/// controlled specifically to minimize (real font, fixed device/DPI,
/// fixed locale, no mid-animation frames) — but Skia's software
/// rasterizer can still theoretically differ in subpixel anti-aliasing
/// between platform builds of the Flutter engine. See
/// `test/golden/README.md` for what to do if CI's Linux runner ever
/// produces a genuine mismatch against these macOS-generated baselines.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  required ThemeData theme,
  required GoldenTextScale textScale,
}) async {
  tester.view.physicalSize = ProbeViewport.smallPhone.size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale.scale),
        disableAnimations: true,
      ),
      child: MaterialApp(
        theme: theme,
        locale: const Locale('en', 'US'),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Builds the golden file path for one matrix cell, keeping every golden
/// test's path construction identical (and therefore the directory
/// listing self-describing) rather than each test composing its own.
String goldenPath({
  required String screen,
  required Brightness brightness,
  required GoldenTextScale textScale,
}) {
  final String theme = brightness == Brightness.dark ? 'dark' : 'light';
  return 'goldens/$screen.$theme.${textScale.label}.png';
}
