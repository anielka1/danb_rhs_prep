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
  unique question IDs in stable order. Insufficient eligible content is a gate.
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
limitation is stated in the instructions. There is no migration or durable
production mock storage added by this task. Production without storage/content
shows an honest unavailable state. Timed configurations use the stored start time,
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
and saved-content version changes. Existing in-memory repository is the demo
contract; durable production storage and qualified content review remain separate
gates. Revert the PREP-650 PR to roll back; no migrations, external writes or
secrets require separate reversal.
