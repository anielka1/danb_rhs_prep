# DANB RHS Prep

An iPhone-first Flutter exam-preparation app built around one promise:
**help candidates understand when they may be ready to pass**.

> **Project status:** active pre-release development. Jira project `PREP`
> is the source of truth for delivery status; GitHub `main` is the source of
> truth for merged code.
>
> DANB RHS Prep is an independent study product. It is not affiliated with,
> endorsed by, or an official product of the Dental Assisting National Board
> (DANB). Readiness and mock-exam results are estimates, not official exam
> results or guarantees.

## Product contract

Version 1 is designed around these non-negotiable rules:

- **accountless by default** — the core study experience must not require login
- **local-first and offline-first** — study data and progress remain usable
  without a network connection
- **configuration-driven** — exam rules belong in `ExamConfig`, not widgets
- **reviewed content only** — production sessions may use only questions with an
  `approved` lifecycle state
- **human approval** — automation may validate or assist review, but may not
  promote a question to `approved`
- **clear architecture boundaries** — UI does not read JSON, SQLite, StoreKit,
  or cloud services directly
- **four-tab product shell** — Home, Practice, Mock Exam, and Progress
- **honest claims** — the app estimates readiness; it never claims that a user
  passed the official exam

The existing screens are a visual prototype. Their warm cream surfaces,
periwinkle actions, navy typography, rounded cards, and calm hierarchy remain
the design reference. Hardcoded scores, timers, questions, progress, and
navigation behavior are not production data.

## Planning and sources of truth

| Area | Authoritative source |
| --- | --- |
| Scope, priority, dependencies, assignee, and current task status | Jira project `PREP` |
| Merged implementation | GitHub `main` |
| Reviewable work and test evidence | GitHub pull requests linked to a `PREP-###` issue |
| Architecture boundaries | [Flutter architecture](EXAMPREP_FLUTTER_ARCHITECTURE.md) |
| Product behavior and screen contracts | [Product and screen specification](EXAMPREP_PRODUCT_AND_SCREEN_SPEC.md) |
| Delivery sequence and release gates | [App Store roadmap](docs/DANB_RHS_APP_STORE_ROADMAP.md) |
| Question governance and readiness gates | [Content workflow](docs/content/README.md) |

The Jira plan contains **18 epics, numbered 00–17**. This README summarizes the
repository evidence and working agreement; it does not replace the detailed
acceptance criteria, test plans, dependencies, and Claude Code/Codex prompt in
each Jira task.

If Jira and the repository disagree, first verify the implementation and test
evidence, then update Jira. The existence of a file or screen is not enough to
mark a task done.

## Jira status definitions

| Status | Meaning |
| --- | --- |
| `TODO` | Required behavior is not implemented or has no acceptable evidence. |
| `BLOCKED` | Work cannot be completed until a named dependency or gate is resolved. |
| `IN PROGRESS` | Implementation has started but the Definition of Done is not met. |
| `REWORK` | Something exists, but audit evidence shows it is incorrect, incomplete, unsafe, or still prototype-only. |
| `VERIFY` | The implementation appears present, but automated or manual evidence is incomplete. |
| `DONE` | Scope and acceptance criteria are complete, tests/builds are green, evidence is attached, documentation is current, and the change is merged to `main`. |

## Audited delivery snapshot

This is the Jira import snapshot based on
`anielka1/danb_rhs_prep@f5ca3ad9`, audited on **2026-09-02**. Jira remains the
live source of truth after this date.

| Phase | Epic | Snapshot |
| ---: | --- | --- |
| 00 | Security, repository, and process quality | 2 REWORK, 11 TODO |
| 01 | Apple, business, and legal foundations | 9 DONE, 5 TODO |
| 02 | Domain architecture and boundaries | 9 DONE, 1 IN PROGRESS |
| 03 | Design system and app shell | 10 DONE, 1 REWORK, 3 VERIFY |
| 04 | Existing prototype audit and repair | 9 REWORK, 4 VERIFY, 3 TODO |
| 05 | Professional question bank | 4 DONE, 9 BLOCKED |
| 06 | Local database and reliability | 11 TODO |
| 07 | Bootstrap and basic onboarding | 6 DONE |
| 08 | Diagnostic and initial result | 8 BLOCKED |
| 09 | Practice | 14 TODO |
| 10 | Home, Progress, and Readiness | 16 TODO |
| 11 | Mock Exam | 12 TODO |
| 12 | Payments and StoreKit | 3 IN PROGRESS, 13 TODO |
| 13 | Settings, legal, and support | 1 DONE, 8 TODO |
| 14 | Localization, privacy, and product operations | 12 TODO |
| 15 | Automated tests and quality gates | 1 DONE, 8 TODO |
| 16 | iOS, TestFlight, and App Store | 1 DONE, 1 REWORK, 11 TODO |
| 17 | Controlled launch and maintenance | 10 TODO |

Snapshot totals: **41 DONE, 4 IN PROGRESS, 13 REWORK, 7 VERIFY, 17 BLOCKED,
and 134 TODO — 216 tasks in total.**

## What exists today

The repository already contains meaningful foundations:

