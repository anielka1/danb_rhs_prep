/// Plain-Dart validation library for the DANB RHS content workbench.
///
/// This is deliberately **not** production code: nothing under `lib/`
/// imports anything from `tool/`, this file is not registered as a
/// `pubspec.yaml` asset, and it exists solely to check the *structure* of
/// unbundled candidate content in `content_workbench/danb_rhs/` before a
/// qualified human reviews it. A clean validation result is never itself
/// an approval — see `docs/DANB_RHS_CONTENT_APPROVAL_WORKFLOW.md`.
///
/// Kept importable from `test/` via a relative path (Dart doesn't restrict
/// relative imports to `lib/`), so the checks here are unit-testable with
/// synthetic fixtures without touching disk.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';

/// The only fingerprint algorithm this validator currently trusts. Stored
/// explicitly on every reviewer decision (never inferred from fingerprint
/// length or shape) so a decision written under a retired algorithm — for
/// example a pre-SHA-256 FNV-1a fingerprint — is recognized as such rather
/// than silently compared byte-for-byte against a same-looking string.
const String kFingerprintAlgorithm = 'sha256-canonical-json-v1';

/// Domain-separation prefix mixed into every fingerprint's hashed bytes, so
/// this hash could never collide with a SHA-256 of the same canonical JSON
/// computed for an unrelated purpose elsewhere.
const String _fingerprintDomainSeparator = 'danb-rhs-question-approval:v1';

enum ValidationSeverity { error, warning }

class ValidationIssue {
  const ValidationIssue({
    required this.code,
    required this.message,
    required this.severity,
    this.path,
  });

  final String code;
  final String message;
  final ValidationSeverity severity;
  final String? path;

  @override
  String toString() =>
      '[${severity.name.toUpperCase()}] $code${path == null ? '' : ' ($path)'}: $message';
}

/// A reviewer's recorded decision on one candidate question, bound to the
/// exact [contentFingerprint] of the text they reviewed.
enum ReviewDecisionKind { reject, revise, approve }

class ReviewerDecision {
  const ReviewerDecision({
    required this.questionId,
    required this.contentFingerprint,
    required this.contentFingerprintAlgorithm,
    required this.decision,
    required this.reviewerIdentity,
    required this.reviewDate,
    this.notes,
  });

  final String questionId;
  final String contentFingerprint;

  /// The algorithm identifier the decision itself claims (e.g.
  /// `sha256-canonical-json-v1`), read verbatim from the JSON — never
  /// inferred from the fingerprint's length or format. Empty when the
  /// field is missing entirely, which a pre-SHA-256 decision would do;
  /// either way, anything other than [kFingerprintAlgorithm] is treated
  /// as unsupported/legacy, never silently accepted.
  final String contentFingerprintAlgorithm;
  final ReviewDecisionKind decision;
  final String reviewerIdentity;
  final DateTime? reviewDate;
  final String? notes;

  static ReviewDecisionKind? _decisionFromJson(Object? value) {
    if (value is! String) return null;
    for (final kind in ReviewDecisionKind.values) {
      if (kind.name == value) return kind;
    }
    return null;
  }

  factory ReviewerDecision.fromJson(Map<String, Object?> json) {
    return ReviewerDecision(
      questionId: _string(json['questionId']),
      contentFingerprint: _string(json['contentFingerprint']),
      contentFingerprintAlgorithm: _string(json['contentFingerprintAlgorithm']),
      decision:
          _decisionFromJson(json['decision']) ?? ReviewDecisionKind.reject,
      reviewerIdentity: _string(json['reviewerIdentity']),
      reviewDate: DateTime.tryParse(_string(json['reviewDate'])),
      notes: _nullableString(json['notes']),
    );
  }
}

/// The workbench-only lifecycle status of one candidate question, as
/// determined purely by structure and by matching reviewer decisions —
/// never by anything this tool decides on its own.
enum CandidateReviewStatus {
  invalid,
  awaitingReview,
  revisionRequested,
  rejected,
  approvedAndMatched,
  staleApproval,

  /// The latest decision is `approve`, but its
  /// `contentFingerprintAlgorithm` is not [kFingerprintAlgorithm] — e.g. a
  /// legacy pre-SHA-256 (FNV-1a) decision, or an algorithm this validator
  /// doesn't recognize. Never trusted regardless of whether the raw
  /// fingerprint string happens to match; requires renewed human review
  /// under the current algorithm.
  unsupportedApprovalAlgorithm,
}

class DomainInventory {
  DomainInventory({
    required this.domainId,
    required this.draftTarget,
    this.drafted = 0,
    this.approvedAndMatched = 0,
    this.requiredForDiagnostic = 0,
  });

