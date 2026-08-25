# DANB RHS Content Inventory & Source-Material Gate

Status: **gate failed for all three configured domains — no candidate questions
drafted.** This document is the record of that check. It is re-run (and this
file updated) every time new source material becomes available.

## 1. Source inventory

Every source found by inspecting the repository (`assets/content/`, `docs/`,
`lib/`, and the root-level product/architecture specs) for exam-blueprint or
clinical/technical reference material.

| Source | Authority | Version/date | Domains supported | Sufficient for factual validation? |
| --- | --- | --- | --- | --- |
| `exam.domains[]` structure inside `assets/content/danb_rhs/content.json` (domain/topic IDs and blueprint weights) | Derived from the DANB RHS exam outline — structural taxonomy only, not the outline document itself | Labeled `sourceVersion: "danb-rhs-outline-effective-2025-03-12"`; the outline document this was derived from is not present in the repo to verify | `purpose_technique`, `radiation_protection`, `infection_control` (domain/topic naming and weights only) | **No** — establishes domain IDs, topic IDs, and blueprint weights for allocation purposes; contains no clinical, technical, or procedural detail a question could be checked against |
| `rhs-dev-001`/`rhs-dev-002` questions' `references[].title/source/url` fields (e.g. "RHS Exam Outline and References", `https://www.danb.org/exams/exam/rhs-exam`) | Points to DANB's public exam page | Not fetched, bundled, or dated in this task | `purpose_technique`, `radiation_protection` (the two domains these two draft questions happen to touch) | **No** — a citation pointing at a URL is not source content; nothing at that URL has been retrieved, licensed, or bundled into the repo for this task |
| `docs/PROTOTYPE_CONTENT_AUDIT.md` | Internal engineering audit | 2026 (this project) | None (UX/content-source tracking, not clinical) | No — confirms only that real content authoring hasn't happened yet |
| `EXAMPREP_PRODUCT_AND_SCREEN_SPEC.md`, `EXAMPREP_FLUTTER_ARCHITECTURE.md`, `docs/DANB_RHS_APP_STORE_ROADMAP.md` | Internal product/engineering specs | 2026 (this project) | None (product scope, screens, architecture — not clinical) | No |
| Official DANB RHS exam outline (full document) | DANB | — | — | **Not present in the repository** |
| CDC dental infection-control guidance | CDC | — | — | **Not present in the repository** |
| FDA/ADA dental radiography guidance | FDA/ADA | — | — | **Not present in the repository** |
| Recognized dental-radiography textbook/training material | — | — | — | **Not present in the repository** |

No PDFs, licensed documents, or reference text of any kind exist anywhere in
this repository beyond the structural JSON above. Nothing under
`assets/`, `docs/`, or elsewhere constitutes a usable clinical or technical
source.

## 2. Gate result

Per the mandated rule — *"the public exam outline may establish domains and
weights, but an outline alone is not sufficient evidence for detailed
clinical facts"* — the only material found (the domain/topic/weight
structure) is explicitly insufficient on its own, and no domain has any
additional authoritative source behind it.

| Domain | Authoritative source present? | Gate result |
| --- | --- | --- |
| `purpose_technique` (Purpose and Technique) | No | **Blocked** |
| `radiation_protection` (Radiation Characteristics and Protection) | No | **Blocked** |
| `infection_control` (Infection Prevention and Control) | No | **Blocked** |

**All three domains are blocked.** No candidate questions were drafted from
general model knowledge, per the explicit instruction not to invent clinical
facts from memory.

## 3. Existing draft inventory (unchanged)

| Question ID | Domain | Status | Action taken |
| --- | --- | --- | --- |
| `rhs-dev-001` | `radiation_protection` | `draft` | None — left unchanged, no factual/structural defect reported |
| `rhs-dev-002` | `purpose_technique` | `draft` | None — left unchanged, no factual/structural defect reported |

## 4. Candidate drafting outcome

| Domain | Draft target | Candidates drafted this task | Remaining gap |
| --- | --- | ---: | ---: |
| `purpose_technique` | 14 | 0 | 14 |
| `radiation_protection` | 8 | 0 | 8 |
| `infection_control` | 8 | 0 | 8 |
| **Total** | **30** | **0** | **30** |

`content_workbench/danb_rhs/candidate_questions.json` is a valid, empty
starter template (`"candidates": []`) — the pipeline, schema, and tooling
around it are ready to receive real candidates the moment sourcing exists.

## 5. What must be supplied before drafting can resume

For **each** domain, a qualified reviewer needs access to one or more of
the acceptable source types. **How that source is made available depends
on its licensing — it does not automatically mean committing the document
to this repository.** See the safe source-storage policy below.

- **`purpose_technique`**: the official DANB RHS exam outline (full text, not
  just the domain/topic list already present) and/or a recognized dental
  radiography textbook or training manual covering image acquisition
  technique, error correction, and patient management.
- **`radiation_protection`**: FDA/ADA dental radiography guidance and/or a
  radiation physics/biology reference covering the specific topics already
  named in the blueprint (`radiation_physics`, `radiation_biology`,
  `patient_operator_protection`).
- **`infection_control`**: current CDC dental infection-control guidance
  (or the equivalent OSAP/ADA summary) — this domain has no content at all
  today, drafted or otherwise, so it needs source material before any
  question — even a first draft — can be written responsibly.

### Safe source-storage policy

A citation is not proof that this application may redistribute the
source, so where a source *lives* depends on its licensing:

- **Committable to this repository**: only when redistribution is clearly
  permitted (e.g. a genuinely public-domain or openly licensed document)
  *and* keeping a repository copy is genuinely appropriate — that is a
  deliberate, per-document decision, never a default.
- **Never committed merely to support this workflow**: licensed textbooks,
  paid training materials, restricted PDFs, and scans. CDC guidance is
  generally public and citable by URL; a purchased radiography textbook or
  a DANB outline distributed under restrictive terms is not something to
  paste into version control just because a reviewer has legitimate access
  to it.
- **What this repository stores regardless**: source *metadata* — title,
  publisher/authority, edition/version, publication/effective date,
  chapter/section/page (or URL anchor), public URL when available, access
  date, and a licensing/access note — recorded in each candidate
  question's `references[]` field, not the source document itself.
- **Where a restricted source actually lives**: in the reviewer's own
  authorized private storage (their own licensed copy, their
  organization's document system, or — for a personal local working copy
  only — the git-ignored `content_workbench/private_sources/` directory;
  see its `README.md`). Never committed.
- Regardless of where sourcing lives, questions must remain original —
  written from the source's *facts*, not copied or closely paraphrased
  from the source's *wording* beyond what is legally necessary.

Once a reviewer has access to adequate sourcing for a domain (by whichever
appropriate means — committed public document, personal license, or
organizational access), re-run this inventory, re-derive the table in
Section 2, and drafting can proceed domain-by-domain as sourcing becomes
sufficient (a domain does not need to wait for the others).
