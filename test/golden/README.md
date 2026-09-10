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

## Baseline platform

The current 32 images were generated on Ubuntu with Flutter 3.41.2 by
[update-goldens run 34518857290](https://github.com/anielka1/danb_rhs_prep/actions/runs/34518857290),
from commit `ee64f95c8f8a861c46536ec65a370ebc605d23c3`.
Artifact `10168811632` ZIP SHA-256:
`262d9bd093d48f50d2b7d6e4a9ab149b8ac1440aa4fc215e9775682719727570`.
All light/dark and normal/AX5 images were visually reviewed for the blue
palette, typography and welcome illustration redesign. At AX5, content
continues below the viewport through the existing scrollable layouts;
interaction tests remain the check for reaching controls below the fold.

Linux CI is authoritative for exact pixel comparisons. macOS rendering
produced differences across all 32 images despite the same Flutter version,
fonts and viewport. Do not replace these baselines with macOS output or
relax the comparator to hide those differences. Use the workflow below
for intentional UI changes, review its images, then commit them through a PR.
Local macOS runs can report golden mismatches; verify the committed images
with the Linux quality job before merging.

## Update procedure

**Prefer regenerating on Linux (matching what CI actually enforces),
not locally on a different OS:**

UI pull requests now generate the same `golden-images` review artifact automatically.
The workflow never writes baselines back; review and commit the intended changes.
Manual generation remains available:

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

Welcome illustration baselines were subsequently reviewed and updated from
Linux run `34520554520`, commit `60d0ead72206b20f45c9eca051c8cc49c6e1048a`,
artifact `10169486947` (ZIP SHA-256
`96903e812e6cdc344a76fe2cb7e5c8367e6f4be5666f79031102122908ca07c5`).
The illustration now uses explicit translucent layers instead of path-shadow
blur. The workflow verifies generated images in a fresh test process before
uploading them; the pixel comparator remains exact.

Home (light/dark × normal/AX5) and Settings (light/dark normal) baselines
were reviewed for the soft study-screen redesign from Linux run `34522797485`,
commit `25486975569577306a122f0e2457a7f6a9cf566a`, artifact `10170365672`.
ZIP SHA-256: `3cd7c151e23e7366dd40198bdef9f423114e212aca353453dbb9051f12682889`.
The other 26 images were byte-identical and remain unchanged.
