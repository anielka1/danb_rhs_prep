# DANB RHS Content Approval Workflow

How a candidate question moves from an empty template to bundled production
content. Every step involving judgment (sourcing, factual review, approval,
promotion) is human-controlled; nothing in this repository automates a
status change into `reviewed`/`approved`, and nothing automatically copies a
candidate into the production bundle.

## Pipeline

1. **Author creates a draft candidate** in
   `content_workbench/danb_rhs/candidate_questions.json`, following
   `DANB_RHS_QUESTION_AUTHORING_GUIDE.md`, only for a domain whose source
   gate has passed in `content_inventory.md`. Status is always `"draft"`.

2. **Validator checks structure**:
   ```
   dart run tool/validate_candidate_questions.dart --report
   ```
   Confirms schema validity, unique/non-colliding IDs, known domain/topic
   IDs, exactly one correct answer, no duplicate stems, required source
   metadata present, and inventory counts. A clean run proves the candidate
   is *structurally* reviewable — it proves nothing about factual accuracy
   and is never treated as approval.

3. **Qualified reviewer evaluates** the question and its sources using
   `DANB_RHS_QUESTION_REVIEW_CHECKLIST.md`, opening the cited reference
   directly rather than relying on memory. The source itself may live in
   the reviewer's own authorized private storage rather than in this
   repository — see "Safe source-storage policy" below.

4. **Reviewer records a decision** in
   `content_workbench/danb_rhs/reviewer_decisions.json`, keyed by the exact
   question `id`, the `contentFingerprint` the validator reports for that
   question's current text, and the `contentFingerprintAlgorithm` it was
   computed with (see below). The decision carries the reviewer's real
   identity, an ISO-8601 date, the checklist outcome, and notes.

5. **Rejected/revision-required questions remain outside production** —
   they stay in the workbench indefinitely as a record; nothing promotes
   them.

6. **Approved, fingerprint-matched questions may be promoted** to
   `assets/content/danb_rhs/reviewed_content.json` — a deliberate, human-performed
   edit (or a future promotion script explicitly run by a human), never an
   automatic step of running the validator or the test suite.

7. **Production content validation runs** — the existing
   `ContentValidator` (`lib/features/content/domain/content_validation.dart`)
   against the updated `reviewed_content.json`, exactly as it already does today.

8. **The diagnostic preflight is rerun** —
   `dart run tool/validate_candidate_questions.dart --require-ready`
   confirms bundled *production* approved inventory still meets the
   configured allocation (currently 7/4/4, derived from configuration, not
   hardcoded) after promotion.

9. **Section 3.5 implementation begins only when `--require-ready` exits
   `0`** — i.e. enough approved questions exist in the *bundled* production
   content, not merely in the workbench. A fingerprint-matched approval
   sitting only in `reviewer_decisions.json` does not itself unblock
   Section 3.5; the question must actually be promoted into `reviewed_content.json`
   first — see "Validator CLI modes and exit codes" below.

No step in this repository currently automates 6–8; they are documented
here as the required human-controlled sequence for when promotion actually
happens.

## Content fingerprint

Binds a reviewer's approval to the *exact* text they reviewed, so an edit
after approval can't silently carry the old approval forward.

**Algorithm**: `sha256-canonical-json-v1` (the value of
`kFingerprintAlgorithm` in `tool/candidate_question_validator.dart`) — SHA-256
over deterministic canonical JSON, using the `crypto` package. This approval algorithm remains confined to
`tool/` and its tests; the separate [release transport checksum](SUPABASE_CONTENT_SYNC.md)
also uses `crypto` at runtime and never grants reviewer approval. Rendered as a lowercase
64-character hexadecimal digest. An earlier version of this fingerprint
used a 64-bit FNV-1a hash (16 hex characters); FNV-1a is not
collision-resistant enough to bind a human approval to exact content, so it
has been replaced — see "Legacy and unsupported algorithms" below.

**What's fingerprinted** — every field that can affect the question's
meaning, diagnostic eligibility, selection behavior, difficulty
classification, domain/topic classification, source provenance, or a human
reviewer's judgment:

| Field | Why it's material |
| --- | --- |
| `id` | An approval is bound to a specific question. |
| `domainId`, `topicId` | Domain/topic classification — exactly what the diagnostic's blueprint allocation selects on. |
| `questionText`, `answers` (id+text, **in order**), `correctAnswerId`, `explanation`, `references` (**in order**) | The question's actual tested content. Answer/reference order is material — reordering changes the fingerprint, since it can change which option a candidate reads first. |
| `difficulty` | Feeds difficulty-based selection/weighting; a reviewer who judged a question as difficulty `2` did not review it as `4`. |
| `sourceVersion` | Identifies which edition/version of the authoritative source the question was drafted against. A reviewer's factual sign-off is bound to that specific source version — citing a superseded edition afterward must not silently keep the approval. |
| `tags` (sorted — see below) | Support blueprint/topic cross-referencing and future selection logic. Included even though the current generator doesn't consume tags yet — a field isn't excluded just because nothing reads it *today*. |
| `version` | The question's own content-revision number — see "Deciding whether `version` is material" below. |

