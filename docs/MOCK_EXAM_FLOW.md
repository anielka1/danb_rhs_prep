# Mock Exam vertical slice — PREP-650

## Verified gap and resulting behavior

On main `f00b9ba`, Mock Exam was unavailable and its registered result screen
fabricated an 82% score and PASSED badge without any attempt. The regression
`mock_exam_results_screen_test.dart` failed before the fix (one PASSED widget)
and now requires an honest no-result state.

The accountless debug demo now runs start → instructions → answering → flags →
question navigation → finish confirmation → calculated demo result → new exam.
Cancelling confirmation preserves the attempt. Exiting resumes the same saved
answers, flags and cursor. No correctness is revealed during the attempt.

Results use only `Above practice threshold` / `Below practice threshold`.
The configured threshold is inclusive and evaluated without rounding; unanswered
questions count as incorrect. Every result includes:

> Practice estimate only. This is not an official DANB result or a prediction of exam performance.

## Architecture and content boundary

- `MockExamBlueprint` validates the existing content contract, allocates domain
  quotas by largest remainder (configuration order resolves ties), and selects
  unique question IDs. New starts rank by exposure and randomize ties and the
  final question order; preflight remains deterministic. Insufficient eligible
  content is a gate.
- Production selection accepts only existing approved questions; this change
  authors no clinical content and changes no approval/reviewer metadata.
- Demo uses the existing injected synthetic draft fixtures, visibly labelled
  `[Demo]`. VM product/profile guards reject demo activation, including direct
  blueprint use. Existing AOT binary probes also check fixture stripping.
- `MockExamController` owns state, scoring and repository writes. Widgets do not
  access assets, JSON, SQLite, network, authentication or platform storage.
- Bootstrap carries the injected progress repository through direct onboarding
  routes to MainShell; no second state-management architecture is introduced.

## State and persistence policy

Every answer, flag, cursor and completion is saved before publishing new state.
Pending writes block duplicate operations and exiting. Failed writes retain the
previous state and allow retry; errors do not display storage diagnostics.
Restoration validates content version, question/answer identities and domain
quotas. Corrupt or ambiguous active attempts are never silently discarded.

Demo storage is in-memory: closing the exam or rebuilding the controller resumes
within the same process; restarting the app resets deterministic fixtures. This
limitation is stated in the instructions. Production uses the existing Drift-backed progress repository. Schema 5 adds
nullable answer-order JSON to mock and practice rows; see the persistence section
below. Production without storage/content shows an honest unavailable state. Timed configurations use the stored start time,
including time spent away; at expiry answers are blocked and explicit confirmation
is still required to produce a result. The demo configuration is untimed.

## Accessibility and privacy

Selected answers, flags and question navigation expose textual/semantic state;
status never relies only on color. Controls use existing tokens and minimum
44-point targets. Screens scroll at large text sizes. Material confirmation is
scrollable to prevent the overflow reproduced at 4× text. Existing adaptive iOS
alerts are retained. Tests cover light/dark, normal/4× text and disabled animations.
No data collection, analytics, network traffic, PII or signing changes are added.
Physical-device VoiceOver speech and the complete iOS AX5 matrix require manual
verification; automated semantics checks do not claim to substitute for them.

## Verification map and rollback

- `test/mock_exam/`: deterministic blueprint/flow, negative structures, threshold
  boundary, retry/concurrent writes, restart, timing, invalid saved attempts.
- `test/screens/mock_exam*_test.dart`: original result regression, full clickable
  flow, return/retake, loading/error/retry, accountless composition, semantics.
- `test/debug/`: product/profile activation rejection and native AOT fixture scan.
- Required checks: format, analyze, full Flutter tests, both VM-mode tests,
  candidate content report and unsigned iOS release build (same commands as CI).

Risks: route lifecycle, atomic-write behavior of future repository implementations,
and saved-content version changes. The in-memory repository remains the demo contract; approved production content
and physical-device verification remain release gates. After a schema-5 database
has been opened, use a forward fix retaining schema 5; do not downgrade the app
to schema 4 or delete the new columns.

