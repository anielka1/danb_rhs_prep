# Simple Supabase question review

The current Supabase workbench uses a deliberately small manual review record.
The reviewer works in Supabase Studio's Table Editor. No reviewer name,
credential, fingerprint, checklist, or separate decision vocabulary is stored
in this database workflow.

This workflow does not make approval automatic: the person changing the row is
responsible for checking the question and its cited source before approving it.

## Tables used during review

All review data remains in the private `content_workbench` schema.

- `questions` — question text, correct answer ID, explanation, status and tags.
- `answers` — four answer options, filtered by `question_id`.
- `question_references` — source metadata and URL, filtered by
  `question_id`.
- `reviewer_decisions` — one simple review row per question.

The editable fields in `reviewer_decisions` are:

| Field | Use |
| --- | --- |
| `question_id` | Exact ID from `questions`. One row is allowed per question. |
| `approved` | Set to `true` only after checking the complete question and source. |
| `notes` | Optional correction or review notes. |

The database manages `approved_at`, `id`, and `created_at` automatically.

## Approve a question

1. In Table Editor, choose schema `content_workbench` and table `questions`.
2. Open one question whose `status` is `draft`.
3. In `answers`, filter `question_id` to the same ID and check all four
   options and the marked `correct_answer_id`.
4. In `question_references`, filter to the same ID, open the source URL, and
   confirm that the source supports the correct answer and explanation.
5. In `reviewer_decisions`, insert a row with the question ID,
   `approved = true`, and any useful notes.
6. Save the row.

On save, the database automatically:

- sets `approved_at` to the current time; and
- changes the matching question's `status` to `approved`.

## Return a question to draft

Open its existing row in `reviewer_decisions`, set `approved = false`, add
the reason to `notes`, and save. The database clears `approved_at` and
returns the matching question to `draft`.

Deleting the review row also returns the question to `draft`.

## Publication remains separate

Approval does not publish a question to the mobile app. A release still has to
be assembled, validated, checksummed, and inserted into
`public.question_bank_releases`. The Flutter client continues to read only a
published, active release and never reads `content_workbench` directly.