- immutable exam, domain, topic, mock, readiness, entitlement, and product models
- immutable question, answer, reference, lifecycle, and versioning models
- repository interfaces that keep domain code independent from persistence
- a versioned JSON content loader and codec
- deterministic content validation with structured errors and warnings
- a content-review workflow with provenance, fingerprints, and audit artifacts
- semantic theme tokens, shared UI components, and the four-tab shell
- bootstrap plus welcome, exam-date, and experience-level onboarding
- automated model, validator, content, and widget tests

The product is **not release-ready**:

- the bundled sample bank contains draft content and no production-approved
  question set
- diagnostic readiness is blocked until the approved pilot contains at least
  7 Radiation Safety, 4 Infection Prevention, and 4 Patient Care questions
- full mock delivery requires at least 75 approved questions plus operational
  reserve capacity
- durable Drift/SQLite persistence is not implemented
- Practice, Home/Progress, and Mock Exam still contain prototype behavior or
  hardcoded values
- StoreKit purchase and restore flows are not complete
- CI, branch protection, release automation, and several manual accessibility
  checks remain open

## Critical delivery path

Work should normally proceed in this order, while independent tasks may run in
parallel:

1. Close Phase 00 security, secret-handling, CI, and branch-protection gates.
2. Resolve legal/source ownership and qualified reviewer prerequisites from
   Phases 01 and 05.
3. Finish Phase 02–04 verification and rework so new features build on stable
   architecture, design primitives, and truthful UI.
4. Approve the minimum diagnostic pilot through the human review workflow.
5. Implement Phase 06 durable local persistence and recovery behavior.
6. Deliver Diagnostic, Practice, Home/Progress, and Mock Exam in dependency
   order.
7. Complete StoreKit only against real entitlements and production flows.
8. Pass automated, accessibility, privacy, TestFlight, and App Store release
   gates before controlled rollout.

A blocked feature should not be bypassed with mock production data, random
scores, empty callbacks, or hardcoded success paths.

## Jira-to-GitHub workflow

1. Pick the highest-priority unblocked Jira task and read its dependencies,
   acceptance criteria, test plan, and agent prompt.
2. Verify the claimed state against the latest `main`; do not assume the Jira
   label or an older roadmap is still correct.
3. Create a focused branch such as `feature/PREP-123-short-name`,
   `fix/PREP-123-short-name`, or `docs/PREP-123-short-name`.
4. Implement the smallest complete change, including relevant edge cases and
   tests. Preserve domain/repository/UI boundaries.
5. Run the applicable local checks and record their actual output.
6. Open a PR whose title or body contains `PREP-123`. Include changed behavior,
   test evidence, risks, privacy/accessibility decisions, and rollback steps.
7. Merge only after required checks and review pass, then update the Jira task
   and attach the PR/test evidence.

Do not weaken tests, lint rules, validators, or content gates to make a task
green. Do not mix unrelated cleanup into the same PR.

## Local setup

Flutter stable with Dart 3.3 or newer is required.

```bash
flutter pub get
flutter run
```

## Quality checks

Run the checks applicable to every code change:

```bash
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
```

Validate candidate question content with:

```bash
dart run tool/validate_candidate_questions.dart --report
```

The production content gate must also pass before a diagnostic or release bank
is accepted:

```bash
dart run tool/validate_candidate_questions.dart --require-ready
```

That command is expected to remain blocked while the professionally reviewed
approved bank is below the configured minimums. Never change the thresholds or
lifecycle state merely to force a passing result.

Release-related tasks must additionally run the build named in their Jira
acceptance criteria. Never report a format, analysis, test, or build as passing
unless it was actually executed.

## Continuous integration

`.github/workflows/ci.yml` runs the same quality checks above automatically
on every pull request targeting `main`, every push to `main`, and on-demand
via `workflow_dispatch`. The `quality` job runs on a pinned Flutter version
(matching `.metadata`, not an unpinned `stable` float) with `contents: read`
permissions and cancels superseded runs on the same ref. It executes, in
order: `flutter pub get`, the formatting check, `flutter analyze`,
`flutter test`, the content-workbench validator in `--report` mode (not
`--require-ready` — the approved question bank does not yet meet that gate,
so requiring it would block all merges), and `git diff --check`. CI does not
build the iOS app; that remains a required local pre-merge/pre-release step
and a separate, not-yet-implemented workflow.

A separate `secret-scan` job runs [gitleaks](https://gitleaks.io/) (a pinned,
checksum-verified binary, not a third-party marketplace Action) against the
full working tree and commit history on the same triggers, and fails the
build if it finds anything — secret values are redacted from its output, and
nothing it scans is sent to any external service.

## Content and compliance rules

- Do not copy, reconstruct, solicit, or store recalled live exam questions.
- Every candidate question needs traceable sources and deterministic review
  artifacts.
- Only a qualified human reviewer may approve clinical correctness and promote
  content to `approved`.
- AI-generated suggestions remain draft until the same review process is
  complete.
- Keep trademarks, independence disclosures, privacy statements, and support
  information accurate in the app and store metadata.
- Treat readiness, predictions, and mock results as educational estimates.

## Security

Never commit API tokens, signing material, passwords, personal data, or private
keys. Use environment variables, the operating-system keychain, or an approved
secret manager locally, and encrypted repository/environment secrets in CI. If
a credential is exposed, revoke and rotate it immediately, review access logs,
and record only the rotation date and owner—not the secret value.