## Persisted answer order and mock rotation

New practice (including planned and diagnostic) and mock sessions create a
question-ID → ordered stable answer-ID map once, before opening a question.
Controllers resolve display-only Question objects from this saved map. Letters
A/B/C/D describe the current display positions only; scoring, selection, flags,
and feedback use IDs. No build method shuffles. Completion, navigation, retry,
and restart preserve the map, including answer review. Content is not rewritten.

Schema 5 adds nullable `answer_order_json` to `practice_sessions` and
`mock_attempts`. The additive upgrade from versions 1–4 leaves every old column
and row intact. Null means legacy: use the previous content answer order, without
backfilling or consuming randomness. Historical scores and feedback are unchanged.
Malformed non-null permutations (duplicates, missing/foreign IDs) fail closed;
they are not treated as legacy. Existing content-version/eligibility constraints
still apply; this is not a content snapshot or a cross-version content migration.

At each new mock start, the eligible pool, configured count and largest-remainder
domain quotas are unchanged. An effective first-mock reserve still ranks first.
Within that priority, lower exposure ranks first and equal exposure is shuffled.
Exposure is the number of practice/diagnostic answer attempts plus prior mock
selections, including unanswered or abandoned selections; matching mock answer
rows are not counted twice. This is a rotation measure, not a mastery/readiness
measurement. The existing `seenBeforeStartCount` retains its answered-history
meaning. Ranking never bypasses content approval or access limits.

Selection is without replacement within an exam; a small pool can repeat across
exams. A pool below a required domain quota remains unavailable. The chosen set,
question order and answer permutations are persisted together before the first
question. Resume resolves only that stored attempt. A start retry also checks for
an active attempt, covering a successful commit followed by a lost response.
A failed write before commit exposes no new exam; a later start may draw again.

Tests use controlled Random sources (including a source that throws if resume
consumes randomness), real SQLite close/reopen, and a frozen schema-4 SQL fixture
exported from main b705270. Existing UI tests locate answers by identity/text,
not by assuming the first option is correct. Test sources do not affect production
randomness. Hosted workflows remain disabled for these commits via `[skip ci]`.

## Final grades and topic-session exit

New mock completions atomically store the final `MockAttempt`, one frozen
`AnswerAttempt` per answered question, and the corresponding `QuestionState`
aggregates. Grades use stable answer IDs, not display positions. Changing a
choice during an exam records only the final choice when the exam is finished.
Until then, the persisted mock remains resumable without publishing interim
correctness to Progress. Unanswered questions still reduce the mock score but
are not marked attempted or completed in topic progress.

Final answer records contain the content/question version, correct answer ID,
and explanation used for grading. Their timestamp and local date represent
exam finalization; no per-question answer time or confidence is invented.
Progress and Review mistakes consume these records through their existing
history logic. Legacy completed mocks are not backfilled or regraded; existing
`Grade unavailable` behavior remains when their detailed grades are missing.

`MockCompletionRepository` is the atomic completion capability implemented by
Drift, the demo repository, and the reset-aware UI lease. A failed completion
keeps the exact final payload for Retry. Editing choices is unavailable until
that retry succeeds, since a failure may occur after the database committed.
Deterministic record IDs make an identical retry idempotent. SQLite tests cover
rollback of partial work, a lost acknowledgement, and a full database restart.
No schema migration is required (schema 5 remains unchanged).

New topic sessions persist `PracticeMode.topicPractice`, including the
unfinished-topics action. X ends that run even when resumed from Home without
a topic-selection callback. Legacy `browseDomain` sessions receive the same
exit behavior; older `quickPractice` sessions are not guessed to be topic
sessions, because that mode also represented ordinary mixed practice. Ordinary
mixed sessions remain resumable. Ending a run never marks its unanswered
questions or its whole topic completed. A failed save retains the existing
Stay/Leave recovery flow. Existing question/answer order and history survive.
