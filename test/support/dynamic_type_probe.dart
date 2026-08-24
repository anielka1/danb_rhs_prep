import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Named viewport sizes used to probe Dynamic Type layouts. The app
/// declares iPad support (`TARGETED_DEVICE_FAMILY = "1,2"`), so iPad is a
/// real target, not a hypothetical one.
class ProbeViewport {
  const ProbeViewport(this.label, this.size);

  final String label;
  final Size size;

  static const ProbeViewport smallPhone =
      ProbeViewport('small iPhone (iPhone SE)', Size(375, 667));
  static const ProbeViewport largePhone =
      ProbeViewport('large iPhone (iPhone Pro Max)', Size(430, 932));
  static const ProbeViewport ipad = ProbeViewport('iPad', Size(810, 1080));

  // Phase 2 exit-criteria viewport spec (docs/DANB_RHS_APP_STORE_ROADMAP.md):
  // approximate logical sizes for a small iPhone, a large iPhone, and iPad
  // portrait. Named separately from the sizes above (which predate this
  // spec and are already the basis of a large passing test suite) rather
  // than changed in place.
  static const ProbeViewport exitCriteriaSmallPhone =
      ProbeViewport('small iPhone (320x568)', Size(320, 568));
  static const ProbeViewport exitCriteriaLargePhone = largePhone;
  static const ProbeViewport exitCriteriaIpad =
      ProbeViewport('iPad portrait (834x1194)', Size(834, 1194));

  @override
  String toString() => label;
}

/// Pumps [app] with the test view resized to [viewport] (the real layout
/// constraints screens are measured against) and an ancestor [MediaQuery]
/// forcing [textScale] (using the current, non-deprecated [TextScaler]
/// API — never `textScaleFactor`). Settles all animations, then asserts
/// nothing (e.g. a `RenderFlex` overflow) was thrown.
///
/// Deliberately does *not* clamp text scaling — that would hide real
/// overflow bugs instead of catching them.
Future<void> pumpAtScale(
  WidgetTester tester,
  Widget app, {
  required ProbeViewport viewport,
  required double textScale,
}) async {
  final double dpr = tester.view.devicePixelRatio;
  tester.view.physicalSize =
      Size(viewport.size.width * dpr, viewport.size.height * dpr);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: app,
    ),
  );
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull,
      reason:
          'unexpected overflow/exception at ${textScale}x on ${viewport.label}');
}
