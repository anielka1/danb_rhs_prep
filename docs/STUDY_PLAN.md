# Self-directed study (September 2026)

The calendar and daily allocation feature has been retired. Home does not compute
or display daily commitments, forecasts, required pace, availability or remaining
planned study time. The allocation engine and calendar editing service have been
removed, along with their UI. Practice length is chosen per session, not inferred
from the exam date. Free-plan allowances and their midnight UTC reset are unchanged.

## Current path

Welcome → exam timeframe → Home. There is no experience, availability or starting
check screen. Completion is written only after the profile saves; failures remain
on the date screen with Retry. Restart restores the completed setup.

Home offers exactly Practise questions (one random question), Practice by topics,
Saved questions, Review mistakes and Mock exam. Quick 10 and Timed quiz are no
longer Home launchers; their saved sessions still resume with their answer order
and feedback. Continue session resumes practice or mock. The bottom
bar contains Home and Progress only; Settings remains in Home's header.

The shared-theme **Your progress** card shows current unique Correct / Needs review and
**Correct today**, a count of correct attempts on the local day. It does not show
study time, accuracy, daily goals or a calendar plan. A compact exam-date action
edits the existing date. See [progress aggregation](PROGRESS_AGGREGATION.md) for
the common source used by Home, Progress and mistake practice, including historical
mock limitations.

## Retired starting check

There are no routes or launchers for DiagnosticScreen. Historical diagnostic
attempts still contribute their recorded grades to Progress and topic evidence;
they remain excluded from the free practice allowance. No old answer is regraded.

Home and the practice launcher use `resumablePracticeSession`. An in-progress
legacy diagnostic is saved as `abandoned`, with its question IDs, answer order,
answers and timestamps preserved and no `completedAt`. This releases the single
active practice slot. A read or retirement write failure propagates to Retry;
new practice does not start over an unsafely retained active session. Repeating
the operation is idempotent. Completed diagnostics are untouched. No unanswered
question is recorded and no false completion is created. Low-level legacy session
serialization and historical controller tests remain supported.

## Data compatibility

Schema stays **5**. No migration, deletion or reset runs as part of this change.
Existing answers, session types, plan dates, review IDs, schedule rows, profile
availability and legacy daily-goal column remain readable. The old calendar is not
exposed and no new scheduled work is generated. Existing mock reservations retain
their prior expiry/access rules; mock selection and payment rules are unchanged.
The historical review-evidence policy remains tested; it does not allocate work.

`UserProfile.experienceLevel` is nullable. New absence is encoded as the explicit
`notCollected` marker in the existing non-null text column, rather than a fabricated
`justStarting` answer. Recognized historical values are preserved. Unknown values
read as absence. SharedPreferences experience answers are neither fabricated nor
erased. Re-saving the exam timeframe preserves any existing legacy answer.

`activeDurationSeconds` still measures answering only. Background time and the
existing idle timeout are unchanged. Summary elapsed time still includes pauses;
historical measurements and scores are not reinterpreted.

## Verification

Launch tests cover date → Home with approved and unavailable content, restart,
and profile/completion write Retry. Home covers legacy diagnostic retirement,
retirement failure Retry, unchanged historical answers, normal session resume and
Mock exam. SQLite reopen tests preserve partial and completed diagnostic records.
System/Light/Dark tests reconstruct the app with a fresh bootstrap and the same
store, and verify shared Home colors. Existing history, answer-order, free-limit,
feedback and theme tests remain. Diagnostic UI goldens are removed with the screen;
comparison rules for all remaining screens are unchanged.

Use `flutter run -t tool/main_home_preview.dart` for the isolated synthetic
preview. It writes no production data. See the PR verification report for actual
executed checks and visual inspection.
