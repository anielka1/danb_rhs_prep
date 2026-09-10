# Settings, help and readiness review — 2026-09-10

## Implemented

Settings study-plan actions now use icon panels and stronger typography. Appearance uses full-width selected cards with a check indicator. Reset retains confirmation, busy and failure handling, with a distinct error-container treatment. Study help opens a separate, scrollable FAQ screen. Existing plan editing and reset behavior is preserved.

## Diagnostic and readiness findings

A starting diagnostic is not implemented. ExperienceLevelScreen currently completes onboarding into Home. The candidate inventory report still fails the 15-question diagnostic preflight: there are no eligible approved diagnostic questions in the current workbench. Synthetic demo questions remain separate from production content.

ReadinessSnapshot models, storage and display exist, but there is no runtime algorithm calculating and saving new readiness scores from study answers. Demo history is seeded in DebugDemoEnvironment. Progress now labels demo history as sample data and explicitly says it does not assess exam readiness. Standard progress explains that accuracy is not passing probability and that personalized readiness estimation is unavailable. Help explains these limits and suggests starting with Practice.

These findings are verification, not a completed diagnostic implementation. No invented scoring formula or approval of draft exam content was introduced.

## Device and accessibility verification

Settings/help widget coverage uses a 375×667 viewport with light/dark themes and 1×/4× text. It exercises all appearance options, all help topics, returning to settings, and cancelling reset. Existing tests exercise editing, reset failure/retry and retention of plan/theme. A large-text help viewport failure found during testing was corrected with the app's supported scrollable layout.

Flutter lists macOS and Chrome only. No physical phone or wireless device is connected; simctl reports CoreSimulatorService connection refused. Physical-device rendering, VoiceOver and touch verification are outstanding. Widget coverage does not replace those checks.

## Visual baselines

The Linux update-goldens workflow now also produces review artifacts for UI pull requests. It never commits them, and the quality job independently continues to compare committed baselines. Intentional Settings and Progress changes require reviewing and committing Linux-generated replacements before merging. macOS output is for local visual inspection only.
