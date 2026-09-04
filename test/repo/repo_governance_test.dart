import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the repo-governance artifacts added for "[REPO] Dodaj PR
/// template, ochrone main i szybki runbook agentow" (epic FAST 00):
/// the PR template a reviewer/CI relies on to see Jira linkage, test
/// evidence, risk, and privacy/accessibility/rollback decisions, and the
/// agent runbook describing the one safe worktree/branch/verify/push/PR
/// process. Without this test, any of the three files could be silently
/// deleted or gutted by a future edit with nothing catching it — they
/// aren't referenced by any Dart import, so `flutter analyze` wouldn't
/// notice either.
void main() {
  group('.github/PULL_REQUEST_TEMPLATE.md', () {
    late String template;

    setUpAll(() {
      template = File('.github/PULL_REQUEST_TEMPLATE.md').readAsStringSync();
    });

    test('prompts for the Jira reference', () {
      expect(template, contains('Jira'));
      expect(template, contains('PREP-'));
    });

    test('prompts for test evidence', () {
      expect(template, contains('Test evidence'));
      expect(template, contains('dart format'));
      expect(template, contains('flutter analyze'));
      expect(template, contains('flutter test'));
    });

    test('prompts for risks, privacy/accessibility, and rollback', () {
      expect(template, contains('Risks'));
      expect(template, contains('Privacy'));
      expect(template, contains('accessibility'));
      expect(template, contains('Rollback'));
    });
  });

  group('AGENTS.md', () {
    late String runbook;

    setUpAll(() {
      runbook = File('AGENTS.md').readAsStringSync();
    });

    test('documents the one safe process end to end', () {
      // The exact sequence this task's scope names explicitly: worktree,
      // branch, verify, push, PR.
      for (final step in [
        'worktree',
        'branch',
        'verify',
        'push',
        'PR',
      ]) {
        expect(runbook, contains(step),
            reason: 'AGENTS.md should document the "$step" step');
      }
    });

    test('documents the required local verification commands', () {
      expect(runbook, contains('dart format'));
      expect(runbook, contains('flutter analyze'));
      expect(runbook, contains('flutter test'));
    });

    test(
        'documents branch-protection status for main, not just leaves '
        'it unmentioned', () {
      expect(runbook, contains('Branch protection'));
      expect(runbook.toLowerCase(), contains('main'));
    });
  });

  group('CLAUDE.md', () {
    test('points to AGENTS.md as the single source of truth', () {
      final String claude = File('CLAUDE.md').readAsStringSync();
      expect(claude, contains('AGENTS.md'));
    });
  });
}
