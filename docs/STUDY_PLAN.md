# Adaptive study plan

The plan is a local projection, not an exam-readiness score or a guarantee of
passing. Production content must pass the existing validator and be approved.
Draft/demo content is never promoted by the planner. The production pool currently
has no approved questions; availability can be saved, but a real planned session
requires approved content. Synthetic integration questions live under `test/`.

## Durable inputs and migration

Schema 4 adds nullable availability JSON to `UserProfiles`, nullable confidence,
active seconds and local calendar date to `AnswerAttempts`, planned date and review
IDs to `PracticeSessions`, pre-start exposure count to `MockAttempts`, and the
`StudySchedules` exception table. Upgrades from 1, 2 and 3 are additive. Old rows
retain null measurements; no confidence or time is invented. Generated Drift code
is produced with `dart run build_runner build`.

Availability is stored once in the profile and exposed through BootstrapReady's
profile/availability getter. Bootstrap loads that profile from the settings
repository; edits publish a new snapshot only after saving. There is deliberately
no second, potentially contradictory availability record in SharedPreferences.
Editing the date/experience preserves availability, original question goal and
creation time. Legacy profiles keep their existing question goal until they choose
weekdays and 15, 30 or 45 minutes. Retaking an exam is not an advanced skill level;
Mostly reviewing is a separate stable study-stage value.

Calendar exceptions are replaced transactionally. Progress reset removes answers,
sessions, review evidence, mocks and calendar exceptions while preserving profile
and appearance, following the existing reset lease. Retired leases cannot write
old progress back after reset. Review state is derived from append-only answers,
so an idempotently retried answer cannot advance the schedule twice.

## Dates, budgets and allocation

The pure engine receives the current instant, explicit local calendar date and
zone label. Calendar arithmetic uses UTC-flagged year/month/day components solely
for DST-independent date arithmetic; it never converts an exam date with toUtc.
New answers capture their local date at submission. Old answers without local-day
evidence use their recorded UTC date for review scheduling, not for confident
retention evidence. The existing free-practice counter retains its UTC-day reset.

D counts selected study dates from today through the day before the exam.
F = min(5, floor(0.20D)), B = floor(0.10D), S = D-F-B. The required pace is
ceil(U/S), with U counting unseen approved ordinary questions, excluding an active
mock reserve. This is distinct from the time-constrained assigned pace. With 500
questions and D=30, F=5/B=3/S=22 and pace=23; reserving 75 gives pace=20.

Initial estimates are 90 seconds for new questions and 45 seconds for reviews.
After five measured samples of each kind, use the median of samples between 5 and
300 seconds. Work already recorded today reduces its budget and remaining new
assignment. A stopwatch on the question screen excludes background time and time
spent viewing feedback. Estimates do not interrupt an answer in progress.

The normal forecast reserves 30% of time for reviews. Actual due reviews are
assigned first; excess remains visible as backlog. Domain allocation uses weighted
cumulative deficits rather than re-rounding every small batch. Within domain ties,
unseen topics precede weak topics, then remaining material; difficulty uses the
validated 1–5 scale (initial target 2, mostly-reviewing target 3, then performance).
IDs break ties deterministically. Missing domain coverage remains explicit in the
projection. Buffers are distributed and optional; once work has started they can
absorb excess before increasing ordinary-day load. Moving onto an occupied date
reuses its single daily budget instead of adding an invisible second session.

Future review dates simulate successful review intervals only to estimate workload;
they never write answers or create mastery evidence. Actual history is recalculated
after answers, availability changes, content/access changes and foreground/day
changes. Unscheduled plans roll over seven days without a countdown. Tomorrow is
review-only; today/past exam dates schedule no new pre-exam work.

## Review evidence

Success intervals are 1, 3, 7 and 14 days, then 14. Only explicitly confident
correct answers on separate dates advance a stage. Errors or “I guessed” restart
at the next available study date. Review policy version 2 keeps the stage for a neutral correct answer but gives
only a short next-available-study-day check, never the old stage's 3/7/14-day
interval. An early neutral answer can shorten an existing due date, not delay it.
An overdue neutral answer clears today's queue until that short next check.
Repeated neutral answers on successive days remain short. Same-day answers do not
advance or postpone the interval; an error followed by a same-day correction
remains at stage zero. Only a confident success on a different day earns the
1/3/7/14 interval. This derived policy change requires no stored-state migration.
Days outside selected availability move forward to the next selected weekday.
Reviews falling after the exam are marked in the projection; final-review slots
may bring them forward without claiming retention.

Topic retained status requires at least three distinct questions, three recorded
local dates and three questions at review stage 3 or higher, without an overdue
review or error. Under three questions or two dates is insufficient data. Other
states are learning and needs review. These configurable product heuristics are
not official DANB thresholds. Unique coverage, first-answer accuracy and repeat
accuracy are shown separately.

## Practice, diagnostic and mock integration