  final String domainId;
  final int draftTarget;
  int drafted;
  int approvedAndMatched;
  int requiredForDiagnostic;

  bool get diagnosticReady => approvedAndMatched >= requiredForDiagnostic;
}

class CandidateBankReport {
  CandidateBankReport({
    required this.issues,
    required this.statusByQuestionId,
    required this.domainInventory,
    required this.diagnosticTargetCount,
  });

  final List<ValidationIssue> issues;
  final Map<String, CandidateReviewStatus> statusByQuestionId;
  final Map<String, DomainInventory> domainInventory;
  final int diagnosticTargetCount;

  bool get isStructurallyValid =>
      !issues.any((issue) => issue.severity == ValidationSeverity.error);

  bool get diagnosticPreflightWouldPass =>
      domainInventory.values.every((inventory) => inventory.diagnosticReady);

  String renderReport() {
    final buffer = StringBuffer();
    buffer.writeln('DANB RHS candidate content bank report');
    buffer.writeln('=' * 60);
    buffer.writeln('Structurally valid: ${isStructurallyValid ? 'YES' : 'NO'} '
        '(${issues.where((i) => i.severity == ValidationSeverity.error).length} error(s), '
        '${issues.where((i) => i.severity == ValidationSeverity.warning).length} warning(s))');
    buffer.writeln();
    buffer.writeln(
        'Domain inventory (target $diagnosticTargetCount-question diagnostic):');
    buffer.writeln(
        '${'Domain'.padRight(22)}${'Target'.padLeft(8)}${'Drafted'.padLeft(9)}${'Approved'.padLeft(10)}${'Required'.padLeft(10)}  Ready?');
    for (final inventory in domainInventory.values) {
      buffer.writeln('${inventory.domainId.padRight(22)}'
          '${inventory.draftTarget.toString().padLeft(8)}'
          '${inventory.drafted.toString().padLeft(9)}'
          '${inventory.approvedAndMatched.toString().padLeft(10)}'
          '${inventory.requiredForDiagnostic.toString().padLeft(10)}  '
          '${inventory.diagnosticReady ? 'yes' : 'no'}');
    }
    buffer.writeln();
    buffer.writeln('15-question diagnostic preflight would: '
        '${diagnosticPreflightWouldPass ? 'PASS' : 'FAIL'}');
    if (statusByQuestionId.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Per-question status:');
      for (final entry in statusByQuestionId.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value.name}');
      }
    }
    if (issues.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Issues:');
      for (final issue in issues) {
        buffer.writeln('  $issue');
      }
    }
    return buffer.toString();
  }
}

/// Recursively sorts every JSON object's keys (so key order in the source
/// JSON never affects the result) while preserving array order (element
/// order can itself be material — e.g. answer/reference ordering). Applied
/// only to already-decoded structured data, never to raw JSON text, so
/// whitespace differences in the original document can't affect the
/// output either.
Object? _canonicalize(Object? value) {
  if (value is Map) {
    final List<String> sortedKeys =
        value.keys.map((key) => key.toString()).toList(growable: false)..sort();
    return {for (final key in sortedKeys) key: _canonicalize(value[key])};
  }
  if (value is Iterable) {
    return value.map(_canonicalize).toList(growable: false);
  }
  return value;
}

