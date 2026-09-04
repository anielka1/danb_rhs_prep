import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards a specific CI regression found while auditing the "keep quality
/// CI green" task (epic FAST 00): a bare `git diff --check` step, run right
/// after `actions/checkout`, always reports zero findings — the working
/// tree and index are identical immediately after a clean checkout, so
/// there is nothing to diff, regardless of whether the checked-out
/// commit actually contains a leftover merge-conflict marker or a
/// disallowed whitespace error. Confirmed by reproduction: a commit with
/// `<<<<<<< HEAD` / `=======` / `>>>>>>>` markers passed a bare
/// `git diff --check` silently (exit 0).
///
/// The fix diffs the full checked-out tree against git's fixed
/// empty-tree object (`git diff --check <empty-tree> HEAD`), so every
/// line reads as "added" and is actually inspected. This test does not
/// re-run that command (that's what the `secret-scan`/`quality` jobs
/// already do on every PR) — it guards against the *step* silently
/// regressing back to the vacuous bare form in a future edit of
/// `ci.yml`, which would look like an equivalent, harmless simplification
/// but would quietly disable the check again.
void main() {
  test(
      'the merge-conflict/whitespace check diffs against a real base, '
      'not a bare (always-empty) git diff --check', () {
    final String workflow = File('.github/workflows/ci.yml').readAsStringSync();

    final RegExp checkStepRun = RegExp(r'run:\s*git diff --check(.*)');
    final Match? match = checkStepRun.firstMatch(workflow);

    expect(match, isNotNull,
        reason: 'expected a `git diff --check` step in ci.yml');

    final String trailingArgs = match!.group(1)!.trim();
    expect(
      trailingArgs,
      isNotEmpty,
      reason: 'git diff --check with no revision arguments compares the '
          'working tree to the index, which are identical right after a '
          'clean CI checkout — it silently finds nothing no matter what '
          'the commit actually contains. It must diff against a real '
          "base (e.g. git's empty-tree object) so it inspects the "
          'checked-out content.',
    );
  });

  test(
      '.gitattributes exempts markdown\'s intentional trailing-space line '
      'breaks from the whitespace check, without touching conflict-marker '
      'detection', () {
    final String attributes = File('.gitattributes').readAsStringSync();

    expect(attributes, contains('*.md'));
    expect(attributes, contains('whitespace='));
    expect(
      attributes,
      contains('trailing-space'),
      reason: 'without this, the corrected git diff --check would fail '
          'on docs/DANB_RHS_APP_STORE_ROADMAP.md\'s existing trailing '
          'double-space Markdown line breaks, which are intentional, not '
          'a whitespace error.',
    );
  });
}
