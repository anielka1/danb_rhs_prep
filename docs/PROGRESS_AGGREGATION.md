# Recorded learning progress

`LearningProgress.fromHistory` is the single current-grade/activity aggregation
used by Home, Progress and the Review mistakes launcher. It reads saved grades;
it never compares an old answer to the current content answer key. Content
eligibility is the existing PracticeGenerator gate (approved production content,
or the isolated labelled debug fixture). All configured domains are displayed.
The bank summary includes the whole eligible bank, not a fabricated target size.
Practice selection continues to respect existing free limits and mock reserves.

## Current questions

Each available question contributes once. The last saved AnswerAttempt in the
repository's durable insertion order determines Correct or Needs review. SQLite
returns rowid order, and the in-memory repository preserves insertion order.
Neither lexical attempt IDs nor tied/backwards device timestamps reorder events.
Retrying an existing attempt ID does not add a second event. A genuinely unseen
question is Not attempted. Domain counts use the current question-to-domain
mapping and sum to the entire bank. A removed question leaves the current bank
but remains in daily activity. Review mistakes uses the same incorrect ID set;
a later correct answer removes a question even if its lifetime timesIncorrect
remains positive. Existing question-state aggregates and weak-area logic remain
unchanged. No migration, history deletion or regrading occurs; schema stays 5.

## Daily activity

Every real saved practice/diagnostic answer counts, including repeat answers to
one question. Correct today is this activity's correct count, not unique questions.
`localAnsweredDate` takes precedence. Older AnswerAttempts without it use
`answeredAt.toLocal()` in the device's current timezone. Such older day groupings
can change after travel; the original timezone cannot be recovered honestly.
Days are ordered newest first. No duration or accuracy figure is invented.
Read errors surface Error/Retry, while an empty successful read is a valid zero.
The separate free allowance still resets by UTC and is not based on this view.

## Mock evidence and limits

Only completed mocks contribute grades; active mock correctness is never exposed.
If individual mock AnswerAttempts exist, count each session/question once and do
not add the aggregate score again. Questions not answered in a mock are never
counted as daily incorrect answers.

Current MockAttempt storage has a frozen correctCount, submitted answer IDs and
completion timestamp, but no individual frozen grades or per-answer local dates.
For an aggregate-only completed mock, daily activity therefore uses its saved
correctCount, answers.length minus correctCount, and completion date converted to
the current local timezone. This is a completion-day grouping, not a claim about
when each answer was submitted. No new mock write format is introduced here.

Those answers cannot truthfully be split into current Correct / Needs review.
They are displayed as **Grade unavailable**, an explicit additional segment only
when needed, instead of falsely labelling them Not attempted. A later dated saved
individual grade resolves that question; equal/earlier timestamps remain unknown
because cross-record ordering cannot be established. The three requested counts
remain visible and the unknown segment is included in domain/bank totals. Home
shows a short limitation note; Progress provides the fuller explanation.

If a mock has only partially imported individual AnswerAttempts, show those
recorded events and do not expand its aggregate into guessed missing events.
The limitation is surfaced. This avoids duplicate or invented daily splits.

## Navigation compatibility

AppTab has only home/progress and MainShell has two navigation stacks. The existing
restoration key retains storage IDs 0 and 3; removed IDs 1/2 and unknown values map
to Home. Answer/session storage is untouched. Existing Quick 10, timed, planned,
diagnostic and mock sessions still resume their saved IDs/order/answers.
Practice and mock flow exits return to Home. Finished mock routes no longer keep
busy pop guards or perform extra pops after a shell-level return to Home.
