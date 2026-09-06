# Golden screenshot matrix (PREP-658)

`golden_matrix_test.dart` golden-tests one representative, meaningful
state of each of the 8 screens PREP-658 names — onboarding, Home,
Practice, feedback, Summary, Mock result, Progress, Settings — under
light/dark theme x normal/AX5 text scale (32 images total). See that
file's own doc comment for the exact screen -> state mapping and why
one state per screen, not every success/empty/error permutation.

## What's controlled, and how

Every axis a golden image is sensitive to is pinned explicitly rather
than left to whatever a given machine defaults to (see
`test/support/golden_probe.dart`'s `pumpGolden` for the implementation):

- **Font**: the real, vendored Roboto (`test/fonts/*.ttf`, Apache
  License 2.0), loaded globally for every test in this suite —
  golden or not — by `test/flutter_test_config.dart`. Not Flutter's
  synthetic fallback glyphs, and not whatever font a given OS happens
  to have installed.
- **Device / DPI**: a fixed 375x667 logical viewport (`ProbeViewport
  .smallPhone`, the same reference small phone `dynamic_type_test.dart`
  already probes layout against) at a fixed `devicePixelRatio` of 1.
- **Locale**: pinned to `en_US` — the app's only supported locale
  today, pinned explicitly rather than left implicit.
- **Motion**: disabled (`disableAnimations: true`) — a golden image is
  one frame; mid-transition it would be arbitrary which frame that was.
- **"Now"**: every screen with a live-clock dependency is given a fixed
  `now` (`HomeScreen`, `PracticeSessionController`, `MockExamController`
  all take an injectable `now` for exactly this reason — see each
  golden case's own fixture setup). `ProgressScreen`'s fixture data
  comes from `DebugDemoEnvironment`, which is fixed literals throughout
  (see that file's own doc comment) — never `DateTime.now()`.
- **Icons**: Material Icons render as generic placeholder squares in
  this suite (`flutter_test_config.dart` loads the real Roboto *text*
  font, not the separate Material Icons *glyph* font — a pre-existing
  characteristic of every test in this repo, not something specific to
  golden tests). Golden coverage here still catches real layout/color/
  spacing regressions; it just can't distinguish one icon shape from
  another.

## Known cross-platform risk

These baseline images were generated on macOS (Flutter 3.41.2 — pinned
to match `.github/workflows/ci.yml`'s `quality` job exactly), since
this repository's day-to-day development environment has no Linux host
to generate them on directly. `flutter test`'s golden comparison
(`matchesGoldenFile`) is an exact pixel match; even with every axis
above controlled, Skia's software rasterizer can theoretically differ
in subpixel anti-aliasing between the macOS and Linux (`ubuntu-latest`,
where CI's `quality` job actually runs and enforces these goldens)
builds of the Flutter engine.

**If CI fails on one of these goldens with a small, cosmetic pixel diff
(not a real layout/color regression)**: that's this risk materializing,
not a bug in the screen under test. Regenerate the goldens *on the same
platform CI enforces them on* — see the procedure below — rather than
re-generating locally on macOS again, which would just reproduce the
same mismatch.

## Update procedure

**Prefer regenerating on Linux (matching what CI actually enforces),
not locally on a different OS:**

1. Go to this repository's GitHub Actions tab -> `update-goldens`
   workflow -> "Run workflow" (manual `workflow_dispatch`, `main` or
   your branch).
2. It runs `flutter test --update-goldens test/golden/` on
   `ubuntu-latest` with the same pinned Flutter version as the
   `quality` job, then uploads the regenerated
   `test/golden/goldens/*.png` files as a build artifact (it does not
   push a commit itself — golden changes should still go through a
   reviewed PR, since a silently-updated visual baseline defeats the
   point of a regression test).
3. Download the artifact, replace `test/golden/goldens/` with its
   contents, and open a PR with the diff — the PR description should
   say *why* the goldens changed (an intentional visual change) so a
   reviewer isn't just asked to trust a pile of binary diffs.

**Local regeneration** (only when you're already on Linux, or
accepting the cross-platform risk above as a starting point to be
confirmed by CI):

```
flutter test --update-goldens test/golden/
```

Never hand-edit a golden PNG, and never regenerate goldens to make an
unrelated failing test pass — a golden diff means the rendered output
changed; confirm *why* before accepting the new baseline.
