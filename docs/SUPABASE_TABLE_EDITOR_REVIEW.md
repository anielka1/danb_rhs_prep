# One-table Supabase question review

The complete review queue is stored in
`content_workbench.reviewer_decisions`. It contains one row for every DANB RHS
question, so a reviewer does not need to switch between multiple tables.

Each row shows:

- review number and question ID;
- domain and topic;
- question text;
- answers A, B, C and D;
- the correct answer;
- explanation;
- source title, section and URL;
- `approved`, `approved_at` and `notes`.

No reviewer identity, fingerprint, checklist, or separate decision vocabulary is
stored in this Supabase workflow.

## Approve a question

1. Open Supabase Studio and choose **Table Editor**.
2. Select schema `content_workbench`.
3. Open `reviewer_decisions`.
4. Sort by `review_number` ascending.
5. Read the question, four answers, correct answer and explanation in the same
   row.
6. Open `source_url` and verify the claim against the cited section.
7. If the question is acceptable, set `approved` to `true`.
8. Optionally enter a short comment in `notes`.
9. Save the row.

The database automatically fills `approved_at` and changes the corresponding
row in `questions` to `status = approved`.

## Leave a question unapproved

Leave `approved = false` and put the required correction in `notes`. The
question remains a draft.

## Undo approval

Set `approved` back to `false` and save. The database clears
`approved_at` and returns the matching question to draft.

## Useful filters

- Waiting for review: `approved = false`
- Approved: `approved = true`
- One domain: filter `domain_id`
- Resume work: sort by `review_number`

## Publication remains separate

Approval does not publish questions to the mobile app. A release still has to be
assembled, validated, checksummed, and inserted into
`public.question_bank_releases`. The Flutter client reads only a published,
active release and never reads the private workbench directly.
