# Shared Settings theme and removal of the starting check

Base: `cf7fd9f` (current main including PR #74).
Branch: `feature/shared-theme-no-diagnostic`. No automatic merge or hosted
workflow dispatch. Commit and PR use `[skip ci]` for the zero-budget policy.

## Changes

Home no longer has an independent palette. `AppHomeColors` is removed; surfaces,
primary containers and their foregrounds, disabled icons and shadows use the same
ColorScheme as Settings. Other screens already used the shared theme and were
kept intact. Home's counts, five ordered tiles, two bottom tabs and Mock exam
remain. Semantic success/error/warning colors are unchanged.

The path is Welcome → exam timeframe → Home. Profile and onboarding completion
must save before entering Home; both failure paths retain Retry. DiagnosticScreen,
its imports, launchers and help text are removed. There is no replacement skip
question. Legacy enum values and historical answer processing remain readable.

Home and practice setup share `resumablePracticeSession`: an active diagnostic
is persisted as `abandoned`, retaining IDs, answer order, timestamps and all saved
answers. `completedAt` remains null. A failed retirement write propagates to the
existing Retry UI and does not permit a new session over the unresolved active
slot. Completed diagnostics are untouched; retired records remain in history.
No unattempted answer is synthesized. Schema 5, data, free limits and content
approval states are unchanged.

## Evidence

The new date → Home test failed against the original implementation for both
approved and draft-only content, then passed after removing the diagnostic step.
Targeted tests cover full bootstrap/restart, profile/completion write Retry,
Home retirement failure Retry and subsequent new practice, SQLite close/reopen
with partial/completed diagnostics, preserved answer order and historical grades,
and the existing full Mock exam flow. Theme tests use fresh app/bootstrap
instances with the same store to verify System/Light/Dark persistence and actual
Home surface/foreground colors. Existing controller/history recovery tests remain;
obsolete tests of the removed diagnostic UI are replaced by retirement coverage.

Final local Linux checks (Flutter 3.41.2 / Dart 3.11.0):
- Format: `Formatted 260 files (0 changed) in 0.75 seconds.`
- Analyze: `No issues found! (ran in 1.7s)`.
- Full test suite: `01:15 +1065 ~1: All tests passed!` (one existing skip),
  including all 40 golden cases.
- Candidate validator `--report`: structurally valid, 0 errors, 0 warnings;
  26 awaiting review, 0 approved. Its unchanged diagnostic pilot preflight
  reports FAIL; this legacy content report is not an app diagnostic entrypoint
  and was not altered to force readiness.
- `git diff --check`: clean.

The initial full run failed three obsolete Skip expectations and eight intentional
Home image changes. The Skip assertions were replaced with the new direct-Home
path; images were inspected before acceptance. The final results above are from
an independent full run after those changes.
Source parity: all 300 Dart/PNG files match the tested local Linux VM:
`83bff22f0ff79c8bf5761f3e39b46aaa5ddd5f6444938588be51e7b6f503f609`.

## Visual inspection

Opened actual Flutter-rendered Home images in both themes, normal and AX5 (4×)
text, with/without a date and with scrolled counters. Also opened Settings,
Progress and practice-question images in both themes. Eight intended Home
baselines were accepted after inspection. Six diagnostic images were removed
with their screen. Exact comparison rules and the remaining screen baselines
are unchanged; 40 golden cases remain.

| View | Light | Dark |
| --- | --- | --- |
| Home | [render](../../test/golden/goldens/home.light.normal.png) | [render](../../test/golden/goldens/home.dark.normal.png) |
| Dated Home | [render](../../test/golden/goldens/planned_home.light.normal.png) | [render](../../test/golden/goldens/planned_home.dark.normal.png) |
| Home AX5 | [render](../../test/golden/goldens/home_current_counts.light.ax5.png) | [render](../../test/golden/goldens/home_current_counts.dark.ax5.png) |
| Settings | [render](../../test/golden/goldens/settings.light.normal.png) | [render](../../test/golden/goldens/settings.dark.normal.png) |
| Progress | [render](../../test/golden/goldens/progress.light.normal.png) | [render](../../test/golden/goldens/progress.dark.normal.png) |
| Question | [render](../../test/golden/goldens/practice_question.light.normal.png) | [render](../../test/golden/goldens/practice_question.dark.normal.png) |

These are test renders at 375×667, not iPhone screenshots. The existing font
harness shows placeholder glyphs for icons; real icon artwork is not verified.
`flutter run -d B91AEAC1-C5D9-44A3-B950-66F6969213F7 -t tool/main_home_preview.dart`
could not discover the simulator (only macOS and Chrome were listed).
CoreSimulator also returned connection-invalid/refused errors. The visible
Simulator window contained the old app with its starting-check entry, so it was
not used as evidence for the changed build. No native run, screenshot, VoiceOver
inspection or iOS release build success is claimed for this change.

Once native tooling is available, run `flutter run -t tool/main_home_preview.dart`
and check real icon rendering, Settings theme switching, safe areas and VoiceOver.
