# Self-directed study (September 2026)

The calendar and daily allocation feature has been retired. Home does not compute
or display daily commitments, forecasts, required pace, availability or remaining
planned study time. The allocation engine and calendar editing service have been
removed, along with their UI. Practice length is chosen per session, not inferred
from the exam date. Free-plan allowances and their midnight UTC reset are unchanged.

## Current path

Welcome → exam timeframe → optional starting check → Home. There is no experience
or availability question. Completion is written after the profile saves; a failure
stays retryable. Reopening preserves the timeframe and any diagnostic session.
Skipping the check completes onboarding without creating answer history.

Home offers exactly Practise questions (one random question), Practice by topics,
Saved questions, Review mistakes and Mock exam. Quick 10 and Timed quiz are no
longer Home launchers; their saved sessions still resume with their answer order
and feedback. Continue session resumes practice, diagnostic or mock. The bottom
bar contains Home and Progress only; Settings remains in Home's header.

The navy **Your progress** card shows current unique Correct / Needs review and
**Correct today**, a count of correct attempts on the local day. It does not show
study time, accuracy, daily goals or a calendar plan. A compact exam-date action
edits the existing date. See [progress aggregation](PROGRESS_AGGREGATION.md) for
the common source used by Home, Progress and mistake practice, including historical
mock limitations. The optional starting check remains secondary.

## Why keep the starting check?

It writes `AttemptSessionType.diagnostic` through the same atomic attempt/state
transaction as practice. `QuestionState.timesSeen/timesCorrect/timesIncorrect`
therefore include those answers. Progress displays that evidence, and
`PracticeGenerator` uses the aggregate topic accuracy for `PracticeFocus.weakAreas`
for weak areas. Mistake practice uses the latest saved grades through the shared
`LearningProgress` aggregation. It does not set a self-reported skill level,
change adaptive difficulty, or calculate the probability of passing. Small samples
are described as a starting point. Diagnostic attempts do not consume the daily
free practice allowance. The domain quota and approved-content gate are unchanged.
Production still needs a reviewed approved bank; no drafts are promoted here.

The optional check distinguishes unavailable material, read/start failures, active
sessions and stored results. Skip, Continue later, resume and retry saving remain
available. Answer IDs and persistent answer ordering remain the source of scoring.

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

Updated launch tests cover completion, skipping, insufficient content, persisted
answers/order through app reconstruction, and retry of profile/completion writes.
Home tests cover empty content, real progress, safe read retry, direct practice,
legacy planned resume, diagnostic routing, and small-screen large-text layouts.
SQLite tests preserve old profile fields and round-trip a new absent experience.
The diagnostic-to-weak-practice regression verifies its real downstream benefit.
Obsolete calendar/allocation and experience-selector tests are removed with their
features; storage, answer ordering, feedback, free-limit and review-evidence checks
remain. Golden thresholds and shared test harness are unchanged.

Use `flutter run -t tool/main_study_preview.dart` for the isolated 80-question
synthetic fixture and full optional check. This is debug-only and writes no
production data. Actual executed results and reviewed render references are in the
PR verification report.
