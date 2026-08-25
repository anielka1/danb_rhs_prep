import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/features/questions/domain/question.dart';

import '../../tool/candidate_question_validator.dart';

/// Builds synthetic, non-clinical production content JSON with three
/// domains weighted 0.5/0.25/0.25 — so a 15-question diagnostic requires
/// 7/4/4 — and lets the caller supply the exact bundled `questions` array,
/// so tests can control precisely how many are `approved`/`draft`/
/// `reviewed`/`retired` per domain.
String _productionContentJson({
  required List<Map<String, Object?>> questions,
  int diagnosticQuestions = 15,
}) {
  return jsonEncode({
    'contentVersion': 'test-1',
    'sourceVersion': 'test-source',
    'generatedAt': '2026-01-01T00:00:00Z',
    'exam': {
      'id': 'test_exam',
      'name': 'Test Exam',
      'provider': 'Test Provider',
      'examVersion': 'v1',
      'contentVersion': 'test-1',
      'domains': [
        {
          'id': 'domain_a',
          'name': 'Domain A',
          'weight': 0.5,
          'topics': [
            {'id': 'topic_a1', 'name': 'Topic A1'},
          ],
        },
        {
          'id': 'domain_b',
          'name': 'Domain B',
          'weight': 0.25,
          'topics': [
            {'id': 'topic_b1', 'name': 'Topic B1'},
          ],
        },
        {
          'id': 'domain_c',
          'name': 'Domain C',
          'weight': 0.25,
          'topics': [
            {'id': 'topic_c1', 'name': 'Topic C1'},
          ],
        },
      ],
      'mockExam': {
        'questionCount': 10,
        'durationMinutes': 10,
        'practicePassingPercent': 75,
        'allowsBackNavigation': false,
        'timed': true,
      },
      'officialScoring': {
        'scaleMinimum': 100,
        'scaleMaximum': 900,
        'passingScaledScore': 400,
        'isComputerAdaptive': true,
      },
      'readiness': {
        'weights': {
          'recentAccuracy': 0.3,
          'domainMastery': 0.25,
          'mockPerformance': 0.25,
          'repeatedMastery': 0.1,
          'coverage': 0.1,
        },
        'thresholds': [
          {'minimum': 0, 'label': 'Starting', 'band': 'starting'},
        ],
        'priorScore': 40,
        'minimumEvidenceQuestions': 40,
        'recencyHalfLifeDays': 21,
        'weakDomainPenalty': 0.15,
      },
      'subscriptionProductIds': {
        'weekly': 'w',
        'monthly': 'm',
        'threeMonths': 't',
      },
      'freeTier': {
        'dailyPracticeQuestions': 10,
        'diagnosticQuestions': diagnosticQuestions,
        'includedMockExams': 0,
      },
      'disclaimer': 'test disclaimer',
    },
    'questions': questions,
  });
}

Map<String, Object?> _productionQuestion({
  required String id,
  required String domainId,
  required String topicId,
  String status = 'approved',
  String questionText = 'A synthetic placeholder production question?',
}) {
  return {
    'id': id,
    'examId': 'test_exam',
    'domainId': domainId,
    'topicId': topicId,
    'questionText': questionText,
    'answers': [
      {'id': 'a', 'text': 'Option A'},
      {'id': 'b', 'text': 'Option B'},
      {'id': 'c', 'text': 'Option C'},
      {'id': 'd', 'text': 'Option D'},
    ],
    'correctAnswerId': 'a',
    'explanation': 'A synthetic placeholder explanation of sufficient length.',
    'references': [
      {'title': 'Fixture Source', 'source': 'Test Suite', 'section': '1'},
    ],
    'difficulty': 1,
    'status': status,
    'version': 1,
    'updatedAt': '2026-01-01T00:00:00Z',
    'sourceVersion': 'test',
    'tags': const <String>[],
  };
}

const String _emptyCandidates =
    '{"schemaVersion":1,"examId":"test_exam","candidates":[]}';
const String _emptyDecisions =
    '{"schemaVersion":1,"examId":"test_exam","decisions":[]}';

/// Writes [content] to a fresh temp file the caller is responsible for
/// cleaning up via the returned [Directory] (deleted recursively in each
/// test's `tearDown`-equivalent try/finally).
File _writeTemp(Directory dir, String name, String content) {
  final File file = File('${dir.path}/$name');
  file.writeAsStringSync(content);
  return file;
}

