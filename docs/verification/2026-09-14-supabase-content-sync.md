# Supabase content synchronization verification — 2026-09-14

Base: `main` / `origin/main` at `97f1e97` (verified again before PR).
Branch: `feature/supabase-content-sync`. No merge. No hosted workflows dispatched;
commit and PR use `[skip ci]` under the zero-budget policy.

## Scope and server inspection

- Read-only inspection confirmed `public.question_bank_releases` columns,
  constraints, SELECT policy, RLS and anon read access in `danb-rhs-prep`.
- A read under `SET LOCAL ROLE anon` returned `visible_releases: 0`.
- Both `anon` and `authenticated` have no USAGE on `content_workbench`.
- No remote table, grant, policy, function, release or reviewer decision was
  changed. No actual key was retrieved, committed or logged.
- Local progress schema remains 5; content uses a separate schema-1 SQLite file.
  An integration test compares every existing progress table before and after
  download, activation and bootstrap, including saved diagnostic history,
  bookmarks and profile settings.

## Regression evidence

Targeted suite after fixes: **34 passed**, including the updated production
bootstrap wiring. Fakes cover disabled configuration, offline/server errors,
empty releases, new/old/identical releases, invalid metadata/checksum/schema/JSON,
unapproved content, failed domain validation, insert/activation rollback, corrupt
cache fallback, actual file close/reopen, active practice/mock answer order,
legacy sessions and later activation after completion. No fixture is published.

New integration-level failures reproduced before their fixes:

- Unreadable progress originally selected bundled `2026.1-dev` instead of the
  previously activated `fixture-1`. It now keeps the activated bank and postpones
  activation, without treating failed session reads as an empty history.
- The real SDK built `//rest/v1/...` with a trailing-slash base URL; URLs are now
  normalized. The SDK also issued four requests despite client-level retry=false;
  applying retry=false/count=0 and timeout to the final builder produces one.
  The HTTP interception test stops before any socket and checks the exact public
  release endpoint, GET method, publication/exam/retirement filters, ordering and
  limit. It does not contact Supabase.

No golden files, validator thresholds, existing correctness assertions, question
content/statuses, reviewer records or fingerprint implementation were changed.
The runtime-dependency allowlist was extended only for the two explicitly used
non-UI packages; the UI-library prohibition remains enforced.

## Final required checks

Local Lima Linux VM, Flutter 3.41.2 / Dart 3.11.0, final source tree:

| Command | Actual result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | `Formatted 281 files (0 changed)`, exit 0 |
| `flutter analyze` | `No issues found!`, exit 0 |
| `flutter test` | **1122 passed, 1 existing skipped**, `All tests passed!`, exit 0 |
| `flutter test --dart-define=dart.vm.product=true test/debug/demo_entrypoint_mode_test.dart` | 1 passed, exit 0 |
| `flutter test --dart-define=dart.vm.profile=true test/debug/demo_entrypoint_mode_test.dart` | 1 passed, exit 0 |
| `dart run tool/validate_candidate_questions.dart --report` | Structurally valid, 0 errors / 0 warnings, 26 awaiting review, exit 0 |
| `git diff --check` and `git diff --cached --check` (host repository) | No output, exit 0 |

The report correctly retains failed content-readiness preflight (zero approved
questions). Structural validity is not clinical approval or publication readiness.
The full suite includes the unmodified Linux golden comparisons. Multiple
independent content databases in tests produce Drift's debug warning about
multiple instances; they have separate executors and are closed in teardown.

## Native build limitation

`flutter build ios --release --no-codesign` was attempted locally and **did not
complete**. First `pod install` failed with EPERM writing the CocoaPods cache.
A second attempt using `CP_CACHE_DIR=/private/tmp/rhs-cocoapods-cache` got further,
but SQLite's configure step failed with:

```
Error: couldn't create error file for command: not owner
Error running pod install
```

No successful native compile, simulator run or device offline test is claimed.
Run from the normal macOS Terminal on this branch:

```bash
flutter pub get
flutter build ios --release --no-codesign
```

Then follow the [manual offline procedure](../SUPABASE_CONTENT_SYNC.md#manual-offline-checks).
A real positive release remains untested because the production table is empty.
The first human-approved publisher must confirm the documented canonical checksum
contract; the existing table has no established hash algorithm/example to compare.

## Changed files

- `README.md`
- `config/supabase.example.json`
- `docs/DANB_RHS_CONTENT_APPROVAL_WORKFLOW.md`
- `docs/SUPABASE_CONTENT_SYNC.md`
- `lib/features/content/sync/content_release.dart`
- `lib/features/content/sync/content_release_database.dart`
- `lib/features/content/sync/content_release_database.g.dart`
- `lib/features/content/sync/remote_content_source.dart`
- `lib/features/content/sync/supabase_remote_content_source.dart`
- `lib/features/content/sync/synced_content_repository.dart`
- `lib/main.dart`
- `linux/flutter/generated_plugin_registrant.cc`
- `linux/flutter/generated_plugins.cmake`
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `pubspec.lock`
- `pubspec.yaml`
- `test/bootstrap/production_wiring_test.dart`
- `test/content_sync/content_sync_test.dart`
- `test/content_sync/supabase_source_test.dart`
- `test/design_system/no_parallel_ui_library_test.dart`
- `tool/content_release_checksum.dart`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`
- `docs/verification/2026-09-14-supabase-content-sync.md` (this evidence).