A planned session stores ordered IDs and which IDs were reviews before opening a
question. Resume restores that same set and feedback. New starts share the existing
content validator and eligibility gate, enforce the existing UTC practice cap,
and fail closed on unreadable storage. Existing practice modes remain available.
A failed answer-history read during resume propagates instead of producing a
controller with zero answers. This includes failure of the second read after the
planned-session preflight read succeeded. Retry restores the same saved IDs and
historical feedback; a successful empty read is a distinct, valid state.

The optional diagnostic reads its count from freeTier.diagnosticQuestions and uses
largest-remainder domain quotas. It records diagnostic attempts, separate from the
practice allowance, and offers Skip when the pool is insufficient. Results describe
performance per area, never exam readiness. Content/eligibility failures show the
reason and Skip; a transient start failure keeps a visible Retry diagnostic
button. Retrying uses the normal start/resume path, so a session already persisted
before an error is reused rather than duplicated. A successful retry clears the
error message. These recovery changes do not alter schema 4 or historical data.

A mock requires a separate configured-duration slot (currently 60 minutes), content
availability and remaining access. An optional first-mock reserve is made only from
unseen approved questions and only if every currently represented topic remains in
the ordinary pool. Reserving does not mutate a started mock. The selector honors
reserved IDs and each new result stores the number seen before start. Cancelling,
starting the first mock, losing access, or content retirement that removes ordinary
topic coverage releases the ordinary-pool restriction.
Mock answer review is separate from the timed slot.

## Verification

Tests in `test/study_plan/` exercise real SQLite persistence/restart, schema-3
migration, idempotent answers, separate diagnostic typing, reservation selection
and cancellation, old preference preservation, time/quota limits, date boundaries,
review intervals and 375×667 layouts under light/dark themes at 1×/4× text.

Final command results and any outstanding release gates are recorded in the PR.
Hosted GitHub Actions are not used for this task, per the zero-cost requirement;
Linux checks use the local Lima VM. Content is never approved to satisfy a gate.

Mock answers contribute to explored coverage, while first-answer and repeat
accuracy use practice/diagnostic AnswerAttempts. The debug demo allows three mock
attempts (two seeded history records and one interactive attempt); production
allowances are unchanged.

### Local verification, 2026-09-10

- Format: 245 files, 0 changed, exit 0. Analyze: no issues, exit 0.
- Full Linux suite: 1031 passed, 1 skipped, exit 0 (including goldens).
- Release bundle: exit 0.
- Content report: exit 0. Production readiness: exit 2, no approved
  questions for the required 7/4/4 diagnostic distribution.
- iOS release/no-codesign was attempted but Xcode returned error 66 in this
  environment. User Terminal verification and physical-device checks are pending.

## Stability follow-up to PR #63

The next-days required pace remains a forecast based on the remaining pool.
Today's unstarted pace reconstructs the pool before today's first answers so
completed work is subtracted once, not twice. After a planned session starts,
its existing schema-4 ordered question IDs and review IDs define the day's
commitment. A fresh controller and a reopened SQLite database reconstruct the
same unfinished IDs. Finishing this commitment does not allocate another batch
when fast recorded answers lower the time estimate. Remaining time, content
eligibility and UTC allowance still bound the projection; resume never replaces
the active session. Availability/date edits recalculate the forecast, not saved
session IDs. Free practice remains separately available.

Home reads the active session in StudyPlanPanel, which owns the only primary
practice/continue action. The separate Free practice card opens the existing mode
picker as a secondary action. Returning from practice, Settings, a tab, or the
background refreshes the panel. No new navigation framework or tab was added.

Calendar presentation separates remaining assignments from recorded answers and
spent time. Completed rows show their actual recorded work rather than an empty
assignment, and changing today to a day off keeps that work visible. A missed
saved session is marked not completed; a day off explicitly says no study is
scheduled. Exam rows point to Settings and expose no impossible edit buttons.
Past unstarted projections are not invented as completed or missed records.
Existing fallback estimates remain for old answers without active timing.

Regressions reproduced on main: 23 became 22 after 18 answers; neutral review
inherited a seven-day delay; two primary practice actions; editable exam row;
completed-day zero-assignment presentation; day-off edits hid recorded work;
exhausted quota incorrectly completed an active session. An in-progress saved
session now takes precedence over an empty time/quota-constrained assignment.
The schema remains **4**, with no migration or deleted data.

### Stabilization verification, 2026-09-11

- Format: 246 files, 0 changed, exit 0. Analyze: no issues, exit 0.
- Full local Linux suite: `01:24 +1042 ~1: All tests passed!`, exit 0
  (1042 passed, 1 skipped), including the unchanged exact golden comparator.
- Content report: exit 0; require-ready: exit 2 because approved remains zero.
- iOS release/no-codesign: attempted, exit 1, Xcode error 66. Direct workspace
  inspection exits 66 with `ios/Runner.xcworkspace is not a workspace file`
  and CoreSimulator connection errors in this execution environment.
  Verify from a normal Terminal at the repository root with
  `flutter build ios --release --no-codesign`. No successful iOS build is claimed.
- No hosted GitHub Actions. Physical-device accessibility is not verified.