void main() {
  group('runValidatorCli — default and --report modes', () {
    test(
        'an empty but structurally valid workbench: --report returns 0 '
        'and visibly prints diagnostic readiness FAIL', () {
      final Directory dir =
          Directory.systemTemp.createTempSync('workbench_cli_test');
      try {
        final File production = _writeTemp(
          dir,
          'content.json',
          _productionContentJson(questions: const []),
        );
        _writeTemp(dir, 'candidates.json', _emptyCandidates);
        _writeTemp(dir, 'decisions.json', _emptyDecisions);

        final out = StringBuffer();
        final err = StringBuffer();
        final int exitCode = runValidatorCli(
          ['--report'],
          out: out,
          err: err,
          paths: ValidatorCliPaths(
            productionContentPath: production.path,
            candidateQuestionsPath: '${dir.path}/candidates.json',
            reviewerDecisionsPath: '${dir.path}/decisions.json',
          ),
        );

        expect(exitCode, 0);
        expect(out.toString(), contains('Structurally valid: YES'));
        expect(out.toString(), contains('FAIL'));
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test(
        'a structural validation error (e.g. duplicate candidate IDs) '
        'returns 1', () {
      final Directory dir =
          Directory.systemTemp.createTempSync('workbench_cli_test');
      try {
        final File production = _writeTemp(
          dir,
          'content.json',
          _productionContentJson(questions: const []),
        );
        final Map<String, Object?> dup = {
          'id': 'dup-1',
          'examId': 'test_exam',
          'domainId': 'domain_a',
          'topicId': 'topic_a1',
          'questionText': 'A duplicated candidate?',
          'answers': [
            {'id': 'a', 'text': 'A'},
            {'id': 'b', 'text': 'B'},
            {'id': 'c', 'text': 'C'},
            {'id': 'd', 'text': 'D'},
          ],
          'correctAnswerId': 'a',
          'explanation': 'Explanation text of sufficient length here.',
          'references': [
            {'title': 'T', 'source': 'S', 'section': '1'},
          ],
          'difficulty': 1,
          'status': 'draft',
          'version': 1,
          'updatedAt': '2026-01-01T00:00:00Z',
          'sourceVersion': 'test',
          'tags': [],
        };
        _writeTemp(
          dir,
          'candidates.json',
          jsonEncode({
            'schemaVersion': 1,
            'examId': 'test_exam',
            'candidates': [dup, dup],
          }),
        );
        _writeTemp(dir, 'decisions.json', _emptyDecisions);

        final out = StringBuffer();
        final err = StringBuffer();
        final int exitCode = runValidatorCli(
          [],
          out: out,
          err: err,
          paths: ValidatorCliPaths(
            productionContentPath: production.path,
            candidateQuestionsPath: '${dir.path}/candidates.json',
            reviewerDecisionsPath: '${dir.path}/decisions.json',
          ),
        );

        expect(exitCode, 1);
        expect(out.toString(), contains('duplicate_candidate_id'));
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('malformed input (invalid JSON) returns 1', () {
      final Directory dir =
          Directory.systemTemp.createTempSync('workbench_cli_test');
      try {
        final File production = _writeTemp(
          dir,
          'content.json',
          _productionContentJson(questions: const []),
        );
        _writeTemp(dir, 'candidates.json', '{ this is not valid JSON');
        _writeTemp(dir, 'decisions.json', _emptyDecisions);

        final out = StringBuffer();
        final err = StringBuffer();
        final int exitCode = runValidatorCli(
          [],
          out: out,
          err: err,
          paths: ValidatorCliPaths(
            productionContentPath: production.path,
            candidateQuestionsPath: '${dir.path}/candidates.json',
            reviewerDecisionsPath: '${dir.path}/decisions.json',
          ),
        );

        expect(exitCode, 1);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test(
        'an unknown option returns a documented usage error on stderr, '
        'exit 1', () {
      final out = StringBuffer();
      final err = StringBuffer();
      final int exitCode = runValidatorCli(
        ['--not-a-real-flag'],
        out: out,
        err: err,
      );
      expect(exitCode, 1);
      expect(err.toString(), contains('Unknown option'));
      expect(err.toString(), contains('Usage:'));
    });
  });

  group('runValidatorCli — --require-ready (bundled production readiness)', () {
    test(
        'the current real bundled production inventory (assets/content/'
        'danb_rhs/content.json, checked from the repository root) returns '
        'exactly 2 under --require-ready — insufficient approved inventory, '
        'not a validation error', () {
      final out = StringBuffer();
      final err = StringBuffer();
      final int exitCode = runValidatorCli(
        ['--require-ready'],
        out: out,
        err: err,
      );
      expect(exitCode, 2);
      expect(out.toString(), contains('Production diagnostic readiness: FAIL'));
    });

    test(
        'synthetic bundled content satisfying the configured 7/4/4 '
        'allocation returns 0', () {
      final Directory dir =
          Directory.systemTemp.createTempSync('workbench_cli_test');
      try {
        final List<Map<String, Object?>> questions = [
          for (var i = 0; i < 7; i++)
            _productionQuestion(
                id: 'a-$i',
                domainId: 'domain_a',
                topicId: 'topic_a1',
                status: 'approved'),
          for (var i = 0; i < 4; i++)
            _productionQuestion(
                id: 'b-$i',
                domainId: 'domain_b',
                topicId: 'topic_b1',
                status: 'approved'),
          for (var i = 0; i < 4; i++)
            _productionQuestion(
                id: 'c-$i',
                domainId: 'domain_c',
                topicId: 'topic_c1',
                status: 'approved'),
        ];
        final File production = _writeTemp(
          dir,
          'content.json',
          _productionContentJson(questions: questions),
        );
        _writeTemp(dir, 'candidates.json', _emptyCandidates);
        _writeTemp(dir, 'decisions.json', _emptyDecisions);

        final out = StringBuffer();
        final err = StringBuffer();
        final int exitCode = runValidatorCli(
          ['--require-ready'],
          out: out,
          err: err,
          paths: ValidatorCliPaths(
            productionContentPath: production.path,
            candidateQuestionsPath: '${dir.path}/candidates.json',
            reviewerDecisionsPath: '${dir.path}/decisions.json',
          ),
        );

        expect(exitCode, 0);
        expect(
            out.toString(), contains('Production diagnostic readiness: PASS'));
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('draft bundled questions do not count toward readiness', () {
      final Directory dir =
          Directory.systemTemp.createTempSync('workbench_cli_test');
      try {
        final List<Map<String, Object?>> questions = [
          for (var i = 0; i < 7; i++)
            _productionQuestion(
                id: 'a-$i',
                domainId: 'domain_a',
                topicId: 'topic_a1',
                status: 'draft'),
          for (var i = 0; i < 4; i++)
            _productionQuestion(
                id: 'b-$i',
                domainId: 'domain_b',
                topicId: 'topic_b1',
                status: 'approved'),
          for (var i = 0; i < 4; i++)
            _productionQuestion(
                id: 'c-$i',
                domainId: 'domain_c',
                topicId: 'topic_c1',
                status: 'approved'),
        ];
        final File production = _writeTemp(
          dir,
          'content.json',
          _productionContentJson(questions: questions),
        );
        _writeTemp(dir, 'candidates.json', _emptyCandidates);
        _writeTemp(dir, 'decisions.json', _emptyDecisions);

        final out = StringBuffer();
        final int exitCode = runValidatorCli(
          ['--require-ready'],
          out: out,
          err: StringBuffer(),
          paths: ValidatorCliPaths(
            productionContentPath: production.path,
            candidateQuestionsPath: '${dir.path}/candidates.json',
            reviewerDecisionsPath: '${dir.path}/decisions.json',
          ),
        );

        expect(exitCode, 2);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('reviewed bundled questions do not count toward readiness', () {
      final Directory dir =
          Directory.systemTemp.createTempSync('workbench_cli_test');
      try {
        final List<Map<String, Object?>> questions = [
          for (var i = 0; i < 7; i++)
            _productionQuestion(
                id: 'a-$i',
                domainId: 'domain_a',
                topicId: 'topic_a1',
                status: 'reviewed'),
          for (var i = 0; i < 4; i++)
            _productionQuestion(
                id: 'b-$i',
                domainId: 'domain_b',
                topicId: 'topic_b1',
                status: 'approved'),
          for (var i = 0; i < 4; i++)
            _productionQuestion(
                id: 'c-$i',
                domainId: 'domain_c',
                topicId: 'topic_c1',
                status: 'approved'),
        ];
        final File production = _writeTemp(
          dir,
          'content.json',
          _productionContentJson(questions: questions),
        );
        _writeTemp(dir, 'candidates.json', _emptyCandidates);
        _writeTemp(dir, 'decisions.json', _emptyDecisions);

        final int exitCode = runValidatorCli(
          ['--require-ready'],
          out: StringBuffer(),
          err: StringBuffer(),
          paths: ValidatorCliPaths(
            productionContentPath: production.path,
            candidateQuestionsPath: '${dir.path}/candidates.json',
            reviewerDecisionsPath: '${dir.path}/decisions.json',
          ),
        );

        expect(exitCode, 2);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('retired bundled questions do not count toward readiness', () {
      final Directory dir =
          Directory.systemTemp.createTempSync('workbench_cli_test');
      try {
        final List<Map<String, Object?>> questions = [
          for (var i = 0; i < 7; i++)
            _productionQuestion(
                id: 'a-$i',
                domainId: 'domain_a',
                topicId: 'topic_a1',
                status: 'retired'),
          for (var i = 0; i < 4; i++)
            _productionQuestion(
                id: 'b-$i',
                domainId: 'domain_b',
                topicId: 'topic_b1',
                status: 'approved'),
          for (var i = 0; i < 4; i++)
            _productionQuestion(
                id: 'c-$i',
                domainId: 'domain_c',
                topicId: 'topic_c1',
                status: 'approved'),
        ];
        final File production = _writeTemp(
          dir,
          'content.json',
          _productionContentJson(questions: questions),
        );
        _writeTemp(dir, 'candidates.json', _emptyCandidates);
        _writeTemp(dir, 'decisions.json', _emptyDecisions);

        final int exitCode = runValidatorCli(
          ['--require-ready'],
          out: StringBuffer(),
          err: StringBuffer(),
          paths: ValidatorCliPaths(
            productionContentPath: production.path,
            candidateQuestionsPath: '${dir.path}/candidates.json',
            reviewerDecisionsPath: '${dir.path}/decisions.json',
          ),
        );

        expect(exitCode, 2);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test(
        'approved questions count only toward their own configured '
        'domain — an over-supplied domain does not compensate for an '
        'under-supplied one', () {
      final Directory dir =
          Directory.systemTemp.createTempSync('workbench_cli_test');
      try {
        final List<Map<String, Object?>> questions = [
          // domain_a wildly over-supplied.
          for (var i = 0; i < 20; i++)
            _productionQuestion(
                id: 'a-$i',
                domainId: 'domain_a',
                topicId: 'topic_a1',
                status: 'approved'),
          for (var i = 0; i < 4; i++)
            _productionQuestion(
                id: 'b-$i',
                domainId: 'domain_b',
                topicId: 'topic_b1',
                status: 'approved'),
          // domain_c under-supplied (needs 4, has 0).
        ];
        final File production = _writeTemp(
          dir,
          'content.json',
          _productionContentJson(questions: questions),
        );
        _writeTemp(dir, 'candidates.json', _emptyCandidates);
        _writeTemp(dir, 'decisions.json', _emptyDecisions);

        final out = StringBuffer();
        final int exitCode = runValidatorCli(
          ['--require-ready'],
          out: out,
          err: StringBuffer(),
          paths: ValidatorCliPaths(
            productionContentPath: production.path,
            candidateQuestionsPath: '${dir.path}/candidates.json',
            reviewerDecisionsPath: '${dir.path}/decisions.json',
          ),
        );

        expect(exitCode, 2);
        expect(
            out.toString(), contains('Production diagnostic readiness: FAIL'));
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test(
        'one underfilled domain returns 2 even when the overall total '
        'across all domains is at least 15', () {
      final Directory dir =
          Directory.systemTemp.createTempSync('workbench_cli_test');
      try {
        // 12 + 4 + 3 = 19 total approved questions (well over 15), but
        // domain_c has only 3 of its required 4 — must still fail.
        final List<Map<String, Object?>> questions = [
          for (var i = 0; i < 12; i++)
            _productionQuestion(
                id: 'a-$i',
                domainId: 'domain_a',
                topicId: 'topic_a1',
                status: 'approved'),
          for (var i = 0; i < 4; i++)
            _productionQuestion(
                id: 'b-$i',
                domainId: 'domain_b',
                topicId: 'topic_b1',
                status: 'approved'),
          for (var i = 0; i < 3; i++)
            _productionQuestion(
                id: 'c-$i',
                domainId: 'domain_c',
                topicId: 'topic_c1',
                status: 'approved'),
        ];
        final File production = _writeTemp(
          dir,
          'content.json',
          _productionContentJson(questions: questions),
        );
        _writeTemp(dir, 'candidates.json', _emptyCandidates);
        _writeTemp(dir, 'decisions.json', _emptyDecisions);

        final int exitCode = runValidatorCli(
          ['--require-ready'],
          out: StringBuffer(),
          err: StringBuffer(),
          paths: ValidatorCliPaths(
            productionContentPath: production.path,
            candidateQuestionsPath: '${dir.path}/candidates.json',
            reviewerDecisionsPath: '${dir.path}/decisions.json',
          ),
        );

        expect(exitCode, 2);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test(
        'the required-per-domain allocation is derived from the '
        'configured diagnostic count and domain weights, not hardcoded — '
        'a differently configured diagnostic count changes what counts as '
        'ready', () {
      final Directory dir =
          Directory.systemTemp.createTempSync('workbench_cli_test');
      try {
        // With a 10-question diagnostic and the same 0.5/0.25/0.25
        // weights, apportionment yields 5/3/3 (not 7/4/4) — exactly 5/3/3
        // approved questions must therefore be enough.
        final List<Map<String, Object?>> questions = [
          for (var i = 0; i < 5; i++)
            _productionQuestion(
                id: 'a-$i',
                domainId: 'domain_a',
                topicId: 'topic_a1',
                status: 'approved'),
          for (var i = 0; i < 3; i++)
            _productionQuestion(
                id: 'b-$i',
                domainId: 'domain_b',
                topicId: 'topic_b1',
                status: 'approved'),
          for (var i = 0; i < 3; i++)
            _productionQuestion(
                id: 'c-$i',
                domainId: 'domain_c',
                topicId: 'topic_c1',
                status: 'approved'),
        ];
        final File production = _writeTemp(
          dir,
          'content.json',
          _productionContentJson(questions: questions, diagnosticQuestions: 10),
        );
        _writeTemp(dir, 'candidates.json', _emptyCandidates);
        _writeTemp(dir, 'decisions.json', _emptyDecisions);

        final out = StringBuffer();
        final int exitCode = runValidatorCli(
          ['--require-ready'],
          out: out,
          err: StringBuffer(),
          paths: ValidatorCliPaths(
            productionContentPath: production.path,
            candidateQuestionsPath: '${dir.path}/candidates.json',
            reviewerDecisionsPath: '${dir.path}/decisions.json',
          ),
        );

        expect(exitCode, 0);
        expect(
            out.toString(), contains('Production diagnostic readiness: PASS'));
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test(
        'fingerprint-matched workbench approvals that have not been '
        'manually promoted into bundled content do not count toward '
        '--require-ready — only the bundled content\'s own approved '
        'status matters', () {
      final Directory dir =
          Directory.systemTemp.createTempSync('workbench_cli_test');
      try {
        // Bundled production content has zero approved questions...
        final File production = _writeTemp(
          dir,
          'content.json',
          _productionContentJson(questions: const []),
        );
        // ...even though the workbench has a fully fingerprint-matched,
        // human-approved candidate sitting right there, unpromoted.
        final Map<String, Object?> candidate = {
          'id': 'cand-001',
          'examId': 'test_exam',
          'domainId': 'domain_a',
          'topicId': 'topic_a1',
          'questionText': 'A fully approved but unpromoted candidate?',
          'answers': [
            {'id': 'a', 'text': 'A'},
            {'id': 'b', 'text': 'B'},
            {'id': 'c', 'text': 'C'},
            {'id': 'd', 'text': 'D'},
          ],
          'correctAnswerId': 'a',
          'explanation': 'Explanation text of sufficient length here.',
          'references': [
            {'title': 'T', 'source': 'S', 'section': '1'},
          ],
          'difficulty': 1,
          'status': 'draft',
          'version': 1,
          'updatedAt': '2026-01-01T00:00:00Z',
          'sourceVersion': 'test',
          'tags': [],
        };
        final String fingerprint =
            computeContentFingerprint(Question.fromJson(candidate));
        _writeTemp(
          dir,
          'candidates.json',
          jsonEncode({
            'schemaVersion': 1,
            'examId': 'test_exam',
            'candidates': [candidate],
          }),
        );
        _writeTemp(
          dir,
          'decisions.json',
          jsonEncode({
            'schemaVersion': 1,
            'examId': 'test_exam',
            'decisions': [
              {
                'questionId': 'cand-001',
                'contentFingerprint': fingerprint,
                'contentFingerprintAlgorithm': kFingerprintAlgorithm,
                'decision': 'approve',
                'reviewerIdentity': 'Test Reviewer, RDH',
                'reviewDate': '2026-01-02T00:00:00Z',
              },
            ],
          }),
        );

        final int exitCode = runValidatorCli(
          ['--require-ready'],
          out: StringBuffer(),
          err: StringBuffer(),
          paths: ValidatorCliPaths(
            productionContentPath: production.path,
            candidateQuestionsPath: '${dir.path}/candidates.json',
            reviewerDecisionsPath: '${dir.path}/decisions.json',
          ),
        );

        expect(exitCode, 2,
            reason: 'a workbench-only approval must never count as '
                'production-ready until a human promotes it into '
                'content.json');
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
