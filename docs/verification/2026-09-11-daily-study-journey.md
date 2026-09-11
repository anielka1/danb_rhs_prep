# Daily study journey verification — 2026-09-11

Base: current `main` at `842dd1d`. Branch: `feature/daily-study-journey`.
All checks ran locally; no GitHub Actions were dispatched.

## Confirmed gaps and changes

- Regression before the policy fix: five 5-second answers produced a 5-second
  new-question estimate. The estimate now includes a 30-second reading allowance
  and an answer-time floor, with an explicit low-data default (120s new / 75s
  review). The unstarted target also retains its pre-answer capacity.
- Regression before the history fix: an earlier partial planned session had no
  remaining IDs in its calendar row. Its saved unfinished new/review IDs now stay
  visible. Historical rows also include recorded answers without a planned row.
- Home and result now use the same repository-derived daily counts. A saved
  planned set wins over a reduced forecast; completion stays complete, and
  ordinary practice remains secondary. Bootstrap context follows the session
  through feedback to the result screen.
- Calendar dates can be selected; editing is offered only on an eligible selected
  future day. Availability editing returns to Home for an updated projection.
  A regression caught an impossible deadline warning when no date was set; this
  now remains a rolling outlook. No exam date is changed automatically.
- Calendar accessibility regression: a custom card label hid nested edit actions.
  Child semantics now remain exposed; the test checks the `Move session` label.
- Result topic names resolve from the exam configuration. Topic comparisons are
  explicitly session accuracy, and ties do not produce a strongest/weakest claim.
  The result cautions against mastery conclusions from a small sample.

## Real verification results

| Check | Result |
| --- | --- |
| Linux Flutter | 3.41.2, local Lima Ubuntu environment |
| `dart format --output=none --set-exit-if-changed lib test tool` | 258 files, 0 changed |
| `flutter analyze` | No issues found |
| `flutter test` | 1091 passed, 1 existing conditional skip |
| Product VM demo guard | 1 passed |
| Profile VM demo guard | 1 passed |
| `dart run tool/validate_candidate_questions.dart --report` | Structurally valid; 0 errors, 0 warnings |
| Production diagnostic preflight | FAIL as expected: 0 approved questions; 26 candidates still awaiting review |
| Pixel comparisons | Original 32-image matrix retained, plus 6 new daily journey images; exact comparison unchanged |
| `git diff --check` | No findings |
| `flutter build ios --release --no-codesign` | Failed in this environment: `xcodebuild encountered an error (66)` |

The full suite's one skip is the product/profile-constant test, exercised by the
separate guard commands above. Targeted checks cover partial and completed days,
Home → answer → result → Home → restart/reset, saved session resumption,
missed-work/capacity copy, no approved material, no exam date, calendar selection,
availability editing and accessible edit controls. Controlled-clock tests verify
30 seconds answering despite an hour in the background and a separate 20-second
answer after ten minutes viewing feedback. Idle time is capped and never backfilled.

Existing budget assertions were updated for the new reading allowance rather than
relaxed. The 500-question / F5 B3 S22 persistence test uses a 45-second answer
fixture plus reading to retain an ample budget for its exact 23-question target;
its partial/restart/completion assertions remain intact.

## Reviewed screenshots

Widget-test captures with isolated synthetic fixtures, **not physical-device
screenshots**. The existing harness displays placeholder Material icon glyphs and
a debug banner. All ten added/changed images were visually reviewed on Linux.

| State | Light | Dark |
| --- | --- | --- |
| Partial daily plan | [View](../../test/golden/goldens/daily_plan_partial.light.normal.png) | [View](../../test/golden/goldens/daily_plan_partial.dark.normal.png) |
| Partial calendar | [View](../../test/golden/goldens/daily_calendar_partial.light.normal.png) | [View](../../test/golden/goldens/daily_calendar_partial.dark.normal.png) |
| Completed daily result | [View](../../test/golden/goldens/daily_result_done.light.normal.png) | [View](../../test/golden/goldens/daily_result_done.dark.normal.png) |

## Compatibility and remaining limits

Schema **5**, answer permutations, recorded results, free UTC quota, question
approval, difficulty adaptation and purchases are unchanged. No new dependency,
notification, hosted service or data migration was introduced.

Reading is a fixed allowance, not measured reading time. The two-minute inactivity
heuristic may undercount quiet question reading. Old missing timing remains
unknown in history. An unstarted past day with no saved session or record cannot
be reconstructed honestly; the calendar does not fabricate historical forecasts.

On an iPhone, still check VoiceOver focus/reading order, actual Dynamic Type at
largest sizes, light/dark mode, background/foreground, restart/Continue, date
editing and the completed-plan return action. Automated layout checks use a
375x667 viewport and 4x text; they are not a claim of physical-device verification.

Run from a normal Terminal to verify the iOS build:

```sh
cd /path/to/danb_rhs_prep
flutter build ios --release --no-codesign
```

No successful iOS build is claimed for this change. Do not run paid Actions to
replace this local check. The PR is prepared without automatic merge.
