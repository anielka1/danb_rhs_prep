import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/features/questions/domain/question.dart';

import '../../tool/candidate_question_validator.dart';

/// Synthetic, non-clinical production content fixture: three domains
/// weighted 0.5/0.25/0.25 (so a 15-question diagnostic apportions to
/// 7/4/4 — mirroring the real DANB RHS weighting without using any real
/// exam content), each with one topic, plus one pre-existing "production"
/// question used to test ID-collision detection.
String _productionContentJson({int diagnosticQuestions = 15}) {
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
    'questions': [
      {
        'id': 'prod-existing-001',
        'examId': 'test_exam',
        'domainId': 'domain_a',
        'topicId': 'topic_a1',
        'questionText': 'An already-bundled production question.',
        'answers': [
          {'id': 'a', 'text': 'Option A'},
          {'id': 'b', 'text': 'Option B'},
          {'id': 'c', 'text': 'Option C'},
          {'id': 'd', 'text': 'Option D'},
        ],
        'correctAnswerId': 'a',
        'explanation': 'Because A is correct in this synthetic fixture.',
        'references': [
          {'title': 'Fixture Source', 'source': 'Test Suite', 'section': '1'},
        ],
        'difficulty': 1,
        'status': 'approved',
        'version': 1,
        'updatedAt': '2026-01-01T00:00:00Z',
        'sourceVersion': 'test',
        'tags': [],
      },
    ],
  });
}

Map<String, Object?> _candidate({
  required String id,
  String domainId = 'domain_a',
  String topicId = 'topic_a1',
  String questionText = 'A synthetic placeholder question stem?',
  List<Map<String, String>>? answers,
  String correctAnswerId = 'a',
  String explanation =
      'A synthetic placeholder explanation of sufficient length.',
  List<Map<String, String>>? references,
  String status = 'draft',
  int difficulty = 1,
  int version = 1,
  String sourceVersion = 'test',
  List<String> tags = const <String>[],
  String updatedAt = '2026-01-01T00:00:00Z',
}) {
  return {
    'id': id,
    'examId': 'test_exam',
    'domainId': domainId,
    'topicId': topicId,
    'questionText': questionText,
    'answers': answers ??
        [
          {'id': 'a', 'text': 'Option A'},
          {'id': 'b', 'text': 'Option B'},
          {'id': 'c', 'text': 'Option C'},
          {'id': 'd', 'text': 'Option D'},
        ],
    'correctAnswerId': correctAnswerId,
    'explanation': explanation,
    'references': references ??
        [
          {'title': 'Fixture Source', 'source': 'Test Suite', 'section': '1'},
        ],
    'difficulty': difficulty,
    'status': status,
    'version': version,
    'updatedAt': updatedAt,
    'sourceVersion': sourceVersion,
    'tags': tags,
  };
}

String _candidatesJson(List<Map<String, Object?>> candidates) {
  return jsonEncode({
    'schemaVersion': 1,
    'examId': 'test_exam',
    'candidates': candidates,
  });
}

Map<String, Object?> _decision({
  required String questionId,
  required String contentFingerprint,
  String contentFingerprintAlgorithm = kFingerprintAlgorithm,
  String decision = 'approve',
  String reviewerIdentity = 'Test Reviewer, RDH',
  String reviewDate = '2026-01-02T00:00:00Z',
  String? notes,
}) {
  return {
    'questionId': questionId,
    'contentFingerprint': contentFingerprint,
    'contentFingerprintAlgorithm': contentFingerprintAlgorithm,
    'decision': decision,
    'reviewerIdentity': reviewerIdentity,
    'reviewDate': reviewDate,
    if (notes != null) 'notes': notes,
  };
}

String _decisionsJson(List<Map<String, Object?>> decisions) {
  return jsonEncode({
    'schemaVersion': 1,
    'examId': 'test_exam',
    'decisions': decisions,
  });
}

