# DANB RHS Question Authoring Guide

Audience: anyone (human or AI-assisted) drafting **candidate** questions for
the DANB RHS content bank. Candidates live in
`content_workbench/danb_rhs/candidate_questions.json` and are never bundled
into the production app until a qualified human reviewer promotes them —
see `DANB_RHS_CONTENT_APPROVAL_WORKFLOW.md`.

## 0. Before drafting anything

Check `content_workbench/danb_rhs/content_inventory.md`. A question may only
be drafted for a domain whose gate has **passed** — i.e. an authoritative,
current, legally usable source is available to the reviewer for that
domain. "Available" does not necessarily mean "committed to this
repository" — see the safe source-storage policy in
`content_inventory.md` and `content_workbench/private_sources/README.md`:
a licensed textbook or restricted PDF the reviewer has legitimate access to
counts as available sourcing even though it should never be committed;
only genuinely redistributable public documents belong in the repository
itself. If the inventory shows a domain blocked, do not draft for it, no
matter how confident the author is in the fact from general knowledge.
This guide describes *how* to write a question once sourcing exists; it
does not override the sourcing gate.

## 1. Required fields for every candidate

Each candidate question must provide, at minimum, everything the production
`Question` schema (`lib/features/questions/domain/question.dart`) requires,
plus the workbench's own review fields:

| Field | Requirement |
| --- | --- |
| `id` | Unique, stable, never reused or renumbered once assigned. Recommended form: `rhs-cand-<domainId>-<sequence>`, e.g. `rhs-cand-infection_control-001`. Must not collide with any ID already in `assets/content/danb_rhs/content.json`. |
| `examId` | Must be `danb_rhs`. |
| `domainId` | Must be one of the exam's currently configured domain IDs (`exam.domains[].id` in `content.json`) — never invented. |
| `topicId` | Must be one of that domain's configured topic IDs. |
| `status` | Always `"draft"` for anything authored here — see the human-approval boundary below. |
| `questionText` | A single, clear, focused stem — see authoring rules. |
| `answers` | At least 4 options (house convention — matches both existing sample questions), each with a stable `id` (`"a"`, `"b"`, `"c"`, `"d"`, ...) and non-empty `text`. Option IDs must stay stable even if the on-screen order of options is later randomized or the wording is edited. |
| `correctAnswerId` | Must reference exactly one of `answers[].id`. |
| `explanation` | Explains *why* the correct answer is correct, in enough depth for a subject-matter reviewer to check it against the cited source without re-deriving it themselves. |
| `references` | At least one `{title, source, section, url?}` entry identifying the authoritative source, its edition/version/date, and the specific section, chapter, page, or URL anchor the fact came from. A reference naming only a publisher with no locator (no section/page/anchor) is not acceptable. |
| `difficulty` | 1–5, per the existing schema. |
| `version` | Starts at `1`; increment on any material edit (see fingerprinting, below). |
| `sourceVersion` | Identifies which authoritative source version this question was drafted against (e.g. `"cdc-dental-ic-summary-2016"`). |
| `tags` | Free-form, optional; use for topic cross-referencing, not for review status. |

## 2. Authoring rules

- Use plain, professional language. No slang, no rhetorical flourishes.
- One unambiguously best answer. If a reviewer could defend two options as
  correct, the question needs rewriting, not a note explaining the
  "intended" answer.
- Avoid trick questions — the question should test whether the candidate
  knows the material, not whether they can spot a wording trap.
- Avoid double negatives ("Which of the following is NOT an example of a
  technique that does not reduce patient dose?").
- Never use "All of the above" or "None of the above" as an option.
- Avoid clues from answer length, grammar, or specificity — distractors
  should read as naturally as the correct answer, not shorter/vaguer/
  grammatically mismatched with the stem.
- Avoid unnecessarily frightening or graphic clinical scenarios — test the
  competency, not the reader's nerves.
- Avoid trivia unrelated to the configured blueprint (a domain's `topics[]`
  list in `content.json` is the scope; don't drift outside it).
- Distractors must be clearly, checkably wrong, and the explanation must say
  *why* — a distractor must never describe an unsafe practice without the
  explanation immediately clarifying it is unsafe. A candidate reading only
  the distractor text (e.g. skimming after guessing wrong) must not walk
  away having absorbed a dangerous technique as if it were plausible advice.
- Keep terminology consistent with the rest of the bank (e.g. don't
  alternate between "receptor" and "sensor" for the same concept across
  questions without reason).
- Avoid duplicate learning objectives unless deliberate and documented in
  `tags` — the bank should cover breadth within each domain's topic list,
  not repeatedly test the same fact.
- No unsupported pass-rate or exam-frequency claims anywhere in the
  question, explanation, or reference ("this appears on 30% of exams" is
  never acceptable — nothing in this repo can substantiate that claim).
- No jurisdiction-specific rule presented as universal. If a regulation
  varies by state/region, either the stem must scope it explicitly or the
  question shouldn't be asked as a single-best-answer item.
- No recalled, copied, or closely paraphrased DANB exam content, proprietary
  question-bank content, commercial prep-app content, or copyrighted
  textbook question content. Every candidate must be original material
  written from the cited authoritative source's *facts*, not from someone
  else's *test item* built on those facts.

## 3. Human-approval boundary

Content produced by an author (including AI-assisted drafting) may only
ever be written with `"status": "draft"`. Never set `"reviewed"` or
`"approved"` on a candidate directly — those transitions happen only through
a recorded human decision in `reviewer_decisions.json`
(`DANB_RHS_CONTENT_APPROVAL_WORKFLOW.md`). A clean run of
`tool/validate_candidate_questions.dart` proves structural validity; it is
never itself an approval and must never be treated as one.

## 4. Editing an existing candidate

Any material edit invalidates any existing human approval for that
question, because the approval record is bound to a content fingerprint
computed over the material fields — the complete list is: `id`,
`domainId`, `topicId`, `questionText`, `answers` (option IDs and text, in
order), `correctAnswerId`, `explanation`, `references` (in order),
`difficulty`, `sourceVersion`, `tags` (as an unordered set — reordering
tags alone does *not* invalidate approval, but adding/removing/changing
one does), and `version`. Bump `version` on any material edit and expect
the validator to report the prior approval (if any) as stale until
re-reviewed — see the full field list and reasoning in
`DANB_RHS_CONTENT_APPROVAL_WORKFLOW.md`. `status` and `updatedAt` are the
only question fields excluded (see that document for why), so a status
promotion or a metadata touch alone never invalidates an approval on its
own — but this deliberately errs toward "re-review" for everything else,
including a typo fix or a tag addition, over "silently keep an approval
that no longer matches the text a human actually read."
