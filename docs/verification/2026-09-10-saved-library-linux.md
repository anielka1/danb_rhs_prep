# PR #62 local Linux verification

Tested source commit: `238e992ad9611887f79f8d4b1fb672e5b04fcba1`.
Environment: local Lima VM, Ubuntu 24.04 aarch64, Flutter 3.41.2.
Packages: curl, unzip, xz-utils, libgtk-3-0, libglu1-mesa, sqlite3,
libsqlite3-dev. The latter is needed for Dart FFI's `libsqlite3.so` lookup.
GitHub Actions was not used because the user requires zero GitHub spending.

## Results

- Before updating screenshots: 28 exact golden matches; only the four
  intentionally changed Home images differed.
- Generated four Home baselines, visually reviewed light/dark at normal/AX5.
- `dart format --output=none --set-exit-if-changed lib test tool`: 229 files,
  0 changed, exit 0.
- `flutter analyze`: No issues found, exit 0.
- Fresh `flutter test`: **1001 passed, 1 skipped, zero failures**, exit 0,
  including all 32 exact golden comparisons.
- `flutter test --dart-define=dart.vm.product=true test/debug/demo_entrypoint_mode_test.dart`:
  1 passed, exit 0.
- Equivalent `dart.vm.profile=true` check: 1 passed, exit 0.
- `dart run tool/validate_candidate_questions.dart --report`: exit 0,
  structurally valid, 0 errors, 0 warnings. Production diagnostic readiness
  remains FAIL (no approved inventory); this is not a production content approval.
- Whole-tree whitespace/conflict-marker check and patch whitespace check: passed.
- SHA-256 comparison verified every tested source, test, tool and golden image
  matches the local PR tree; only documentation added after testing differs.

The first full VM test attempt failed because libsqlite3-dev was missing.
Installing that system dependency and repeating the unchanged tests produced
all results above; no assertion, content gate or pixel comparator was relaxed.

## Remaining build check

The restricted agent environment cannot complete Xcode's workspace build.
A local terminal build outside that sandbox is still required:

```sh
cd ~/flutter_projects/danb_rhs_prep
flutter build ios --release --no-codesign
```

Physical-device and VoiceOver testing are separate from this unsigned build.
