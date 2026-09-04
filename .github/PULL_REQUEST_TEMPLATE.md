## Jira

<!-- Required. The PR title or this line must contain a PREP-### reference. -->
Jira: PREP-

## Summary

<!-- What changed and why, in 1-5 bullet points. -->

-

## Test evidence

<!-- Paste the actual output/exit status of each command you ran — never
     check a box for a command you did not run. -->

- [ ] `dart format --output=none --set-exit-if-changed lib test tool`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Task-specific build, if the Jira acceptance criteria name one (e.g.
      `flutter build ios --release --no-codesign`) — state which, or "N/A"
- [ ] Manual verification for anything that can't be reliably automated
      (describe what was checked and how)

## Risks

<!-- What could this break, and what did you check to rule it out?
     "None identified" is only acceptable with a one-line reason why. -->

-

## Privacy / accessibility decisions

<!-- Any new or changed data collection, storage, or third-party call —
     or explicitly "No privacy-relevant change."
     Any new interactive UI — confirm VoiceOver labels, Dynamic Type up to
     AX5, Reduce Motion, and 44x44 tap targets, or explicitly
     "No accessibility-relevant change." -->

-

## Rollback plan

<!-- How to undo this if it causes a problem after merge (e.g. "revert
     this PR's merge commit"; call out anything that wouldn't be undone
     by a plain revert, such as a data migration or a rotated secret). -->

-

## Checklist

- [ ] No secrets, tokens, personal data, or signing material were added to
      the diff or to any log pasted above
- [ ] No existing test, lint rule, or validator was weakened to get a
      green result
- [ ] No unrelated cleanup or drive-by changes are mixed into this PR
