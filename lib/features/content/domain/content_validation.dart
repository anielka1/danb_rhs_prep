import 'dart:math' as math;

import '../../exams/domain/exam_config.dart';
import '../../questions/domain/question.dart';
import 'content_package.dart';

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
}

class ContentValidationResult {
  const ContentValidationResult(this.issues);

  final List<ValidationIssue> issues;

  bool get isValid =>
      !issues.any((issue) => issue.severity == ValidationSeverity.error);
  List<ValidationIssue> get errors => issues
      .where((issue) => issue.severity == ValidationSeverity.error)
      .toList(growable: false);
  List<ValidationIssue> get warnings => issues
      .where((issue) => issue.severity == ValidationSeverity.warning)
      .toList(growable: false);
}

class ContentValidator {
  const ContentValidator();

  ContentValidationResult validate(ContentPackage package) {
    final issues = <ValidationIssue>[];
    _validatePackage(package, issues);
    _validateExam(package.exam, issues);
    _validateQuestions(package, issues);
    return ContentValidationResult(List.unmodifiable(issues));
  }

  void _validatePackage(
    ContentPackage package,
    List<ValidationIssue> issues,
  ) {
    if (package.contentVersion.isEmpty ||
        package.contentVersion != package.exam.contentVersion) {
      _error(
        issues,
        'content_version_mismatch',
        'Package and exam content versions must match and be non-empty.',
        'contentVersion',
      );
    }
    if (package.sourceVersion.isEmpty) {
      _error(
        issues,
        'missing_source_version',
        'Source version is required.',
        'sourceVersion',
      );
    }
    if (package.generatedAt == null) {
      _error(
        issues,
        'invalid_generated_at',
        'generatedAt must be ISO-8601.',
        'generatedAt',
      );
    }
  }

  void _validateExam(ExamConfig exam, List<ValidationIssue> issues) {
    if (exam.id.isEmpty) {
      _error(issues, 'missing_exam_id', 'Exam ID is required.', 'exam.id');
    }
    if (exam.name.isEmpty || exam.provider.isEmpty) {
      _error(
        issues,
        'missing_exam_metadata',
        'Exam name and provider are required.',
        'exam',
      );
    }
    if (exam.examVersion.isEmpty || exam.disclaimer.isEmpty) {
      _error(
        issues,
        'missing_exam_versioning',
        'Exam version and disclaimer are required.',
        'exam',
      );
    }
    if (exam.domains.isEmpty) {
      _error(
        issues,
        'missing_domains',
        'At least one domain is required.',
        'exam.domains',
      );
    }

    final domainIds = <String>{};
    var weightTotal = 0.0;
    for (var index = 0; index < exam.domains.length; index++) {
      final domain = exam.domains[index];
      final path = 'exam.domains[$index]';
      if (domain.id.isEmpty || domain.name.isEmpty) {
        _error(
          issues,
          'invalid_domain',
          'Domain ID and name are required.',
          path,
        );
      }
      if (!domainIds.add(domain.id)) {
        _error(
          issues,
          'duplicate_domain_id',
          'Duplicate domain ID: ${domain.id}.',
          '$path.id',
        );
      }
      if (domain.weight <= 0 || domain.weight > 1) {
        _error(
          issues,
          'invalid_domain_weight',
          'Domain weight must be greater than 0 and at most 1.',
          '$path.weight',
        );
      }
      weightTotal += domain.weight;

      final topicIds = <String>{};
      for (var topicIndex = 0;
          topicIndex < domain.topics.length;
          topicIndex++) {
        final topic = domain.topics[topicIndex];
        if (topic.id.isEmpty || topic.name.isEmpty || !topicIds.add(topic.id)) {
          _error(
            issues,
            'invalid_topic',
            'Topic IDs and names must be non-empty and unique per domain.',
            '$path.topics[$topicIndex]',
          );
        }
      }
    }
    if ((weightTotal - 1).abs() > 0.0001) {
      _error(
        issues,
        'invalid_domain_weight_total',
        'Domain weights must total 1.0.',
        'exam.domains',
      );
    }

    if ((exam.readiness.weights.total - 1).abs() > 0.0001) {
      _error(
        issues,
        'invalid_readiness_weights',
        'Readiness component weights must total 1.0.',
        'exam.readiness.weights',
      );
    }
    final thresholdMinimums = exam.readiness.thresholds
        .map((threshold) => threshold.minimum)
        .toList(growable: false);
    if (thresholdMinimums.isEmpty ||
        thresholdMinimums.first != 0 ||
        !_strictlyIncreasing(thresholdMinimums) ||
        thresholdMinimums.last > 100) {
      _error(
        issues,
        'invalid_readiness_thresholds',
        'Readiness thresholds must start at 0 and increase through 100.',
        'exam.readiness.thresholds',
      );
    }
    if (exam.readiness.minimumEvidenceQuestions <= 0 ||
        exam.readiness.recencyHalfLifeDays <= 0 ||
        exam.readiness.priorScore < 0 ||
        exam.readiness.priorScore > 100 ||
        exam.readiness.weakDomainPenalty < 0 ||
        exam.readiness.weakDomainPenalty > 1) {
      _error(
        issues,
        'invalid_readiness_config',
        'Readiness evidence, decay, prior and penalty values are invalid.',
        'exam.readiness',
      );
    }

    final mock = exam.mockExam;
    if (mock.questionCount <= 0 ||
        mock.durationMinutes <= 0 ||
        mock.practicePassingPercent < 0 ||
        mock.practicePassingPercent > 100) {
      _error(
        issues,
        'invalid_mock_config',
        'Mock exam count, duration and passing score must be valid.',
        'exam.mockExam',
      );
    }
    final scoring = exam.officialScoring;
    if (scoring.scaleMinimum >= scoring.scaleMaximum ||
        scoring.passingScaledScore < scoring.scaleMinimum ||
        scoring.passingScaledScore > scoring.scaleMaximum) {
      _error(
        issues,
        'invalid_official_scoring',
        'Official scaled-score bounds and passing score are invalid.',
        'exam.officialScoring',
      );
    }
    if (exam.subscriptionProductIds.all.any((id) => id.isEmpty)) {
      _error(
        issues,
        'missing_product_id',
        'All subscription product IDs are required.',
        'exam.subscriptionProductIds',
      );
    }
  }