**Deliberately excluded**:
- `status` — promotion from `draft` to `approved` is exactly the event
  this fingerprint exists to survive. Including it would make every
  approval self-invalidate the moment it takes effect.
- `updatedAt` — a bookkeeping timestamp with no bearing on meaning; a file
  touch or resave must not invalidate an otherwise-matching approval.
- Anything that lives on the *reviewer decision* rather than the question
  (notes, reviewer identity, review date) — these can never affect the
  question's own fingerprint, since `computeContentFingerprint` only ever
  receives the `Question`, never the decision.

### Tag normalization

Tags are treated as a semantically **unordered set**: reordering an
otherwise-identical tag list does not change the fingerprint, but adding,
removing, or changing a tag does. This is implemented by sorting the
already-trimmed tag strings `Question.fromJson` produces before
canonicalizing — no case-folding, since tag case is not assumed to be
insignificant (two differently-cased tags are genuinely different tags).
Consistently, the validator rejects exact-duplicate tags on a single
candidate as a structural error (`duplicate_tag`) rather than silently
deduplicating them, since a schema that treats tags as a set should not
also tolerate the same set member listed twice.

### Deciding whether `version` is material

`Question.version` is a per-question `int`, always `1` in current sample
content — but it is **not** a schema/serialization-format version (that
concept exists entirely outside `Question`: e.g. the content package's own
`contentVersion`/`examVersion`, or the workbench file's own top-level
`schemaVersion`). The evidence that it identifies a *content revision*
instead: `EXAMPREP_FLUTTER_ARCHITECTURE.md`'s `QuestionReport` model
carries a `questionVersion` field specifically so a user's report ("Incorrect
answer", "Outdated information", etc.) records *which revision* of a
question's content they saw, separate from the package-level
`contentVersion` — the exact purpose of a content-revision identifier, not
a serialization concern. `content_validation.dart` also validates
`question.version` as required, alongside `sourceVersion`, as part of
`invalid_question_versioning` — grouped with a field this document already
treats as material. `version` is therefore **included**: a reviewer who
approved revision `1` of a question did not review revision `2`, even if
every other field happens to look the same at the moment of comparison
(e.g. a revert-then-reapply). Locked in by the "`version` is included"
test in `test/tool/candidate_question_validator_test.dart`.

**How it's computed**: `computeContentFingerprint(Question)`:
1. Builds a Dart map of exactly the material fields above, read from the
   already-*decoded* `Question` object — never from raw JSON text.
2. Canonicalizes it: object keys are sorted recursively (so source key
   order never matters); array/list order is preserved (so answer and
   reference order remains material, since it can change which option a
   candidate reads first).
3. Re-serializes that canonical structure to JSON, prefixes it with the
   domain-separation string `danb-rhs-question-approval:v1` (so this hash
   could never collide with a SHA-256 computed for an unrelated purpose),
   and hashes the UTF-8 bytes with SHA-256.

Because canonicalization and hashing both operate on decoded structured
data, the result is identical regardless of the source JSON's key order or
whitespace, and changes whenever any material field's *value* changes.

**How staleness is detected**: for every `approve` decision in
`reviewer_decisions.json`, the validator recomputes the fingerprint of the
*current* candidate text with that `id` and compares it — but only after
first checking the decision's own `contentFingerprintAlgorithm`:
- Algorithm is not `sha256-canonical-json-v1` → **unsupported approval
  algorithm** — never trusted, regardless of whether the raw fingerprint
  string happens to match; see below.
- Algorithm matches, fingerprint matches → **human-approved and
  fingerprint-matched** — counts toward promotion eligibility (and, once
  promoted into bundled content, the diagnostic readiness count).
- Algorithm matches, fingerprint differs → **stale approval** — reported
  distinctly, does not count toward readiness, and is never silently
  treated as still valid.
- No decision at all → **awaiting human review**.
- A `revise`/`reject` decision exists but no later `approve` → reported as
  **revision requested** / **rejected** respectively.

### Legacy and unsupported algorithms