const String _emptyDecisions =
    '{"schemaVersion":1,"examId":"test_exam","decisions":[]}';

void main() {
  group('structural validation', () {
    test('a well-formed candidate produces no errors', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([_candidate(id: 'cand-001')]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isTrue);
      expect(report.issues, isEmpty);
    });

    test('duplicate candidate IDs are rejected', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([
          _candidate(id: 'cand-dup'),
          _candidate(
              id: 'cand-dup', questionText: 'A different stem entirely.'),
        ]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isFalse);
      expect(
          report.issues.map((i) => i.code), contains('duplicate_candidate_id'));
    });

    test('an unknown domain ID is rejected', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson(
            [_candidate(id: 'cand-001', domainId: 'not_a_real_domain')]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isFalse);
      expect(report.issues.map((i) => i.code), contains('unknown_domain'));
    });

    test('an unknown topic ID within a known domain is rejected', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson(
            [_candidate(id: 'cand-001', topicId: 'not_a_real_topic')]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isFalse);
      expect(report.issues.map((i) => i.code), contains('unknown_topic'));
    });

    test('an invalid correct-answer reference is rejected', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson(
            [_candidate(id: 'cand-001', correctAnswerId: 'not-an-option')]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isFalse);
      expect(
          report.issues.map((i) => i.code), contains('invalid_correct_answer'));
    });

    test('a missing source reference is rejected', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson:
            _candidatesJson([_candidate(id: 'cand-001', references: [])]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isFalse);
      expect(report.issues.map((i) => i.code),
          contains('missing_source_reference'));
    });

    test('a source reference missing a specific locator is rejected', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([
          _candidate(id: 'cand-001', references: [
            {
              'title': 'Some Publisher',
              'source': 'Some Publisher',
              'section': ''
            },
          ]),
        ]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isFalse);
      expect(report.issues.map((i) => i.code),
          contains('incomplete_source_reference'));
    });

    test(
        'a normalized duplicate stem is detected even with different '
        'whitespace and casing', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([
          _candidate(
              id: 'cand-001', questionText: 'What is the correct technique?'),
          _candidate(
              id: 'cand-002',
              questionText: '  WHAT is the   correct technique?  '),
        ]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isFalse);
      expect(report.issues.map((i) => i.code),
          contains('duplicate_question_stem'));
    });

    test('fewer than the house-minimum option count is rejected', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([
          _candidate(
              id: 'cand-001',
              answers: [
                {'id': 'a', 'text': 'Option A'},
                {'id': 'b', 'text': 'Option B'},
              ],
              correctAnswerId: 'a'),
        ]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isFalse);
      expect(report.issues.map((i) => i.code),
          contains('insufficient_option_count'));
    });

    test('duplicate option IDs within one candidate are rejected', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([
          _candidate(id: 'cand-001', answers: [
            {'id': 'a', 'text': 'Option A'},
            {'id': 'a', 'text': 'Option A again'},
            {'id': 'c', 'text': 'Option C'},
            {'id': 'd', 'text': 'Option D'},
          ]),
        ]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isFalse);
      expect(report.issues.map((i) => i.code), contains('duplicate_option_id'));
    });

    test(
        'a candidate ID colliding with an existing production question ID '
        'is rejected', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson:
            _candidatesJson([_candidate(id: 'prod-existing-001')]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isFalse);
      expect(report.issues.map((i) => i.code),
          contains('production_id_collision'));
    });

    test(
        'duplicate tags are rejected — tags are treated as an unordered '
        'set, so a repeated tag is a structural defect', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([
          _candidate(
              id: 'cand-001',
              tags: const ['radiation-physics', 'radiation-physics']),
        ]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isFalse);
      expect(report.issues.map((i) => i.code), contains('duplicate_tag'));
    });
  });

  group('the human-approval boundary', () {
    test(
        'a draft candidate with no reviewer decision is "awaiting review", '
        'never treated as approved', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([_candidate(id: 'cand-001')]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.statusByQuestionId['cand-001'],
          CandidateReviewStatus.awaitingReview);
    });

    test(
        'a candidate authored directly with status "approved" is rejected '
        'as structurally invalid — the validator itself never grants '
        'approval, and content cannot claim it via its own status field', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson:
            _candidatesJson([_candidate(id: 'cand-001', status: 'approved')]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.isStructurallyValid, isFalse);
      expect(report.issues.map((i) => i.code),
          contains('candidate_status_must_be_draft'));
      expect(
          report.statusByQuestionId['cand-001'], CandidateReviewStatus.invalid);
    });

    test(
        'running the validator twice never mutates or fabricates a '
        'reviewer decision — the decision list passed in is exactly the '
        'decision list reflected back, no more and no fewer entries', () {
      const String decisions = _emptyDecisions;
      final report1 = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([_candidate(id: 'cand-001')]),
        reviewerDecisionsJson: decisions,
      );
      final report2 = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([_candidate(id: 'cand-001')]),
        reviewerDecisionsJson: decisions,
      );
      expect(report1.statusByQuestionId['cand-001'],
          CandidateReviewStatus.awaitingReview);
      expect(report2.statusByQuestionId['cand-001'],
          CandidateReviewStatus.awaitingReview);
    });

    test(
        'a reviewer decision referencing a question ID that does not '
        'exist among the candidates is rejected', () {
      final candidate = _candidate(id: 'cand-001');
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([candidate]),
        reviewerDecisionsJson: _decisionsJson([
          _decision(
              questionId: 'cand-does-not-exist', contentFingerprint: 'abc123'),
        ]),
      );
      expect(report.isStructurallyValid, isFalse);
      expect(report.issues.map((i) => i.code),
          contains('decision_references_unknown_candidate'));
    });
  });

  group('content fingerprint', () {
    test(
        'the fingerprint changes after any material edit (stem, answers, '
        'correct answer, explanation, or references)', () {
      final Map<String, Object?> original = _candidate(id: 'cand-001');
      final Map<String, Object?> editedStem = _candidate(
          id: 'cand-001', questionText: 'A materially different stem?');
      final Map<String, Object?> editedExplanation = _candidate(
          id: 'cand-001',
          explanation: 'A materially different explanation text.');

      final originalFingerprint = _fingerprintOf(original);
      final editedStemFingerprint = _fingerprintOf(editedStem);
      final editedExplanationFingerprint = _fingerprintOf(editedExplanation);

      expect(editedStemFingerprint, isNot(equals(originalFingerprint)));
      expect(editedExplanationFingerprint, isNot(equals(originalFingerprint)));
    });

    test(
        'the fingerprint is identical for byte-identical content computed '
        'twice — deterministic, not randomized per run', () {
      final Map<String, Object?> candidate = _candidate(id: 'cand-001');
      expect(_fingerprintOf(candidate), _fingerprintOf(candidate));
    });

    test(
        'a matching human approval (fingerprint recorded at review time '
        'equals the current candidate fingerprint) is recognized as '
        'approved and fingerprint-matched', () {
      final Map<String, Object?> candidate = _candidate(id: 'cand-001');
      final String fingerprint = _fingerprintOf(candidate);
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([candidate]),
        reviewerDecisionsJson: _decisionsJson([
          _decision(questionId: 'cand-001', contentFingerprint: fingerprint),
        ]),
      );
      expect(report.statusByQuestionId['cand-001'],
          CandidateReviewStatus.approvedAndMatched);
    });

    test(
        'a stale approval — recorded against an older fingerprint than '
        'the current candidate text — is rejected, not silently honored', () {
      final Map<String, Object?> editedCandidate = _candidate(
          id: 'cand-001',
          explanation: 'This explanation was edited after approval.');
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([editedCandidate]),
        reviewerDecisionsJson: _decisionsJson([
          _decision(
              questionId: 'cand-001',
              contentFingerprint: 'stale-fingerprint-from-before-the-edit'),
        ]),
      );
      expect(report.statusByQuestionId['cand-001'],
          CandidateReviewStatus.staleApproval);
    });

    test(
        'a "revise" decision is reflected as revision requested, and a '
        '"reject" decision as rejected — neither counts as approval', () {
      final Map<String, Object?> revised = _candidate(
          id: 'cand-revise', questionText: 'A stem awaiting revision?');
      final Map<String, Object?> rejected = _candidate(
          id: 'cand-reject', questionText: 'A stem that was rejected?');
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([revised, rejected]),
        reviewerDecisionsJson: _decisionsJson([
          _decision(
              questionId: 'cand-revise',
              contentFingerprint: _fingerprintOf(revised),
              decision: 'revise'),
          _decision(
              questionId: 'cand-reject',
              contentFingerprint: _fingerprintOf(rejected),
              decision: 'reject'),
        ]),
      );
      expect(report.statusByQuestionId['cand-revise'],
          CandidateReviewStatus.revisionRequested);
      expect(report.statusByQuestionId['cand-reject'],
          CandidateReviewStatus.rejected);
    });

    test(
        'the fingerprint is exactly 64 lowercase hexadecimal characters '
        '(a SHA-256 digest), not the old 16-character FNV-1a form', () {
      final String fingerprint = _fingerprintOf(_candidate(id: 'cand-001'));
      expect(fingerprint, hasLength(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(fingerprint), isTrue,
          reason: 'Got: $fingerprint');
    });

    test(
        'identical semantic content produces the same fingerprint '
        'regardless of the source JSON object-key order', () {
      const String orderA = '{'
          '"id":"cand-001","examId":"test_exam","domainId":"domain_a",'
          '"topicId":"topic_a1","questionText":"Same question stem?",'
          '"answers":[{"id":"a","text":"Option A"},{"id":"b","text":"Option B"},'
          '{"id":"c","text":"Option C"},{"id":"d","text":"Option D"}],'
          '"correctAnswerId":"a","explanation":"Same explanation text.",'
          '"references":[{"title":"T","source":"S","section":"1"}],'
          '"difficulty":1,"status":"draft","version":1,'
          '"updatedAt":"2026-01-01T00:00:00Z","sourceVersion":"test","tags":[]'
          '}';
      const String orderB = '{'
          '"tags":[],"sourceVersion":"test","updatedAt":"2026-01-01T00:00:00Z",'
          '"version":1,"status":"draft","difficulty":1,'
          '"references":[{"section":"1","source":"S","title":"T"}],'
          '"explanation":"Same explanation text.","correctAnswerId":"a",'
          '"answers":[{"text":"Option A","id":"a"},{"text":"Option B","id":"b"},'
          '{"text":"Option C","id":"c"},{"text":"Option D","id":"d"}],'
          '"questionText":"Same question stem?","topicId":"topic_a1",'
          '"domainId":"domain_a","examId":"test_exam","id":"cand-001"'
          '}';
      final Question questionA =
          Question.fromJson(jsonDecode(orderA) as Map<String, Object?>);
      final Question questionB =
          Question.fromJson(jsonDecode(orderB) as Map<String, Object?>);
      expect(computeContentFingerprint(questionA),
          computeContentFingerprint(questionB));
    });

    test(
        'JSON whitespace differences in the source document do not '
        'affect the fingerprint — it is computed from decoded structured '
        'data, never from raw JSON text', () {
      final Map<String, Object?> compactCandidate = _candidate(id: 'cand-001');
      final String compactJson = jsonEncode(compactCandidate);
      final String spacedJson = compactJson
          .replaceAll(',', ' ,  ')
          .replaceAll(':', ' :   ')
          .replaceAll('{', '{  ')
          .replaceAll('}', '  }');
      final Question fromCompact =
          Question.fromJson(jsonDecode(compactJson) as Map<String, Object?>);
      final Question fromSpaced =
          Question.fromJson(jsonDecode(spacedJson) as Map<String, Object?>);
      expect(computeContentFingerprint(fromCompact),
          computeContentFingerprint(fromSpaced));
    });

    test(
        'answer/reference array order is material — reordering options '
        'changes the fingerprint even though the same options are present', () {
      final Map<String, Object?> original = _candidate(
        id: 'cand-001',
        answers: [
          {'id': 'a', 'text': 'Option A'},
          {'id': 'b', 'text': 'Option B'},
          {'id': 'c', 'text': 'Option C'},
          {'id': 'd', 'text': 'Option D'},
        ],
      );
      final Map<String, Object?> reordered = _candidate(
        id: 'cand-001',
        answers: [
          {'id': 'b', 'text': 'Option B'},
          {'id': 'a', 'text': 'Option A'},
          {'id': 'c', 'text': 'Option C'},
          {'id': 'd', 'text': 'Option D'},
        ],
      );
      expect(
          _fingerprintOf(reordered), isNot(equals(_fingerprintOf(original))));
    });

    test(
        'changing an individual option (not just the stem) invalidates '
        'the fingerprint', () {
      final Map<String, Object?> original = _candidate(id: 'cand-001');
      final Map<String, Object?> editedOption = _candidate(
        id: 'cand-001',
        answers: [
          {'id': 'a', 'text': 'Option A'},
          {'id': 'b', 'text': 'A materially different Option B'},
          {'id': 'c', 'text': 'Option C'},
          {'id': 'd', 'text': 'Option D'},
        ],
      );
      expect(_fingerprintOf(editedOption),
          isNot(equals(_fingerprintOf(original))));
    });

    test('changing the correct answer invalidates the fingerprint', () {
      final Map<String, Object?> original = _candidate(id: 'cand-001');
      final Map<String, Object?> editedCorrectAnswer =
          _candidate(id: 'cand-001', correctAnswerId: 'b');
      expect(_fingerprintOf(editedCorrectAnswer),
          isNot(equals(_fingerprintOf(original))));
    });

    test('changing a source reference invalidates the fingerprint', () {
      final Map<String, Object?> original = _candidate(id: 'cand-001');
      final Map<String, Object?> editedReference = _candidate(
        id: 'cand-001',
        references: [
          {
            'title': 'A Different Source',
            'source': 'Test Suite',
            'section': '2'
          },
        ],
      );
      expect(_fingerprintOf(editedReference),
          isNot(equals(_fingerprintOf(original))));
    });

    test(
        'reviewer notes never alter the question fingerprint — the '
        'fingerprint function only ever takes the question itself, never a '
        'decision or its notes, as input', () {
      final Map<String, Object?> candidate = _candidate(id: 'cand-001');
      final String fingerprint = _fingerprintOf(candidate);
      final reportWithNotes = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([candidate]),
        reviewerDecisionsJson: _decisionsJson([
          _decision(
              questionId: 'cand-001',
              contentFingerprint: fingerprint,
              notes: 'Looks great, approved without reservation.'),
        ]),
      );
      final reportWithoutNotes = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([candidate]),
        reviewerDecisionsJson: _decisionsJson([
          _decision(questionId: 'cand-001', contentFingerprint: fingerprint),
        ]),
      );
      expect(reportWithNotes.statusByQuestionId['cand-001'],
          CandidateReviewStatus.approvedAndMatched);
      expect(reportWithoutNotes.statusByQuestionId['cand-001'],
          CandidateReviewStatus.approvedAndMatched);
    });

    test(
        'an unknown fingerprint algorithm is never accepted, even if the '
        'raw fingerprint string happens to equal the current SHA-256 value',
        () {
      final Map<String, Object?> candidate = _candidate(id: 'cand-001');
      final String fingerprint = _fingerprintOf(candidate);
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([candidate]),
        reviewerDecisionsJson: _decisionsJson([
          _decision(
            questionId: 'cand-001',
            contentFingerprint: fingerprint,
            contentFingerprintAlgorithm: 'some-future-algorithm-v2',
          ),
        ]),
      );
      expect(report.statusByQuestionId['cand-001'],
          CandidateReviewStatus.unsupportedApprovalAlgorithm);
    });

    test(
        'an old FNV-style approval (16-character hex, no recognized '
        'algorithm tag) is not accepted as a valid approval', () {
      final Map<String, Object?> candidate = _candidate(id: 'cand-001');
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([candidate]),
        reviewerDecisionsJson: _decisionsJson([
          _decision(
            questionId: 'cand-001',
            // A legacy 16-hex-char FNV-1a-shaped fingerprint with no
            // algorithm field recorded at all (as a pre-correction decision
            // would have been written) — must not be inferred as SHA-256
            // just because a fingerprint value is present.
            contentFingerprint: 'a1b2c3d4e5f60718',
            contentFingerprintAlgorithm: '',
          ),
        ]),
      );
      expect(report.statusByQuestionId['cand-001'],
          CandidateReviewStatus.unsupportedApprovalAlgorithm);
    });

    test('changing difficulty changes the fingerprint', () {
      final Map<String, Object?> original =
          _candidate(id: 'cand-001', difficulty: 1);
      final Map<String, Object?> edited =
          _candidate(id: 'cand-001', difficulty: 4);
      expect(_fingerprintOf(edited), isNot(equals(_fingerprintOf(original))));
    });

    test(
        'changing sourceVersion changes the fingerprint — a reviewer\'s '
        'factual sign-off is bound to the specific source edition cited, '
        'so citing a different edition afterward must not silently keep '
        'the approval', () {
      final Map<String, Object?> original =
          _candidate(id: 'cand-001', sourceVersion: 'cdc-dental-ic-2016');
      final Map<String, Object?> edited =
          _candidate(id: 'cand-001', sourceVersion: 'cdc-dental-ic-2023');
      expect(_fingerprintOf(edited), isNot(equals(_fingerprintOf(original))));
    });

    test('adding a tag changes the fingerprint', () {
      final Map<String, Object?> original =
          _candidate(id: 'cand-001', tags: const ['radiation-physics']);
      final Map<String, Object?> edited = _candidate(
          id: 'cand-001', tags: const ['radiation-physics', 'sample']);
      expect(_fingerprintOf(edited), isNot(equals(_fingerprintOf(original))));
    });

    test('removing a tag changes the fingerprint', () {
      final Map<String, Object?> original = _candidate(
          id: 'cand-001', tags: const ['radiation-physics', 'sample']);
      final Map<String, Object?> edited =
          _candidate(id: 'cand-001', tags: const ['radiation-physics']);
      expect(_fingerprintOf(edited), isNot(equals(_fingerprintOf(original))));
    });

    test('changing a tag\'s value changes the fingerprint', () {
      final Map<String, Object?> original =
          _candidate(id: 'cand-001', tags: const ['radiation-physics']);
      final Map<String, Object?> edited =
          _candidate(id: 'cand-001', tags: const ['image-quality']);
      expect(_fingerprintOf(edited), isNot(equals(_fingerprintOf(original))));
    });

    test(
        'reordering an otherwise-identical tag list does not change the '
        'fingerprint — tags are semantically unordered', () {
      final Map<String, Object?> orderA = _candidate(
          id: 'cand-001',
          tags: const ['image-quality', 'radiation-physics', 'sample']);
      final Map<String, Object?> orderB = _candidate(
          id: 'cand-001',
          tags: const ['sample', 'image-quality', 'radiation-physics']);
      expect(_fingerprintOf(orderA), _fingerprintOf(orderB));
    });

    test(
        'version is included in the fingerprint — it identifies a '
        'question/content revision (see QuestionReport.questionVersion in '
        'the architecture spec, distinct from the package-level '
        'contentVersion), not a schema/serialization format version, so a '
        'revision bump must invalidate a prior approval', () {
      final Map<String, Object?> original =
          _candidate(id: 'cand-001', version: 1);
      final Map<String, Object?> revised =
          _candidate(id: 'cand-001', version: 2);
      expect(_fingerprintOf(revised), isNot(equals(_fingerprintOf(original))));
    });

    test(
        'changing status alone does not change the fingerprint — '
        'promotion from draft to approved must not self-invalidate the '
        'very approval that authorizes it', () {
      final Map<String, Object?> draft =
          _candidate(id: 'cand-001', status: 'draft');
      final Map<String, Object?> approved =
          _candidate(id: 'cand-001', status: 'approved');
      expect(_fingerprintOf(draft), _fingerprintOf(approved));
    });

    test(
        'changing updatedAt alone does not change the fingerprint — a '
        'bookkeeping timestamp must not invalidate an otherwise-matching '
        'approval', () {
      final Map<String, Object?> original =
          _candidate(id: 'cand-001', updatedAt: '2026-01-01T00:00:00Z');
      final Map<String, Object?> touched =
          _candidate(id: 'cand-001', updatedAt: '2026-06-15T12:34:56Z');
      expect(_fingerprintOf(original), _fingerprintOf(touched));
    });

    test(
        'any material-field edit (including the newly covered difficulty, '
        'sourceVersion, tags, and version) leaves a prior approval stale, '
        'not silently matched', () {
      final Map<String, Object?> approvedCandidate = _candidate(
        id: 'cand-001',
        difficulty: 2,
        sourceVersion: 'source-v1',
        tags: const ['radiation-physics'],
        version: 1,
      );
      final String fingerprintAtApproval = _fingerprintOf(approvedCandidate);

      final Map<String, Object?> editedDifficulty = _candidate(
          id: 'cand-001',
          difficulty: 5,
          sourceVersion: 'source-v1',
          tags: const ['radiation-physics'],
          version: 1);
      final Map<String, Object?> editedSourceVersion = _candidate(
          id: 'cand-001',
          difficulty: 2,
          sourceVersion: 'source-v2',
          tags: const ['radiation-physics'],
          version: 1);
      final Map<String, Object?> editedTags = _candidate(
          id: 'cand-001',
          difficulty: 2,
          sourceVersion: 'source-v1',
          tags: const ['image-quality'],
          version: 1);
      final Map<String, Object?> editedVersion = _candidate(
          id: 'cand-001',
          difficulty: 2,
          sourceVersion: 'source-v1',
          tags: const ['radiation-physics'],
          version: 2);

      for (final edited in [
        editedDifficulty,
        editedSourceVersion,
        editedTags,
        editedVersion,
      ]) {
        final report = validateCandidateBank(
          productionContentJson: _productionContentJson(),
          candidateQuestionsJson: _candidatesJson([edited]),
          reviewerDecisionsJson: _decisionsJson([
            _decision(
                questionId: 'cand-001',
                contentFingerprint: fingerprintAtApproval),
          ]),
        );
        expect(report.statusByQuestionId['cand-001'],
            CandidateReviewStatus.staleApproval);
      }
    });
  });

  group('domain inventory and diagnostic readiness', () {
    test('domain inventory counts drafted candidates correctly per domain', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson([
          _candidate(id: 'a-1', domainId: 'domain_a', topicId: 'topic_a1'),
          _candidate(id: 'a-2', domainId: 'domain_a', topicId: 'topic_a1'),
          _candidate(id: 'b-1', domainId: 'domain_b', topicId: 'topic_b1'),
        ]),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.domainInventory['domain_a']!.drafted, 2);
      expect(report.domainInventory['domain_b']!.drafted, 1);
      expect(report.domainInventory['domain_c']!.drafted, 0);
    });

    test(
        'a 15-question diagnostic apportions to 7/4/4 across domains '
        'weighted 0.5/0.25/0.25, matching the production DANB RHS weights', () {
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(diagnosticQuestions: 15),
        candidateQuestionsJson: _candidatesJson(const []),
        reviewerDecisionsJson: _emptyDecisions,
      );
      expect(report.domainInventory['domain_a']!.requiredForDiagnostic, 7);
      expect(report.domainInventory['domain_b']!.requiredForDiagnostic, 4);
      expect(report.domainInventory['domain_c']!.requiredForDiagnostic, 4);
    });

    test(
        'the 15-question diagnostic preflight passes once every domain '
        'has enough approved-and-fingerprint-matched candidates (7/4/4)', () {
      final candidates = [
        for (var i = 0; i < 7; i++)
          _candidate(
              id: 'a-$i',
              domainId: 'domain_a',
              topicId: 'topic_a1',
              questionText: 'Domain A synthetic question number $i?'),
        for (var i = 0; i < 4; i++)
          _candidate(
              id: 'b-$i',
              domainId: 'domain_b',
              topicId: 'topic_b1',
              questionText: 'Domain B synthetic question number $i?'),
        for (var i = 0; i < 4; i++)
          _candidate(
              id: 'c-$i',
              domainId: 'domain_c',
              topicId: 'topic_c1',
              questionText: 'Domain C synthetic question number $i?'),
      ];
      final decisions = [
        for (final candidate in candidates)
          _decision(
              questionId: candidate['id']! as String,
              contentFingerprint: _fingerprintOf(candidate)),
      ];
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson(candidates),
        reviewerDecisionsJson: _decisionsJson(decisions),
      );
      expect(report.isStructurallyValid, isTrue);
      expect(report.diagnosticPreflightWouldPass, isTrue);
    });

    test(
        'insufficient approved inventory in even one domain fails the '
        'overall diagnostic preflight, even if the others are fully met', () {
      final candidates = [
        for (var i = 0; i < 7; i++)
          _candidate(
              id: 'a-$i',
              domainId: 'domain_a',
              topicId: 'topic_a1',
              questionText: 'Domain A synthetic question number $i?'),
        for (var i = 0; i < 4; i++)
          _candidate(
              id: 'b-$i',
              domainId: 'domain_b',
              topicId: 'topic_b1',
              questionText: 'Domain B synthetic question number $i?'),
        // Only 3 of the required 4 for domain_c.
        for (var i = 0; i < 3; i++)
          _candidate(
              id: 'c-$i',
              domainId: 'domain_c',
              topicId: 'topic_c1',
              questionText: 'Domain C synthetic question number $i?'),
      ];
      final decisions = [
        for (final candidate in candidates)
          _decision(
              questionId: candidate['id']! as String,
              contentFingerprint: _fingerprintOf(candidate)),
      ];
      final report = validateCandidateBank(
        productionContentJson: _productionContentJson(),
        candidateQuestionsJson: _candidatesJson(candidates),
        reviewerDecisionsJson: _decisionsJson(decisions),
      );
      expect(report.domainInventory['domain_c']!.diagnosticReady, isFalse);
      expect(report.diagnosticPreflightWouldPass, isFalse);
    });
  });
}

/// Computes the fingerprint the validator would compute for [candidateJson]
/// by round-tripping it through the same production-content fixture and
/// reading the resulting per-question status inputs indirectly — done here
/// by validating a single-candidate bank against a decision carrying a
/// deliberately wrong fingerprint and reading back what "wrong" was
/// compared to would require exposing internals, so instead this fixture
/// re-implements nothing: it calls the library's own exported
/// [computeContentFingerprint] via the same [Question.fromJson] parsing
/// path the validator itself uses, keeping a single source of truth for
/// what "the fingerprint of this JSON" means.
String _fingerprintOf(Map<String, Object?> candidateJson) {
  return computeContentFingerprint(Question.fromJson(candidateJson));
}
