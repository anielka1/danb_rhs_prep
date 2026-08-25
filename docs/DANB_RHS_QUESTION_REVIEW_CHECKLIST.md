# DANB RHS Question Review Checklist

Audience: the qualified human reviewer evaluating a candidate question
before recording a decision in
`content_workbench/danb_rhs/reviewer_decisions.json`. See
`DANB_RHS_CONTENT_APPROVAL_WORKFLOW.md` for how a decision becomes a
promotable approval, and `DANB_RHS_QUESTION_AUTHORING_GUIDE.md` for what the
author was asked to follow.

Nothing in this checklist is enforced by software. `tool/validate_candidate_
questions.dart` checks structure only (schema shape, IDs, domain
membership) — every item below requires actual human judgment against the
cited source and cannot be automated.

## Per-question checklist

For the exact question ID and content version (fingerprint) being reviewed:

- [ ] **Original content** — not a copied or closely paraphrased DANB exam
      item, recalled exam question, proprietary question-bank item,
      commercial prep-app item, or copyrighted textbook question.
- [ ] **Correct domain assignment** — `domainId`/`topicId` genuinely match
      what the question tests, per the current blueprint in `content.json`.
- [ ] **Blueprint relevance** — the question tests a competency actually
      within the domain's configured topic list, not adjacent trivia.
- [ ] **Factual accuracy** — every claim in the stem, correct answer, and
      distractors is checked directly against the cited source, not against
      the reviewer's own memory.
- [ ] **Source authority and currency** — the cited reference is
      authoritative (matches the accepted-source list) and current (not a
      superseded edition/guideline version).
- [ ] **Answer is unambiguously correct** — no other option could be
      reasonably defended as correct or "more correct" given the stem as
      written.
- [ ] **Distractors are incorrect but plausible** — each wrong answer is a
      believable mistake a real candidate might make, not a throwaway.
- [ ] **Explanation is accurate** — the explanation's reasoning is correct
      and actually supports the marked correct answer, not just restates it.
- [ ] **Terminology is consistent** — matches the vocabulary already used
      elsewhere in the bank for the same concept.
- [ ] **No jurisdiction ambiguity** — any regionally variable rule is either
      scoped explicitly in the stem or the question avoids relying on it.
- [ ] **No accessibility or bias concern** — stem and options are free of
      culturally specific assumptions, exclusionary framing, or content
      that would disadvantage a reader unfamiliar with a narrow context
      unrelated to the tested competency.
- [ ] **No misleading safety guidance** — nothing in the stem, distractors,
      or explanation could be read, out of context, as endorsing an unsafe
      clinical or radiographic practice.
- [ ] **Source verified** — the reviewer personally opened/confirmed the
      cited section/page/anchor and confirms it says what the question
      claims it says. The source itself may live in the reviewer's own
      authorized private storage rather than in this repository (see the
      safe source-storage policy in `content_workbench/danb_rhs/
      content_inventory.md`) — verification means the reviewer actually
      checked it, not that a copy is committed here.

## Reviewer decision

- [ ] **Decision**: exactly one of `reject`, `revise`, `approve`.
- [ ] **Reviewer notes**: free text — required for `reject`/`revise`,
      recommended for `approve`.
- [ ] **Reviewer identity**: a real name/credential, entered by the reviewer
      themselves. Never pre-filled or invented on a reviewer's behalf.
- [ ] **Review date**: ISO-8601 date, entered at the time of review.
- [ ] **Content fingerprint + algorithm**: the exact `contentFingerprint`
      (a 64-character lowercase SHA-256 hex digest) reported by
      `tool/validate_candidate_questions.dart --report` for this question
      at the moment of review, together with `contentFingerprintAlgorithm`
      set to `sha256-canonical-json-v1` — recorded explicitly, never
      inferred from the fingerprint's shape. This is what binds the
      decision to the precise text reviewed. If the question is edited
      afterward, the fingerprint changes and this decision becomes stale
      automatically; it does not carry forward to the new text. A decision
      recorded under any other (or missing) algorithm identifier is never
      honored as an approval, no matter what its fingerprint value is —
      see `DANB_RHS_CONTENT_APPROVAL_WORKFLOW.md`.

## Outcomes

- **`reject`** — the question is factually wrong, unfixable in scope, or
  otherwise unsuitable. It stays in the workbench, unpromotable, as a
  record of what was tried and why it failed.
- **`revise`** — the question has a specific, fixable problem. Reviewer
  notes must describe exactly what needs to change. The author edits the
  candidate (which changes its fingerprint), and it re-enters the queue for
  a fresh review.
- **`approve`** — the question is correct, sourced, and ready. The decision
  record's fingerprint locks in the exact text approved. Only an
  `approve` decision under the current fingerprint algorithm whose
  fingerprint still matches the current candidate text counts toward
  promotion eligibility. Promotion eligibility alone still isn't
  production readiness, though — a fingerprint-matched workbench approval
  only counts toward the diagnostic readiness check (currently 7/4/4,
  derived from configuration, not hardcoded) once a human has manually
  promoted the question into `assets/content/danb_rhs/content.json`; see
  `--require-ready` in `DANB_RHS_CONTENT_APPROVAL_WORKFLOW.md`.