/// Every field that can affect a question's meaning, diagnostic
/// eligibility, selection behavior, difficulty classification,
/// domain/topic classification, source provenance, or a human reviewer's
/// judgment — read from the already-parsed [Question] (never from raw
/// JSON text):
///
/// - `id` — an approval is bound to a specific question.
/// - `domainId`/`topicId` — domain/topic classification, which is
///   exactly what the diagnostic's blueprint allocation selects on.
/// - `questionText`, `answers` (with option IDs, in order),
///   `correctAnswerId`, `explanation`, `references` (in order) — the
///   question's actual tested content.
/// - `difficulty` — feeds difficulty-based selection/weighting; a
///   reviewer judging a question as, say, `2` did not review it as `4`.
/// - `sourceVersion` — identifies which edition/version of the
///   authoritative source the question was drafted against; a reviewer's
///   factual sign-off is bound to that specific source version, so citing
///   a superseded edition afterward must not silently keep the approval.
/// - `tags` — sorted (order carries no meaning; see [_normalizedTags]) but
///   the set contents are material, since tags support blueprint/topic
///   cross-referencing and future selection logic. A field is not excluded
///   merely because the current generator doesn't consume it yet — a
///   fingerprint is meant to hold up as the generator grows.
/// - `version` — the question's own content-revision number (see
///   `QuestionReport.questionVersion` in the architecture spec, which
///   exists specifically to distinguish which *revision* of a question's
///   content a report was filed against, separate from the package-level
///   `contentVersion`). This is a content-identity field, not a
///   schema/serialization-format version (that concept lives entirely
///   outside `Question`, e.g. the workbench file's own top-level
///   `schemaVersion`), so it is included.
///
/// Deliberately excluded:
/// - `status` — promotion from `draft` to `approved` is exactly the event
///   this fingerprint exists to survive; including it would make every
///   approval self-invalidating the moment it takes effect.
/// - `updatedAt` — a bookkeeping timestamp with no bearing on meaning; a
///   file touch or resave must not invalidate an otherwise-matching
///   approval.
/// - Anything that lives on the *reviewer decision* rather than the
///   question (notes, reviewer identity, review date) — a workflow-only
///   field can never affect the question's own fingerprint by
///   construction, since this function never receives the decision.
Map<String, Object?> _materialFields(Question question) {
  return {
    'id': question.id,
    'domainId': question.domainId,
    'topicId': question.topicId,
    'questionText': question.questionText,
    'answers': [
      for (final answer in question.answers)
        {'id': answer.id, 'text': answer.text},
    ],
    'correctAnswerId': question.correctAnswerId,
    'explanation': question.explanation,
    'references': [
      for (final reference in question.references)
        {
          'title': reference.title,
          'source': reference.source,
          'section': reference.section,
          'url': reference.url?.toString(),
        },
    ],
    'difficulty': question.difficulty,
    'sourceVersion': question.sourceVersion,
    'tags': _normalizedTags(question.tags),
    'version': question.version,
  };
}

/// Tags are order-insensitive — a reordered but otherwise-identical tag
/// list carries the same meaning — while the *set* of tags is material
/// (adding, removing, or changing a tag changes what the question is
/// cross-referenced under). Normalized here by sorting the already-trimmed
/// values `Question.fromJson` produces (no case-folding: tag case is not
/// assumed to be insignificant, so two differently-cased tags are treated
/// as genuinely different tags — consistent with the validator rejecting
/// exact-duplicate tags rather than silently merging near-duplicates).
List<String> _normalizedTags(List<String> tags) {
  return tags.toList()..sort();
}

/// The content fingerprint a human approval is bound to:
/// [kFingerprintAlgorithm] (SHA-256 over deterministic canonical JSON,
/// domain-separated), rendered as a lowercase 64-character hex digest.
/// Recomputing this for a question whose material fields haven't changed
/// always yields the same value; any change to a material field — stem,
/// options, correct answer, explanation, references, ID, domain/topic,
/// difficulty, sourceVersion, tag contents (not order), or the content
/// revision `version` — changes it. See [_materialFields] for the
/// complete list and the reasoning behind each inclusion/exclusion.
String computeContentFingerprint(Question question) {
  final Object? canonical = _canonicalize(_materialFields(question));
  final String canonicalJson = jsonEncode(canonical);
  final List<int> bytes =
      utf8.encode('$_fingerprintDomainSeparator:$canonicalJson');
  return crypto.sha256.convert(bytes).toString();
}

