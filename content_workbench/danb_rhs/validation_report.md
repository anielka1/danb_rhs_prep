# Editorial revision validation — 2026-09-11

Base: current `main` at `75a49c62a4df2be58b988098de5f0a7fca72d20c` (PR #65).
Branch: `docs/rhs-editorial-revision`.
Candidate file SHA-256: `787c3454ae5c06009fc6c280b9e413214ddf5848c69efc8de909c94b8958f925`.

## Actual results in this revision

Checks ran in the existing local Ubuntu 24.04 aarch64 Lima VM with Flutter
3.41.2, with a final validator run on the host as well. No hosted workflow was
dispatched. The commit uses `[skip ci]`; golden-update trigger paths are unchanged.

| Command / check | Actual result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | Exit 0: `Formatted 246 files (0 changed) in 0.82 seconds.` |
| `flutter analyze` | Exit 0: `No issues found! (ran in 1.7s)` |
| `flutter test` | Final run exit 0: `01:43 +1042 ~1: All tests passed!` |
| `flutter test --dart-define=dart.vm.product=true test/debug/demo_entrypoint_mode_test.dart` | Exit 0: `00:00 +1: All tests passed!` |
| `flutter test --dart-define=dart.vm.profile=true test/debug/demo_entrypoint_mode_test.dart` | Exit 0: `00:00 +1: All tests passed!` |
| `dart run tool/validate_candidate_questions.dart --report` | Exit 0 on final host and Linux data: 0 errors, 0 warnings; 26 awaitingReview, 0 approved |
| Independent JSON/packet comparison | PASS: 26/26 complete matches, as detailed below |
| `git diff --check` | Exit 0 |
| Diff of app, tests, tools, production, workflows, dependencies and reviewer decisions against base | Empty |

The first full suite also passed (1042 passed / 1 skipped, 1m45s). The full
suite and validator were rerun after the final two distractor clarifications
in PT-007 and RP-007; the final result is above. No test, existing skip or
golden image/comparison was changed. No iOS build was requested or run for this
content-only revision; no build success is claimed.

## Independent consistency checks

A temporary Python probe compared the final JSON to the staged reviewer
packet and to `git show 75a49c6:content_workbench/danb_rhs/candidate_questions.json`.
It checked:

- Exactly 26 matching question IDs and packet blocks; same domain/topic pairs.
- Four stable answer IDs per question and unchanged `correctAnswerId` values.
- Exact stems, ordered option texts/IDs, displayed key positions, explanations,
  versions, difficulty values, source titles/locators/URLs and fingerprints.
- 26 versions incremented exactly once; all 26 fingerprints differ from base.
- Each item has an objective, provisional difficulty rationale and expert focus;
  all 78 incorrect options have a misconception and concrete source locator.
- Baseline `ABCD×6+AB` and difficulty 5/21; revised difficulty 18/8 and static
  position sequence `CADBBDACDACBADBCACDBDABCAD` (A:7, B:6, C:6, D:7).
- All statuses remain draft, workbench schema remains 1; production content
  and reviewer decisions are byte-identical to base. Runtime schema is untouched.

The baseline topic count independently remains 7 of 10 represented topics
below three items. Inspection of the base authoring guide found the numeric
range without level definitions; the revision supplies the rubric. A word scan
found none of the audited absolute cue words (`always`, `never`, `every`, `all`,
`only`, `cannot`, `guarantee`) in final options. This scan and length inspection
are editorial aids, not proof of distractor quality or factual correctness.

Fingerprints were produced by the existing repository
`computeContentFingerprint(Question)` using `sha256-canonical-json-v1` for both
base and revised data. A temporary Dart probe invoked that function and was
removed; the algorithm was not reimplemented. The current CLI does not print
hashes. The reviewer packet carries the resulting values for exact-version review.

## Limits and handoff

Structural validity is **not clinical approval**. The diagnostic preflight
correctly remains FAIL because there are zero approved production questions.
The packet records per-item expert checks, including the unread full JADA
papers behind PT-002/PT-010, regulatory scope in RP-007 and indicator-evidence
limits in IC-008. Difficulty and learner misconceptions remain editorial
hypotheses pending qualified review and later calibration. Coverage is unchanged.

Next: a qualified human opens the cited sections, applies the review checklist
to each exact version and personally records a real decision/identity/date with
the matching fingerprint. Nothing in this PR records that decision or promotes
content. Preserve `[skip ci]` for any content-only follow-up or squash commit
while the zero-hosted-cost policy applies; do not dispatch hosted workflows.

## Final Linux validator report

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
