# Current progress / Home verification — September 13, 2026

Base: current main `1727a59` (merged PR #73), re-fetched before delivery.
Branch: `feature/current-progress-home`. No hosted workflows dispatched; commit
and PR use `[skip ci]`. No merge, migration, content approval or history deletion.

## Behavior

- Home: navy Your progress card, unique Correct / Needs review, daily correct
  attempts, compact exam-date link; exactly five ordered activity tiles.
- Practise questions still launches **one random question**. Topic selection,
  saved questions, current mistakes and mock exams retain their real routes.
- Quick 10 / Timed quiz tiles removed; persisted sessions still resume, including
  historical planned and diagnostic sessions and their saved answer permutations.
- MainShell has only Home / Progress. Legacy restored tab IDs 1/2 go to Home;
  Progress retains persisted ID 3. Exiting/finishing practice or mock returns Home.
- Progress has available-bank and all-subject counts, labelled segmented bars,
  daily activity (newest first) and retained completed-mock history.
- [Aggregation rules](../PROGRESS_AGGREGATION.md) document insertion order,
  local-day fallback, attempt deduplication and mock limitations. Aggregate-only
  mock answers with no subsequent reliable grade are explicitly Grade unavailable,
  not fabricated Correct / Needs review / Not attempted values.

## Reproductions and regression coverage

Before UI integration, `a later correction removes the current review mistake`
failed: no "No mistakes to review" after a wrong answer followed by a correction.
It passes after Home and the launcher consume LearningProgress.

The full demo mock return path also exposed a Navigator `_debugLocked` assertion
when resetting busy parent routes; the completed-flow guards/pop callbacks were
corrected. The real-composition regression now exits a mock to Home, resumes the
same attempt/order, completes it and returns Home without extra pops.

New tests cover wrong→correct and correct→wrong at equal timestamps, persisted
order when the clock moves backwards, unique/current versus repeated/daily
counts, a changed current key, removed content, local midnight and legacy dates,
SQLite close/reopen plus idempotent retry, empty history, read-error Retry,
completed mock deduplication, partial imported grades, active-mock non-disclosure,
Home/Progress/subject/review consistency, exactly five activities, and legacy timed
resume. Existing two-tab, dynamic type, onboarding, saved-answer, access-limit,
100%-summary and full composition tests were updated for the intended navigation.

## Executed checks

Authoritative local Linux VM: Flutter 3.41.2 / Dart 3.11.0.

- Format: `Formatted 259 files (0 changed)`.
- Full `flutter test`: `01:17 +1073 ~1: All tests passed!` (one existing skip).
- Product and profile demo-entrypoint guard: each `+1: All tests passed!`.
- Content `--report`: structurally valid, 0 errors, 0 warnings; 26 awaiting
  human review, 0 approved. Diagnostic preflight remains FAIL for the unchanged
  insufficient approved bank. This is not content approval.
- `flutter analyze`: `No issues found! (ran in 1.9s)`.
- Source parity: all 305 Dart/PNG files in lib/test/tool match the tested VM.
  Sorted path/content manifest SHA-256:
  `f6657b725d18f222dfd28b80da2a460141e2e60d25fd8f5be9c12bea4e28e0a4`.
- `git diff --check`: clean.

The initial macOS full run correctly failed Linux pixel baselines and obsolete
four-tab/old-progress assertions. Those results are not reported as passes.
Behavioral tests were corrected for the requested behavior; Linux baselines were
updated only for inspected intentional changes. Final full regression includes
all 46 golden cases with unchanged exact comparison rules.

## Visual inspection and device limitations

Opened actual Flutter-rendered PNGs for Home and Progress in light/dark themes,
normal and AX5 (4x) text, including scrolled counters. Repaired oversized Progress
heading/legend wrapping and gave Correct and Needs review distinct existing
success/warning colors, with visible text labels independent of color.

| View | Light | Dark |
| --- | --- | --- |
| Home | [render](../../test/golden/goldens/home.light.normal.png) | [render](../../test/golden/goldens/home.dark.normal.png) |
| Home with exam date | [render](../../test/golden/goldens/planned_home.light.normal.png) | [render](../../test/golden/goldens/planned_home.dark.normal.png) |
| Progress | [render](../../test/golden/goldens/progress.light.normal.png) | [render](../../test/golden/goldens/progress.dark.normal.png) |
| Home AX5 counters | [render](../../test/golden/goldens/home_current_counts.light.ax5.png) | [render](../../test/golden/goldens/home_current_counts.dark.ax5.png) |
| Progress AX5 counts | [render](../../test/golden/goldens/progress_current_counts.light.ax5.png) | [render](../../test/golden/goldens/progress_current_counts.dark.ax5.png) |

These are local Flutter test renders at 375×667, not native screenshots. The test
font harness renders icon glyphs as squares; actual icon artwork was not verified
on a device. The normal demo fixture intentionally includes old aggregate-only
mock records; the extra counter fixtures use isolated graded attempts.

A preliminary `flutter run -d <iPhone 16 simulator> -t tool/main_home_preview.dart`
built in 20.7 s and connected a Dart VM service. Native visual inspection was
blocked twice because the Mac was locked. The final `flutter run --no-resident`
attempt could no longer discover that simulator (only macOS and Chrome found);
CoreSimulator also rejected a cleanup request. No final native screenshot,
physical-iPhone verification, VoiceOver session or release iOS build is claimed.

After unlocking the Mac and starting the simulator, run
`flutter run -t tool/main_home_preview.dart` to review the isolated preview.
Check native icons, VoiceOver reading order, safe areas and the real text-size
settings. Production questions remain gated; fixtures do not alter production.
