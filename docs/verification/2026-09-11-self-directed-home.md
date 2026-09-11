# Self-directed Home and shorter onboarding

Base: `61568b7994149c4de3f8a47cf52e8d2f51125786` on `main`.
`origin/feature/home-study-refresh` initially pointed to exactly the same commit;
there was no implementation on that branch. Work stays on that feature branch.

## Delivered behavior

- Calendar, availability and self-assessment screens, Home previews, daily-goal
  panels and daily allocation engine removed. Session summary returns to Home.
- Home rebuilt around one Start/Continue action, recorded answer statistics and
  compact saved-question, progress, practice-filter and optional-check links.
  Empty content does not create a goal or fabricate accuracy. Storage failure
  shows Retry rather than a new/empty session. Concurrent launcher taps are guarded.
- Onboarding is Welcome → timeframe → optional question check → Home. Profile and
  completion writes are retryable. App reconstruction keeps completed onboarding,
  saved diagnostic answers and answer order. No experience is invented.
- Optional diagnostic retained because its atomic answer transactions update
  question states used by Progress, incorrect-question practice and My weak areas.
  It does not estimate passing probability or assign a skill level. UI now uses
  the shared answer tiles, selected state, progress indicator and per-domain result.
- An empty-bank regression failed first because the diagnostic passed a zero
  requested count to the generator, misclassifying no material as a read failure.
  After the guarded count fix, it passes with unavailable material and Skip, no
  Retry and no created session. Technical read/start/write failures still retry.

## Data and scope

Schema remains 5, with no migration, deletion or reset. Existing histories,
feedback snapshots, answer permutations, legacy planned sessions, availability
JSON and calendar rows are preserved. New profiles represent missing experience
as nullable domain data and an explicit `notCollected` storage marker in the
existing text column. Known legacy experience values still round-trip.

Free allowances and the UTC daily reset are unchanged. Existing mock-reservation
expiry/access rules still read old schedule rows; no new calendar work is created.
No production/candidate content, approvals, validator thresholds, payment code,
workflow files or dependencies were changed.

## Actual checks

Local Linux: Lima `rhs-check`, Ubuntu 24.04 aarch64, Flutter 3.41.2, Dart 3.11.0.

- `dart format --output=none --set-exit-if-changed lib test tool`:
  `Formatted 251 files (0 changed)`.
- `flutter analyze`: `No issues found!`.
- Full `flutter test`: `02:17 +1034 ~1: All tests passed!`, exit 0. The one
  conditional demo-mode test is skipped in debug and was run separately below.
- `dart run tool/validate_candidate_questions.dart --report`: structurally valid,
  0 errors, 0 warnings, exit 0. Diagnostic preflight remains FAIL: zero approved
  questions (required 7/4/4 by domain). Structural validity is not clinical approval.
- Demo mode guard with `--dart-define=dart.vm.product=true`: 1 passed, exit 0;
  with `--dart-define=dart.vm.profile=true`: 1 passed, exit 0.
- SHA-256 comparison of all Dart sources and PNG renders in `lib/test/tool`:
  local PR tree matches the Linux-tested tree exactly.
- Targeted host regressions: 67 passed; shortened onboarding/retry/restart subset:
  22 passed; Home and diagnostic 320×568 / 4× text tests: 9 passed. These were
  intermediate checks, followed by the complete Linux run for the delivered code.
- Empty-bank red-before-green: 1 failure reproduced, then 1 test passed.
- Golden regeneration: 42 captures; the following ordinary full test run uses
  exact comparison. Comparator, fonts, viewport and scale are unchanged. Removed
  four calendar/plan captures and added four diagnostic selection/result captures.
- `git diff --check`: clean.

Obsolete calendar-allocation and removed-selector tests were replaced by current
flow regressions. Historical storage, review evidence, answer-order, free-limit,
transactional-save, mistake-review and reset tests remain in the full suite.
No hosted Actions were requested; the commit and PR title use `[skip ci]`.

## Visual review

These are real widget-test renders, **not** simulator or physical-iPhone captures.
The shared test harness has placeholder icon glyphs and a debug banner. Sixteen
changed/new renders were inspected across both themes. The first AX5 render broke
headline words; the responsive heading role was adjusted and inspected again.
Both themes also have interaction tests selecting and saving a diagnostic answer
at 4× text on a 320×568 viewport.

- [Home with history, light](../../test/golden/goldens/home.light.normal.png)
- [Home with history, dark](../../test/golden/goldens/home.dark.normal.png)
- [Home without history](../../test/golden/goldens/planned_home.light.normal.png)
- [Home at AX5](../../test/golden/goldens/home.light.ax5.png)
- [Diagnostic question](../../test/golden/goldens/diagnostic_question.light.normal.png)
- [Selected answer](../../test/golden/goldens/diagnostic_selected.light.normal.png)
- [Diagnostic result](../../test/golden/goldens/diagnostic_result.light.normal.png)
- [Session summary](../../test/golden/goldens/daily_result_done.light.normal.png)
- [Settings](../../test/golden/goldens/settings.light.normal.png)

Native simulator/device execution, VoiceOver gestures on hardware and an iOS build
were not performed for this change. Do not interpret widget renders as native QA.
For iPhone verification run `flutter run -t tool/main_study_preview.dart`, select
an iOS device/simulator, and check timeframe → skip/complete/resume check → Home →
practice → result, including background/resume and accessibility text. The preview
uses isolated synthetic fixtures and temporary repositories; production still has
no approved bank. No draft was promoted to make the diagnostic available.

## Rollback

Revert the PR commit. Stored history is unchanged. An older app interprets an
unknown legacy experience string using its old fallback; reverting code does not
turn `notCollected` into a genuine user answer. Keep the nullable reader if that
older UI is restored. No destructive data rollback is needed.