/// Largest-remainder apportionment of [total] items across [domains] by
/// their configured weights. This exists only to report how many approved
/// questions each domain *would* need for a diagnostic of this size — it
/// is a reporting helper for the content workbench, not the Section 3.5
/// diagnostic generator itself (which is out of scope for this task and
/// will need its own, separately tested implementation).
Map<String, int> apportionByWeight(List<DomainConfig> domains, int total) {
  if (domains.isEmpty || total <= 0) return const {};
  final Map<String, double> exact = {
    for (final domain in domains) domain.id: domain.weight * total,
  };
  final Map<String, int> allocation = {
    for (final domain in domains) domain.id: exact[domain.id]!.floor(),
  };

  if (total >= domains.length) {
    for (final domain in domains) {
      if (allocation[domain.id] == 0) {
        allocation[domain.id] = 1;
      }
    }
  }

  int remaining = total - allocation.values.fold(0, (a, b) => a + b);
  if (remaining > 0) {
    final remainders = domains
        .map((domain) => MapEntry(
            domain.id, exact[domain.id]! - exact[domain.id]!.floorToDouble()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var index = 0;
    while (remaining > 0 && remainders.isNotEmpty) {
      allocation[remainders[index % remainders.length].key] =
          (allocation[remainders[index % remainders.length].key] ?? 0) + 1;
      remaining -= 1;
      index += 1;
    }
  }
  return allocation;
}

/// Runs every structural check described in
/// `docs/DANB_RHS_CONTENT_APPROVAL_WORKFLOW.md` and
/// `docs/DANB_RHS_QUESTION_AUTHORING_GUIDE.md` against raw JSON strings —
/// kept string-in/report-out so it can be exercised by both the CLI
/// (`tool/validate_candidate_questions.dart`, which reads these strings
/// from disk) and unit tests (which pass synthetic fixtures directly).
CandidateBankReport validateCandidateBank({
  required String productionContentJson,
  required String candidateQuestionsJson,
  required String reviewerDecisionsJson,
}) {
  final issues = <ValidationIssue>[];

  late final ContentPackage production;
  try {
    production = const ExamContentCodec().decode(productionContentJson);
  } on Object catch (error) {
    issues.add(ValidationIssue(
      code: 'invalid_production_content',
      message: 'Production content.json could not be parsed: $error',
      severity: ValidationSeverity.error,
    ));
    return CandidateBankReport(
      issues: issues,
      statusByQuestionId: const {},
      domainInventory: const {},
      diagnosticTargetCount: 0,
    );
  }

  final Map<String, Object?> candidateRoot;
  final List<Object?> candidateJsonList;
  try {
    final decoded = jsonDecode(candidateQuestionsJson);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
          'candidate_questions.json must be a JSON object.');
    }
    candidateRoot = decoded;
    final candidates = candidateRoot['candidates'];
    if (candidates is! List<Object?>) {
      throw const FormatException(
          'candidate_questions.json must contain a "candidates" array.');
    }
    candidateJsonList = candidates;
  } on Object catch (error) {
    issues.add(ValidationIssue(
      code: 'invalid_candidate_json',
      message: 'candidate_questions.json could not be parsed: $error',
      severity: ValidationSeverity.error,
    ));
    return CandidateBankReport(
      issues: issues,
      statusByQuestionId: const {},
      domainInventory: const {},
      diagnosticTargetCount: 0,
    );
  }

  final List<ReviewerDecision> decisions;
  try {
    final decoded = jsonDecode(reviewerDecisionsJson);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
          'reviewer_decisions.json must be a JSON object.');
    }
    final decisionsJson = decoded['decisions'];
    if (decisionsJson is! List<Object?>) {
      throw const FormatException(
          'reviewer_decisions.json must contain a "decisions" array.');
    }
    decisions = decisionsJson
        .map((item) => ReviewerDecision.fromJson(
            item is Map<String, Object?> ? item : const <String, Object?>{}))
        .toList(growable: false);
  } on Object catch (error) {
    issues.add(ValidationIssue(
      code: 'invalid_reviewer_decisions_json',
      message: 'reviewer_decisions.json could not be parsed: $error',
      severity: ValidationSeverity.error,
    ));
    return CandidateBankReport(
      issues: issues,
      statusByQuestionId: const {},
      domainInventory: const {},
      diagnosticTargetCount: 0,
    );
  }

  final List<Question> candidates = candidateJsonList
      .map((item) => Question.fromJson(
          item is Map<String, Object?> ? item : const <String, Object?>{}))
      .toList(growable: false);

  final Map<String, Set<String>> domainTopics = {
    for (final domain in production.exam.domains)
      domain.id: domain.topics.map((topic) => topic.id).toSet(),
  };
  final Set<String> productionQuestionIds =
      production.questions.map((question) => question.id).toSet();

  final Set<String> seenCandidateIds = {};
  final Map<String, String> normalizedStemToFirstId = {};
  final Map<String, Question> candidateById = {};

  for (var index = 0; index < candidates.length; index++) {
    final question = candidates[index];
    final path = 'candidates[$index]';

    if (question.id.isEmpty) {
      issues.add(ValidationIssue(
        code: 'missing_candidate_id',
        message: 'Candidate question ID is required.',
        severity: ValidationSeverity.error,
        path: path,
      ));
      continue;
    }
    if (!seenCandidateIds.add(question.id)) {
      issues.add(ValidationIssue(
        code: 'duplicate_candidate_id',
        message: 'Duplicate candidate question ID: ${question.id}.',
        severity: ValidationSeverity.error,
        path: '$path.id',
      ));
      continue;
    }
    if (productionQuestionIds.contains(question.id)) {
      issues.add(ValidationIssue(
        code: 'production_id_collision',
        message:
            'Candidate ID "${question.id}" collides with an existing production question ID.',
        severity: ValidationSeverity.error,
        path: '$path.id',
      ));
    }
    candidateById[question.id] = question;

    if (question.status != QuestionStatus.draft) {
      issues.add(ValidationIssue(
        code: 'candidate_status_must_be_draft',
        message:
            'Candidate "${question.id}" must have status "draft" — only a recorded human '
            'decision in reviewer_decisions.json can move content toward approval.',
        severity: ValidationSeverity.error,
        path: '$path.status',
      ));
    }

    final topics = domainTopics[question.domainId];
    if (topics == null) {
      issues.add(ValidationIssue(
        code: 'unknown_domain',
        message:
            'Candidate "${question.id}" references unknown domain "${question.domainId}".',
        severity: ValidationSeverity.error,
        path: '$path.domainId',
      ));
    } else if (!topics.contains(question.topicId)) {
      issues.add(ValidationIssue(
        code: 'unknown_topic',
        message:
            'Candidate "${question.id}" references unknown topic "${question.topicId}" '
            'for domain "${question.domainId}".',
        severity: ValidationSeverity.error,
        path: '$path.topicId',
      ));
    }

    if (question.questionText.trim().isEmpty) {
      issues.add(ValidationIssue(
        code: 'empty_question_text',
        message: 'Candidate "${question.id}" has an empty stem.',
        severity: ValidationSeverity.error,
        path: '$path.questionText',
      ));
    } else {
      final normalizedStem = question.questionText
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ');
      final firstId = normalizedStemToFirstId[normalizedStem];
      if (firstId != null && firstId != question.id) {
        issues.add(ValidationIssue(
          code: 'duplicate_question_stem',
          message:
              'Candidate "${question.id}" has the same normalized stem as "$firstId".',
          severity: ValidationSeverity.error,
          path: '$path.questionText',
        ));
      } else {
        normalizedStemToFirstId[normalizedStem] = question.id;
      }
    }

    const int minimumOptionCount = 4;
    if (question.answers.length < minimumOptionCount) {
      issues.add(ValidationIssue(
        code: 'insufficient_option_count',
        message:
            'Candidate "${question.id}" has ${question.answers.length} option(s); '
            'the house minimum is $minimumOptionCount.',
        severity: ValidationSeverity.error,
        path: '$path.answers',
      ));
    }
    final Set<String> answerIds = {};
    for (var answerIndex = 0;
        answerIndex < question.answers.length;
        answerIndex++) {
      final answer = question.answers[answerIndex];
      if (answer.id.isEmpty || answer.text.trim().isEmpty) {
        issues.add(ValidationIssue(
          code: 'empty_option',
          message: 'Candidate "${question.id}" has an empty option ID or text.',
          severity: ValidationSeverity.error,
          path: '$path.answers[$answerIndex]',
        ));
      } else if (!answerIds.add(answer.id)) {
        issues.add(ValidationIssue(
          code: 'duplicate_option_id',
          message:
              'Candidate "${question.id}" has duplicate option ID "${answer.id}".',
          severity: ValidationSeverity.error,
          path: '$path.answers[$answerIndex]',
        ));
      }
    }

    if (question.correctAnswerId.isEmpty || question.correctAnswer == null) {
      issues.add(ValidationIssue(
        code: 'invalid_correct_answer',
        message:
            'Candidate "${question.id}" correctAnswerId does not match exactly one option.',
        severity: ValidationSeverity.error,
        path: '$path.correctAnswerId',
      ));
    }

    if (question.explanation.trim().isEmpty) {
      issues.add(ValidationIssue(
        code: 'empty_explanation',
        message: 'Candidate "${question.id}" has an empty explanation.',
        severity: ValidationSeverity.error,
        path: '$path.explanation',
      ));
    }

    if (question.references.isEmpty) {
      issues.add(ValidationIssue(
        code: 'missing_source_reference',
        message: 'Candidate "${question.id}" has no source reference.',
        severity: ValidationSeverity.error,
        path: '$path.references',
      ));
    } else {
      for (var refIndex = 0;
          refIndex < question.references.length;
          refIndex++) {
        final reference = question.references[refIndex];
        if (reference.title.isEmpty ||
            reference.source.isEmpty ||
            reference.section.isEmpty) {
          issues.add(ValidationIssue(
            code: 'incomplete_source_reference',
            message:
                'Candidate "${question.id}" reference[$refIndex] is missing title, '
                'source, or section (a specific locator, not just a publisher name).',
            severity: ValidationSeverity.error,
            path: '$path.references[$refIndex]',
          ));
        }
      }
    }

    // Tags are treated as a semantically unordered set (see
    // _normalizedTags), so a repeated tag is a structural defect, not a
    // meaningful distinct entry.
    final Set<String> seenTags = {};
    for (var tagIndex = 0; tagIndex < question.tags.length; tagIndex++) {
      if (!seenTags.add(question.tags[tagIndex])) {
        issues.add(ValidationIssue(
          code: 'duplicate_tag',
          message:
              'Candidate "${question.id}" has duplicate tag "${question.tags[tagIndex]}" — '
              'tags are an unordered set, so duplicates are meaningless.',
          severity: ValidationSeverity.error,
          path: '$path.tags[$tagIndex]',
        ));
      }
    }
  }

  // Reviewer-decision structural checks + per-question status resolution.
  final Map<String, List<ReviewerDecision>> decisionsByQuestionId = {};
  for (var index = 0; index < decisions.length; index++) {
    final decision = decisions[index];
    final path = 'decisions[$index]';
    if (decision.questionId.isEmpty ||
        !candidateById.containsKey(decision.questionId)) {
      issues.add(ValidationIssue(
        code: 'decision_references_unknown_candidate',
        message:
            'Reviewer decision references question ID "${decision.questionId}", which '
            'does not exist in candidate_questions.json.',
        severity: ValidationSeverity.error,
        path: '$path.questionId',
      ));
      continue;
    }
    if (decision.contentFingerprint.isEmpty) {
      issues.add(ValidationIssue(
        code: 'decision_missing_fingerprint',
        message:
            'Reviewer decision for "${decision.questionId}" is missing a content fingerprint.',
        severity: ValidationSeverity.error,
        path: '$path.contentFingerprint',
      ));
      continue;
    }
    if (decision.reviewerIdentity.isEmpty || decision.reviewDate == null) {
      issues.add(ValidationIssue(
        code: 'decision_missing_reviewer_metadata',
        message:
            'Reviewer decision for "${decision.questionId}" is missing a reviewer identity '
            'or a valid ISO-8601 review date.',
        severity: ValidationSeverity.error,
        path: path,
      ));
    }
    decisionsByQuestionId
        .putIfAbsent(decision.questionId, () => [])
        .add(decision);
  }

  // Every issue raised inside the per-candidate loop above carries a path
  // starting with "candidates[<index>]" — used here (rather than matching
  // on message text) to attribute structural errors back to the exact
  // candidate they belong to.
  final RegExp candidateIndexPattern = RegExp(r'^candidates\[(\d+)\]');
  final Set<String> questionIdsWithStructuralErrors = {};
  for (final issue in issues) {
    if (issue.severity != ValidationSeverity.error || issue.path == null) {
      continue;
    }
    final match = candidateIndexPattern.firstMatch(issue.path!);
    if (match == null) continue;
    final index = int.parse(match.group(1)!);
    if (index < candidates.length) {
      questionIdsWithStructuralErrors.add(candidates[index].id);
    }
  }

  final Map<String, CandidateReviewStatus> statusByQuestionId = {};
  for (final entry in candidateById.entries) {
    final question = entry.value;
    final bool hasStructuralError =
        questionIdsWithStructuralErrors.contains(question.id);

    if (hasStructuralError) {
      statusByQuestionId[question.id] = CandidateReviewStatus.invalid;
      continue;
    }

    final questionDecisions = decisionsByQuestionId[question.id] ?? const [];
    if (questionDecisions.isEmpty) {
      statusByQuestionId[question.id] = CandidateReviewStatus.awaitingReview;
      continue;
    }

    final latest = questionDecisions.last;
    final currentFingerprint = computeContentFingerprint(question);

    switch (latest.decision) {
      case ReviewDecisionKind.reject:
        statusByQuestionId[question.id] = CandidateReviewStatus.rejected;
      case ReviewDecisionKind.revise:
        statusByQuestionId[question.id] =
            CandidateReviewStatus.revisionRequested;
      case ReviewDecisionKind.approve:
        if (latest.contentFingerprintAlgorithm != kFingerprintAlgorithm) {
          // A legacy or unrecognized algorithm (e.g. a pre-SHA-256 FNV-1a
          // decision) is never trusted, regardless of whether the raw
          // fingerprint string happens to match — the algorithm is not
          // inferred from the fingerprint's shape, it must say so itself.
          statusByQuestionId[question.id] =
              CandidateReviewStatus.unsupportedApprovalAlgorithm;
        } else {
          statusByQuestionId[question.id] =
              latest.contentFingerprint == currentFingerprint
                  ? CandidateReviewStatus.approvedAndMatched
                  : CandidateReviewStatus.staleApproval;
        }
    }
  }

  // Domain inventory + diagnostic readiness.
  final int diagnosticTargetCount =
      production.exam.freeTier.diagnosticQuestions;
  final Map<String, int> required =
      apportionByWeight(production.exam.domains, diagnosticTargetCount);
  const Map<String, int> draftTargets = {
    'purpose_technique': 14,
    'radiation_protection': 8,
    'infection_control': 8,
  };

  final Map<String, DomainInventory> domainInventory = {
    for (final domain in production.exam.domains)
      domain.id: DomainInventory(
        domainId: domain.id,
        draftTarget: draftTargets[domain.id] ?? 0,
        requiredForDiagnostic: required[domain.id] ?? 0,
      ),
  };
  for (final question in candidateById.values) {
    final inventory = domainInventory[question.domainId];
    if (inventory == null) continue;
    inventory.drafted += 1;
    if (statusByQuestionId[question.id] ==
        CandidateReviewStatus.approvedAndMatched) {
      inventory.approvedAndMatched += 1;
    }
  }

  return CandidateBankReport(
    issues: issues,
    statusByQuestionId: statusByQuestionId,
    domainInventory: domainInventory,
    diagnosticTargetCount: diagnosticTargetCount,
  );
}

