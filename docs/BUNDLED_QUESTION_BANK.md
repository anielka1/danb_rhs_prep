# Bundled production question bank

Production loads `assets/content/danb_rhs/reviewed_content.json` through
`BundledContentRepository`. All 500 approved questions are shipped in the app.
No Supabase configuration, download, login, or cached remote release is required
to load questions, start the five-question trial, or create a Premium session.
RevenueCat continues to handle purchases and entitlement refresh separately.

## Provenance

This asset is an unchanged copy of published DANB RHS release 1, content version
`2026.1-reviewed.1`, read from the existing question-bank publication on
2026-10-04. No question was edited or newly approved in this change.
SHA-256 of canonical JSON (sorted object keys, no trailing newline):
`b4b5257952d3b420dbdc6dfeeb96c214f5caa5b14ef3955bf6bf8a52983c3c2e`.
Existing question IDs and content version are preserved for stored progress.

## Updates

Question changes now require a reviewed asset update and a new app release.
Preserve question IDs, run content validation and the production wiring tests,
and verify saved-session compatibility before shipping an updated bank.
The older `content.json` contains development drafts used by negative tests;
it is deliberately excluded from the app's asset manifest. Existing sync
components remain available for tests but are not constructed by `main()`.

## Workbench history

The 26 original workbench drafts have matching IDs and unchanged material
content in published release 1. Their original draft records are preserved
verbatim in `content_workbench/danb_rhs/published_release_1_draft_history.json`
and removed from the active candidate queue to avoid production ID collisions.
This archival step creates no approval record and changes no question status.
The archive is excluded from Flutter assets. Future candidates must use new IDs.
