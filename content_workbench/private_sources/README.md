# Private Sources (local-only, never committed)

This directory is an **optional local workspace** for a qualified reviewer's
own legitimately obtained source material — licensed textbooks, paid
training materials, PDF scans of restricted references, or any other
source document used to verify a candidate question's factual accuracy.

## Nothing in this directory should ever be committed

Every file placed here except this README is git-ignored (see the repo
root `.gitignore` rule scoped to this exact path). That is deliberate, not
a bug to work around:

- A citation is not proof that this application — or this repository — may
  redistribute the source. Owning a copy, or having a license to *read* a
  copy, is not the same as having the right to publish that copy to every
  future clone of this repository, public or private.
- Licensed textbooks, paid training materials, restricted PDFs, and scans
  are almost never redistributable this way, even inside a private
  repository — "private" does not mean "licensed for redistribution," and
  a repository's access list can change.
- Public documents may be committed **elsewhere** in this repository
  (never here) only when redistribution is clearly permitted and keeping a
  copy is genuinely appropriate — that is a separate, deliberate decision
  made per-document, not a default.

## What actually belongs in version control

Not the source file — the **citation metadata** a reviewer needs to find
and re-verify the source themselves:

- title
- publisher/authority
- edition/version
- publication/effective date
- chapter/section/page (or precise URL anchor)
- public URL, when one exists
- access date, when relevant
- a licensing/access note (e.g. "personal license, not for redistribution"
  or "publicly available, redistribution permitted")

That metadata lives in each candidate question's `references[]` field
(see `docs/DANB_RHS_QUESTION_AUTHORING_GUIDE.md`) and in
`content_workbench/danb_rhs/content_inventory.md` — not in this directory.

## Using this directory

If it's useful to keep a personal working copy of a source on this
machine while reviewing candidate questions, put it here. It stays local,
never gets staged, and never leaves this machine through this repository.
Nothing in the content-authoring or approval tooling reads from this
directory — it exists purely as a convenience for a human reviewer's own
workflow.

Questions themselves must still be original: authored from the source's
*facts*, not copied or closely paraphrased from the source's *wording*
beyond what is legally and academically necessary (e.g. a short verbatim
definition with attribution). See the authoring guide's rule against
copying source wording beyond what's necessary.