/// One domain's slice of [ProductionReadinessReport]: how many bundled
/// production questions are explicitly `approved` for this domain versus
/// how many a blueprint-balanced diagnostic would require.
class ProductionDomainReadiness {
  const ProductionDomainReadiness({
    required this.domainId,
    required this.approvedCount,
    required this.requiredCount,
  });

  final String domainId;
  final int approvedCount;
  final int requiredCount;

  bool get isReady => approvedCount >= requiredCount;
}

/// Whether the *bundled* production content (`assets/content/danb_rhs/
/// content.json` — what the shipped app actually loads) currently has
/// enough explicitly `approved` questions, per domain, for a
/// blueprint-balanced diagnostic. This deliberately looks only at
/// production content's own `status` field — never at the workbench, never
/// at candidate fingerprints or reviewer decisions — because a
/// fingerprint-matched workbench approval is not itself production-ready
/// until a human has manually promoted that question into `content.json`.
class ProductionReadinessReport {
  const ProductionReadinessReport({
    required this.diagnosticTargetCount,
    required this.domains,
    this.parseError,
  });

  final int diagnosticTargetCount;
  final Map<String, ProductionDomainReadiness> domains;

  /// Set only if production content.json itself could not be parsed —
  /// distinct from "parsed fine, just not enough approved inventory yet".
  final String? parseError;

