# First batch validation — 2026-09-11

Candidate file SHA-256: `4d294b0e96984c2584167b8fc804181cf56b9c2a0ddd1ed9067270f22affa879`.

Base: current `main` at `6223eb6`; branch `docs/rhs-first-draft-batch`.
Checks ran locally, including the existing Ubuntu 24.04 aarch64 Lima VM with
Flutter 3.41.2. No hosted workflow was dispatched. The commit uses `[skip ci]`
to avoid pull-request-triggered CI; golden-update paths are not changed.

## Actual results

| Command / check | Result |
| --- | --- |
| `dart run tool/validate_candidate_questions.dart --report` | Exit 0 on host and Linux; 0 errors, 0 warnings; 26 awaitingReview, 0 approved |
| `dart format --output=none --set-exit-if-changed lib test tool` | Exit 0; Formatted 246 files (0 changed) in 0.81 seconds |
| `flutter analyze` | Exit 0; No issues found! (ran in 8.0s) |
| `flutter test` | Exit 0; 1042 passed, 1 skipped, All tests passed! (2m15s) |
| `git diff --check` | Exit 0 |
| Packet/JSON consistency check | 26/26 stems, explanations and options match; four options and one key each; all draft; 26 fingerprints |
| App/production/test/tool/workflow/dependency diff | Empty |

No tests or golden comparison rules were changed. The existing skipped test
was not enabled or disabled by this content-only change. No iOS build was
requested or run for this workbench-only task; no iOS build success is claimed.

The per-question fingerprints in the packet came from the repository's
`computeContentFingerprint(Question)` implementation, invoked by a temporary
Dart helper which was removed afterward. The helper initially needed its
Question import corrected from a relative to a package import; it then ran
successfully. No validator or schema code changed. The CLI itself currently
does not print the fingerprints.

**Structural validity is not clinical approval.** The diagnostic preflight
below correctly fails: zero questions have human approval and the production
bank still has zero approved questions. Nothing was promoted or merged.

## Validator report

```text
DANB RHS candidate content bank report
============================================================
Structurally valid: YES (0 error(s), 0 warning(s))

Domain inventory (target 15-question diagnostic):
Domain                  Target  Drafted  Approved  Required  Ready?
purpose_technique           14       10         0         7  no
radiation_protection         8        8         0         4  no
infection_control            8        8         0         4  no

15-question diagnostic preflight would: FAIL

Per-question status:
  rhs-cand-purpose_technique-001: awaitingReview
  rhs-cand-purpose_technique-002: awaitingReview
  rhs-cand-purpose_technique-003: awaitingReview
  rhs-cand-purpose_technique-004: awaitingReview
  rhs-cand-purpose_technique-005: awaitingReview
  rhs-cand-purpose_technique-006: awaitingReview
  rhs-cand-purpose_technique-007: awaitingReview
  rhs-cand-purpose_technique-008: awaitingReview
  rhs-cand-purpose_technique-009: awaitingReview
  rhs-cand-purpose_technique-010: awaitingReview
  rhs-cand-radiation_protection-001: awaitingReview
  rhs-cand-radiation_protection-002: awaitingReview
  rhs-cand-radiation_protection-003: awaitingReview
  rhs-cand-radiation_protection-004: awaitingReview
  rhs-cand-radiation_protection-005: awaitingReview
  rhs-cand-radiation_protection-006: awaitingReview
  rhs-cand-radiation_protection-007: awaitingReview
  rhs-cand-radiation_protection-008: awaitingReview
  rhs-cand-infection_control-001: awaitingReview
  rhs-cand-infection_control-002: awaitingReview
  rhs-cand-infection_control-003: awaitingReview
  rhs-cand-infection_control-004: awaitingReview
  rhs-cand-infection_control-005: awaitingReview
  rhs-cand-infection_control-006: awaitingReview
  rhs-cand-infection_control-007: awaitingReview
  rhs-cand-infection_control-008: awaitingReview
```
