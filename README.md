# DANB RHS Prep

An iPhone-first Flutter exam-preparation application built around one promise:
**know when you're ready to pass**.

The existing screens are a visual prototype. Their warm cream surfaces,
periwinkle actions, navy typography, rounded cards, and calm visual hierarchy
remain the design reference; their hardcoded content and product behavior are
not application data.

## Product architecture

The production direction is local-first and configuration-driven:

- exam rules live in `ExamConfig`
- questions are imported from versioned JSON rather than embedded in widgets
- only `approved` questions can enter production sessions
- domain logic stays independent from screens and persistence plugins
- a second exam should require configuration, validated content, and assets—not
  a rewrite of navigation or study engines

The detailed decisions are documented in
`EXAMPREP_FLUTTER_ARCHITECTURE.md` and
`EXAMPREP_PRODUCT_AND_SCREEN_SPEC.md`.

## Current implementation phase

Phase 1 foundation now includes:

- immutable exam, domain, topic, mock, readiness, free-tier, and product models
- immutable question, answer, reference, lifecycle, and versioning models
- a bundled JSON content loader and codec
- deterministic content validation with structured errors and warnings
- a development DANB RHS content package based on the current official outline
- automated validation and codec tests

The sample questions remain `draft`; they are excluded from production sessions
until professionally reviewed and explicitly promoted to `approved`.

## Run checks

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Flutter stable with Dart 3.3 or newer is required.