  void _validateQuestions(
    ContentPackage package,
    List<ValidationIssue> issues,
  ) {
    final domainTopics = <String, Set<String>>{
      for (final domain in package.exam.domains)
        domain.id: domain.topics.map((topic) => topic.id).toSet(),
    };
    final questionIds = <String>{};

    for (var index = 0; index < package.questions.length; index++) {
      final question = package.questions[index];
      final path = 'questions[$index]';
      if (question.id.isEmpty || !questionIds.add(question.id)) {
        _error(
          issues,
          'duplicate_or_missing_question_id',
          'Question IDs must be non-empty and unique.',
          '$path.id',
        );
      }
      if (question.examId != package.exam.id) {
        _error(
          issues,
          'invalid_question_exam',
          'Question examId must match the package exam.',
          '$path.examId',
        );
      }
      final topics = domainTopics[question.domainId];
      if (topics == null) {
        _error(
          issues,
          'invalid_question_domain',
          'Question references an unknown domain.',
          '$path.domainId',
        );
      } else if (!topics.contains(question.topicId)) {
        _error(
          issues,
          'invalid_question_topic',
          'Question references an unknown topic.',
          '$path.topicId',
        );
      }
      if (question.questionText.isEmpty) {
        _error(
          issues,
          'missing_question_text',
          'Question text is required.',
          '$path.questionText',
        );
      }
      if (question.answers.length < 2) {
        _error(
          issues,
          'missing_answers',
          'A question must contain at least two answers.',
          '$path.answers',
        );
      }
      final answerIds = <String>{};
      for (var answerIndex = 0;
          answerIndex < question.answers.length;
          answerIndex++) {
        final answer = question.answers[answerIndex];
        if (answer.id.isEmpty ||
            answer.text.isEmpty ||
            !answerIds.add(answer.id)) {
          _error(
            issues,
            'invalid_answer',
            'Answer IDs and text must be non-empty and IDs unique.',
            '$path.answers[$answerIndex]',
          );
        }
      }
      if (question.correctAnswerId.isEmpty || question.correctAnswer == null) {
        _error(
          issues,
          'invalid_correct_answer',
          'correctAnswerId must reference one of the answers.',
          '$path.correctAnswerId',
        );
      }
      if (question.explanation.isEmpty) {
        _error(
          issues,
          'missing_explanation',
          'Explanation is required.',
          '$path.explanation',
        );
      } else if (question.explanation.length < 40) {
        _warning(
          issues,
          'short_explanation',
          'Explanation may be too short for useful feedback.',
          '$path.explanation',
        );
      }
      if (question.difficulty < 1 || question.difficulty > 5) {
        _error(
          issues,
          'invalid_difficulty',
          'Difficulty must be between 1 and 5.',
          '$path.difficulty',
        );
      }
      if (question.status == QuestionStatus.unknown) {
        _error(
          issues,
          'invalid_question_status',
          'Question status is not recognized.',
          '$path.status',
        );
      }
      if (question.version <= 0 ||
          question.updatedAt == null ||
          question.sourceVersion.isEmpty) {
        _error(
          issues,
          'invalid_question_versioning',
          'Question version, updatedAt and sourceVersion are required.',
          path,
        );
      }
      if (question.references.isEmpty) {
        _warning(
          issues,
          'missing_reference',
          'Professionally reviewed content should include a reference.',
          '$path.references',
        );
      }
      for (var referenceIndex = 0;
          referenceIndex < question.references.length;
          referenceIndex++) {
        final reference = question.references[referenceIndex];
        final referencePath = '$path.references[$referenceIndex]';
        if (reference.title.isEmpty ||
            reference.source.isEmpty ||
            reference.section.isEmpty) {
          _error(
            issues,
            'invalid_reference',
            'Reference title, source and section are required.',
            referencePath,
          );
        }
        if (reference.url != null &&
            (!reference.url!.hasScheme || reference.url!.host.isEmpty)) {
          _error(
            issues,
            'malformed_reference_url',
            'Reference URL is malformed.',
            '$referencePath.url',
          );
        } else if (reference.url != null && reference.url!.scheme != 'https') {
          _warning(
            issues,
            'non_https_reference',
            'Reference URLs should use HTTPS.',
            '$referencePath.url',
          );
        }
      }
    }
  }

  bool _strictlyIncreasing(List<int> values) {
    for (var index = 1; index < values.length; index++) {
      if (values[index] <= values[index - 1]) return false;
    }
    return true;
  }

  void _error(
    List<ValidationIssue> issues,
    String code,
    String message,
    String path,
  ) {
    issues.add(ValidationIssue(
      code: code,
      message: message,
      severity: ValidationSeverity.error,
      path: path,
    ));
  }

  void _warning(
    List<ValidationIssue> issues,
    String code,
    String message,
    String path,
  ) {
    issues.add(ValidationIssue(
      code: code,
      message: message,
      severity: ValidationSeverity.warning,
      path: path,
    ));
  }
}

double readinessEvidenceConfidence(int uniqueQuestions, int minimumEvidence) {
  if (minimumEvidence <= 0 || uniqueQuestions <= 0) return 0;
  return math.min(1, math.sqrt(uniqueQuestions / minimumEvidence));
}