  bool get isStructurallyValid => parseError == null;

  bool get isReady =>
      isStructurallyValid && domains.values.every((d) => d.isReady);

  String render() {
    final buffer = StringBuffer();
    buffer.writeln('Bundled production content readiness');
    buffer.writeln('=' * 60);
    if (!isStructurallyValid) {
      buffer.writeln('Could not evaluate: $parseError');
      return buffer.toString();
    }
    buffer.writeln(
        'Domain inventory (target $diagnosticTargetCount-question diagnostic):');
    buffer.writeln(
        '${'Domain'.padRight(22)}${'Approved'.padLeft(10)}${'Required'.padLeft(10)}  Ready?');
    for (final domain in domains.values) {
      buffer.writeln('${domain.domainId.padRight(22)}'
          '${domain.approvedCount.toString().padLeft(10)}'
          '${domain.requiredCount.toString().padLeft(10)}  '
          '${domain.isReady ? 'yes' : 'no'}');
    }
    buffer.writeln();
    buffer.writeln(
        'Production diagnostic readiness: ${isReady ? 'PASS' : 'FAIL'}');
    return buffer.toString();
  }
}

/// Evaluates [ProductionReadinessReport] from the raw production
/// content.json text. Counts only questions whose `status` is explicitly
/// `approved` — draft, reviewed, and retired questions never count, and
/// nothing from the workbench (candidates, fingerprints, reviewer
/// decisions) is consulted at all, matching how the shipped app itself
/// only ever reads bundled, already-approved content.
ProductionReadinessReport evaluateProductionReadiness(
  String productionContentJson,
) {
  late final ContentPackage production;
  try {
    production = const ExamContentCodec().decode(productionContentJson);
  } on Object catch (error) {
    return ProductionReadinessReport(
      diagnosticTargetCount: 0,
      domains: const {},
      parseError: error.toString(),
    );
  }

  final int diagnosticTargetCount =
      production.exam.freeTier.diagnosticQuestions;
  final Map<String, int> required =
      apportionByWeight(production.exam.domains, diagnosticTargetCount);

  final Map<String, int> approvedCounts = {
    for (final domain in production.exam.domains) domain.id: 0,
  };
  for (final question in production.questions) {
    if (question.status == QuestionStatus.approved &&
        approvedCounts.containsKey(question.domainId)) {
      approvedCounts[question.domainId] =
          approvedCounts[question.domainId]! + 1;
    }
  }

  return ProductionReadinessReport(
    diagnosticTargetCount: diagnosticTargetCount,
    domains: {
      for (final domain in production.exam.domains)
        domain.id: ProductionDomainReadiness(
          domainId: domain.id,
          approvedCount: approvedCounts[domain.id] ?? 0,
          requiredCount: required[domain.id] ?? 0,
        ),
    },
  );
}