Every reviewer decision must record its `contentFingerprintAlgorithm`
explicitly — the validator never infers the algorithm from the
fingerprint's length or shape (a 16-character string is not assumed to be
FNV-1a; a 64-character string is not assumed to be SHA-256). A decision
missing this field entirely, or carrying any value other than
`sha256-canonical-json-v1` (including a real prior algorithm identifier,
or the absence of a field at all from a decision written before this
correction), is classified `unsupportedApprovalAlgorithm` and treated as
**not approved** — it requires renewed human review under the current
algorithm before it can count toward anything.

There are currently no real approval records in
`reviewer_decisions.json`, so this has no practical effect today, but the
behavior is deliberate and permanent: **the validator never automatically
rewrites an existing decision** to add or change its algorithm field, and
a clean validator run never upgrades a legacy decision's trust level on
its own. Re-establishing approval always requires an actual human
re-review, recorded as a new decision under the current algorithm.

## Statuses the validator distinguishes

| Status | Meaning |
| --- | --- |
| `invalid` | This candidate itself has a structural validation error (see `CandidateBankReport.issues`) — never treated as reviewable, let alone approved. |
| `awaitingReview` | Structurally valid; no reviewer decision recorded yet. |
| `revisionRequested` | Latest decision for this question is `revise`. |
| `rejected` | Latest decision for this question is `reject`. |
| `approvedAndMatched` | Latest decision is `approve`, under the current fingerprint algorithm, and its fingerprint matches the current candidate text. |
| `staleApproval` | Latest decision is `approve` under the current algorithm, but its fingerprint no longer matches the current candidate text (the question was edited after approval). |
| `unsupportedApprovalAlgorithm` | Latest decision is `approve`, but under a different or missing fingerprint algorithm — e.g. a legacy pre-SHA-256 decision. Never trusted, regardless of the fingerprint value. |

A validator run never writes to `reviewer_decisions.json` and never changes
a candidate's `status` field — it only reads and reports.

## Safe source-storage policy

See `content_workbench/danb_rhs/content_inventory.md` (§5) and
`content_workbench/private_sources/README.md` for the full policy. In
short: a citation is not proof of redistribution rights. Public, clearly
redistributable documents may be committed to this repository as a
deliberate, per-document decision; licensed textbooks, paid training
materials, restricted PDFs, and scans must never be committed merely to
support this workflow — they stay in the reviewer's own authorized private
storage, optionally mirrored locally (never committed) in the git-ignored
`content_workbench/private_sources/` directory. What this repository
always stores is source *metadata* (title, publisher, edition, date,
locator, URL, access note) in each question's `references[]` field, not
the source document itself.

## Validator CLI modes and exit codes

```
dart run tool/validate_candidate_questions.dart               # concise per-issue output
dart run tool/validate_candidate_questions.dart --report      # full human-readable report
dart run tool/validate_candidate_questions.dart --require-ready
```

| Mode | What it checks | Exit `0` | Exit `1` | Exit `2` |
| --- | --- | --- | --- | --- |
| (default) | Workbench structural validation only (schema, IDs, domains, approval-decision integrity) | Structurally valid | Unknown option, missing input file, JSON/schema parse failure, or any structural/approval-integrity error | — (not used in this mode) |
| `--report` | Same as default, plus the full human-readable domain-inventory report and workbench diagnostic-preflight PASS/FAIL | Structurally valid — **even if** workbench approved inventory is not yet sufficient; readiness is printed, not gated | Same as default | — (not used in this mode) |
| `--require-ready` | Everything `--report` does, **plus** evaluates the actual *bundled* production `reviewed_content.json` — counts only questions with `status: approved` there, per domain, against the configured largest-remainder allocation (currently 7/4/4 for a 15-question diagnostic, derived from `freeTier.diagnosticQuestions` and domain weights — never hardcoded) | Structurally valid **and** bundled production content has enough approved questions in every domain | Any validation error (as above) | Validation succeeded, but bundled production approved inventory is insufficient in at least one domain |

`--require-ready` deliberately never counts draft/reviewed/retired bundled
questions, workbench-only reviewer decisions, stale approvals, or
fingerprint-matched-but-unpromoted candidates — only a question's own
`status: approved` inside `assets/content/danb_rhs/reviewed_content.json` counts,
because that is exactly what the shipped diagnostic engine will read.
The bundled `2026.1-reviewed.1` release contains 500 approved questions
and meets the diagnostic allocation. Exit `2` remains the expected result
for a structurally valid bank with insufficient approved inventory.

The CLI's behavior and exit codes are implemented as a plain function,
`runValidatorCli(arguments, {out, err, paths})`, in
`tool/candidate_question_validator.dart` — `main()` in
`tool/validate_candidate_questions.dart` is a thin wrapper that only
assigns `exitCode`. This lets `test/tool/validator_cli_test.dart` exercise
every mode and exit code directly (including synthetic bundled-content
fixtures written to temp files) without spawning a subprocess per case.
