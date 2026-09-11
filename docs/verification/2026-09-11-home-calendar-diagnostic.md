# Reported study-flow fixes

Base: `main` at `fb5730a` (merged PR #69).
Branch: `fix/home-calendar-onboarding-flow`. No automatic merge or hosted Actions.

## Findings and evidence

| Report | Reproduced cause | Change | Evidence |
|---|---|---|---|
| Calendar missing | `StudyPlanPanel` put the calendar action inside the nonempty, configured pool branch. The calendar was a list, not a month. | Persistent Study calendar/next-seven-day section outside Today and content gates; month grid through exam month; selected-day detail; counts from the existing projection. | Red Home-with-zero-content regression; green launch → skip unavailable diagnostic → Home → calendar; Home/calendar count and month-boundary test; historic partial/completed and availability-edit tests. |
| Initial test unavailable | Production has no approved bank; ordinary demo has only draft trivia and a seeded ordinary practice session. These cannot supply an eligible diagnostic. Additionally a completed diagnostic reopened as a new Start and then failed eligibility instead of displaying its recorded result. | Read saved diagnostic state first; Resume, recorded result, unavailable content and read failure are distinct. Existing start/write retry reused. Unsaved answers prevent leaving. Stale help text corrected. | Completed-result test failed before the fix. Full app composition exercises Welcome → timeframe → experience → availability → diagnostic → result → Home, skip, no approved material, restart after answer 1 and restart after completion. One session, 15 answers, saved answer order retained. Existing post-persist-failure retry tests and new answer-write-failure test pass. |
| Dead Review Mistakes at 100% | The summary always rendered a SecondaryButton and disabled it when no incorrect feedback existed. | Render Review mistakes (N) only for actual incorrect feedback; otherwise No mistakes in this session, retaining Home/plan action. Review remains read-only. | Perfect-result regression failed before fix. One-mistake review asserts question, selected answer, correct answer, explanation and unchanged score. 200/201 correctly displays rounded 100% with Review mistakes (1). |
| Home hierarchy | A large two-line slogan, large gaps and multiple explanatory sections dominated the page. | Compact Settings/date heading; Today counts/time/progress/action; separate week/calendar section; secondary practice/saved/progress entries. Existing colors/components retained. | Small-phone light/dark, 4x text, navigation, settings tooltip/target and semantics tests; updated exact Linux goldens inspected. |

Production content is still blocked: 26 candidates remain awaiting review, zero
approved (required diagnostic domain counts: 7/4/4). No draft was approved and no
validator threshold was changed. The ordinary demo's limitations remain explicit.
`flutter run -t tool/main_study_preview.dart` supplies 80 existing synthetic test
fixtures through normal repository injection in independent memory stores. Its
approved fixture shape is test data, not clinical approval. It refuses non-debug
startup. Production does not import it. A process restart resets this preview;
the separate restart regression retains stores across full app reconstruction,
and the full suite retains SQLite persistence/migration/answer-order coverage.

## Local checks

Local Lima Linux, Flutter 3.41.2. All commands below exited 0:

| Command | Actual result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test tool` | `Formatted 261 files (0 changed)` |
| `flutter analyze` | `No issues found!` |
| `flutter test` | `01:24 +1104 ~1: All tests passed!` (1104 passed; one conditional mode test skipped) |
| Product VM demo-entrypoint guard | 1 passed; includes the new preview entrypoint |
| Profile VM demo-entrypoint guard | 1 passed; includes the new preview entrypoint |
| `dart run tool/validate_candidate_questions.dart --report` | Structurally valid YES, 0 errors, 0 warnings; production diagnostic preflight FAIL (0 approved) |
| Exact golden matrix | 42 passed, included again in the full run |
| `git diff --check` | No whitespace errors |

The two mode guards were run with `flutter test --dart-define=dart.vm.product=true test/debug/demo_entrypoint_mode_test.dart` and the equivalent `dart.vm.profile=true` command. No comparison tolerance, test count or content threshold was weakened.

Red evidence before implementation: the zero-content Home calendar test and
perfect-session mistakes-action test failed (23 other tests passed). The completed
diagnostic reopening test also failed before the screen's saved-state check.
Follow-up tests caught and corrected missing skip on a repository-unavailable
onboarding route, plus outdated navigation/semantic expectations during the Home
redesign. The final full regression includes the real app composition, existing
SQLite migrations and stored session ordering.

## Native execution limitation

The native application did **not** run in this agent environment:

- `xcrun simctl list devices booted` failed: CoreSimulatorService connection
  invalid / connection refused, so no usable simulator device was exposed.
- `flutter run -d macos -t tool/main_study_preview.dart` was attempted. After
  resolving the CocoaPods cache permission, Xcode reported
  `macos/Runner.xcworkspace is not a workspace file` and CoreSimulator errors.
  Generated CocoaPods project changes were inspected and removed from the diff.

No successful simulator run, manual iPhone interaction or new iOS release build
is claimed. From a normal Terminal, use:

```sh
flutter run -t tool/main_study_preview.dart
```

Select an available iPhone simulator/device; complete onboarding, answer the
synthetic check, open Home and Study calendar, finish a perfect practice session,
and verify the missing mistakes button and working Home action. Also check VoiceOver,
large Dynamic Type, dark mode, and background/resume on the phone.

## Inspected widget renders (not simulator screenshots)

These are actual Linux Flutter widget-test renders at 375×667, **not captures of
a running native app**. The test font produces placeholder Material icons and some
symbol glyphs, and a debug banner is visible. Those aspects are not physical-device
verification. All 12 changed existing images and four additional images were opened
and inspected; the comparator/tolerance remains unchanged.

- [Home light](../../test/golden/goldens/planned_home.light.normal.png) / [dark](../../test/golden/goldens/planned_home.dark.normal.png)
- [Month calendar light](../../test/golden/goldens/daily_calendar_partial.light.normal.png) / [dark](../../test/golden/goldens/daily_calendar_partial.dark.normal.png)
- [Diagnostic light](../../test/golden/goldens/diagnostic_question.light.normal.png) / [dark](../../test/golden/goldens/diagnostic_question.dark.normal.png)
- [100% summary light](../../test/golden/goldens/daily_result_done.light.normal.png) / [dark](../../test/golden/goldens/daily_result_done.dark.normal.png)

No schema/migration, planner allocation/adaptation, payment, production content,
UTC quota policy or historical answer/permutation changes. Rollback: revert the
PR commit; there is no data migration to undo.