/// File locations the CLI reads from, overridable so tests can point at
/// synthetic fixtures on disk (e.g. a temp-directory production
/// content.json with a controlled approved-question mix) without touching
/// the real repository files or spawning a subprocess.
class ValidatorCliPaths {
  const ValidatorCliPaths({
    this.productionContentPath = 'assets/content/danb_rhs/content.json',
    this.candidateQuestionsPath =
        'content_workbench/danb_rhs/candidate_questions.json',
    this.reviewerDecisionsPath =
        'content_workbench/danb_rhs/reviewer_decisions.json',
  });

  final String productionContentPath;
  final String candidateQuestionsPath;
  final String reviewerDecisionsPath;
}

const List<String> _kValidatorCliFlags = ['--report', '--require-ready'];
const String kValidatorCliUsage =
    'Usage: dart run tool/validate_candidate_questions.dart [--report] [--require-ready]';

/// Runs the validator CLI's full logic and returns the process exit code,
/// without ever calling `exit()`/reading `exitCode` itself — kept as a
/// plain function over injectable [out]/[err] sinks and [paths] so its
/// behavior and exit codes are unit-testable directly, not only through
/// fragile subprocess assertions. `bin/`-style entrypoints should be a
/// thin wrapper that just assigns `exitCode = runValidatorCli(...)`.
///
/// Exit codes:
/// - `0`: structurally valid; under `--require-ready`, also production-ready.
/// - `1`: an unknown CLI option, a missing input file, a JSON/schema
///   parsing failure, or any structural/approval-integrity validation
///   error (see [CandidateBankReport.isStructurallyValid]).
/// - `2`: only reachable under `--require-ready` — every input was
///   structurally valid, but the *bundled* production content does not yet
///   have enough explicitly `approved` questions, in the right domains,
///   for the configured diagnostic allocation.
int runValidatorCli(
  List<String> arguments, {
  required StringSink out,
  required StringSink err,
  ValidatorCliPaths paths = const ValidatorCliPaths(),
}) {
  final List<String> unknown =
      arguments.where((arg) => !_kValidatorCliFlags.contains(arg)).toList();
  if (unknown.isNotEmpty) {
    err.writeln('Unknown option(s): ${unknown.join(', ')}');
    err.writeln(kValidatorCliUsage);
    return 1;
  }

  final bool wantsReport = arguments.contains('--report');
  final bool requireReady = arguments.contains('--require-ready');

  final File productionFile = File(paths.productionContentPath);
  final File candidateFile = File(paths.candidateQuestionsPath);
  final File decisionsFile = File(paths.reviewerDecisionsPath);
  for (final file in [productionFile, candidateFile, decisionsFile]) {
    if (!file.existsSync()) {
      err.writeln('Missing required file: ${file.path}');
      return 1;
    }
  }

  final String productionJson = productionFile.readAsStringSync();
  final CandidateBankReport report = validateCandidateBank(
    productionContentJson: productionJson,
    candidateQuestionsJson: candidateFile.readAsStringSync(),
    reviewerDecisionsJson: decisionsFile.readAsStringSync(),
  );

  if (wantsReport || requireReady) {
    out.writeln(report.renderReport());
  } else {
    for (final issue in report.issues) {
      final String prefix =
          issue.severity == ValidationSeverity.error ? 'ERROR' : 'WARN';
      out.writeln('[$prefix] ${issue.code}: ${issue.message}');
    }
    out.writeln(report.isStructurallyValid
        ? 'Candidate bank is structurally valid.'
        : 'Candidate bank has structural errors.');
  }

  if (!report.isStructurallyValid) {
    return 1;
  }
  if (!requireReady) {
    return 0;
  }

  final ProductionReadinessReport readiness =
      evaluateProductionReadiness(productionJson);
  out.writeln();
  out.writeln(readiness.render());
  if (!readiness.isStructurallyValid) {
    // Already parsed once above via validateCandidateBank, so this should
    // not be reachable in practice — guarded defensively regardless.
    return 1;
  }
  return readiness.isReady ? 0 : 2;
}

String _string(Object? value) => value is String ? value.trim() : '';
String? _nullableString(Object? value) {
  final parsed = _string(value);
  return parsed.isEmpty ? null : parsed;
}
