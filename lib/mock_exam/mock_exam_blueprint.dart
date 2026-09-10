import '../domain/models/mock_attempt.dart';
import '../features/content/domain/content_package.dart';
import '../features/content/domain/content_validation.dart';
import '../features/exams/domain/exam_config.dart';
import '../features/questions/domain/question.dart';

/// A safe, user-facing reason why no exam can be started.
class MockExamUnavailable implements Exception {
  const MockExamUnavailable(this.message);
  final String message;
}

/// Validates content and allocates a deterministic, duplicate-free exam using
/// largest-remainder domain quotas. No UI, assets, network or fixture imports.
class MockExamBlueprint {
  MockExamBlueprint._(this.package, this.isDemo, this.quotas, this.questions);

  factory MockExamBlueprint.fromPackage(ContentPackage package,
      {Set<String> preferredQuestionIds = const {}}) {
    final validation = const ContentValidator().validate(package);
    if (!validation.isValid ||
        !package.exam.mockExam.practicePassingPercent.isFinite ||
        package.exam.domains.any((d) => !d.weight.isFinite)) {
      throw const MockExamUnavailable('Mock exam content is invalid.');
    }
    final isDemo = package.exam.id.startsWith('demo_') ||
        package.questions.any((q) => q.tags.contains('demo'));
    if (isDemo) {
      ensureDemoAllowed();
      if (!package.exam.id.startsWith('demo_') ||
          package.questions.any((q) =>
              !q.tags.contains('demo') ||
              !q.id.startsWith('demo-') ||
              !q.questionText.startsWith('[Demo]') ||
              q.status != QuestionStatus.draft)) {
        throw const MockExamUnavailable(
            'Demo questions must be clearly labelled drafts.');
      }
    }
    final eligible = isDemo ? package.questions : package.approvedQuestions;
    final count = package.exam.mockExam.questionCount;
    final domains = package.exam.domains;
    final quotas = <String, int>{
      for (final d in domains) d.id: (d.weight * count).floor(),
    };
    final ranked = List.generate(domains.length, (i) => i)
      ..sort((a, b) {
        final ra = domains[a].weight * count - quotas[domains[a].id]!;
        final rb = domains[b].weight * count - quotas[domains[b].id]!;
        final comparison = rb.compareTo(ra);
        return comparison == 0 ? a.compareTo(b) : comparison;
      });
    final remainder = count - quotas.values.fold(0, (a, b) => a + b);
    if (remainder < 0 || remainder > ranked.length) {
      throw const MockExamUnavailable('Mock exam domain weights are invalid.');
    }
    for (var i = 0; i < remainder; i++) {
      quotas[domains[ranked[i]].id] = quotas[domains[ranked[i]].id]! + 1;
    }
    final selected = <Question>[];
    for (final domain in domains) {
      final pool = eligible.where((q) => q.domainId == domain.id).toList()
        ..sort((a, b) {
          final pa = preferredQuestionIds.contains(a.id),
              pb = preferredQuestionIds.contains(b.id);
          return pa != pb ? (pa ? -1 : 1) : a.id.compareTo(b.id);
        });
      if (pool.length < quotas[domain.id]!) {
        throw const MockExamUnavailable(
            'There are not enough eligible questions for the configured mock exam.');
      }
      selected.addAll(pool.take(quotas[domain.id]!));
    }
    return MockExamBlueprint._(
        package, isDemo, Map.unmodifiable(quotas), List.unmodifiable(selected));
  }

  static void ensureDemoAllowed() {
    if (const bool.fromEnvironment('dart.vm.product') ||
        const bool.fromEnvironment('dart.vm.profile')) {
      throw const MockExamUnavailable('Demo exams require debug/test mode.');
    }
  }

  final ContentPackage package;
  final bool isDemo;
  final Map<String, int> quotas;
  final List<Question> questions;
  MockExamConfig get config => package.exam.mockExam;

  /// Restore only an attempt matching this content version and blueprint.
  /// Corruption is reported, never silently replaced with a new exam/result.
  List<Question> resolve(MockAttempt attempt) {
    if (attempt.examId != package.exam.id ||
        attempt.contentVersion != package.contentVersion ||
        attempt.questionIds.length != config.questionCount ||
        attempt.durationMinutes != config.durationMinutes) {
      throw const FormatException('Saved mock exam does not match content.');
    }
    final pool = {
      for (final q in (isDemo ? package.questions : package.approvedQuestions))
        q.id: q
    };
    final resolved = <Question>[];
    for (final id in attempt.questionIds) {
      final q = pool[id];
      if (q == null ||
          attempt.answers.containsKey(id) &&
              !q.answers.any((a) => a.id == attempt.answers[id])) {
        throw const FormatException('Saved mock exam has unresolved answers.');
      }
      resolved.add(q);
    }
    for (final entry in quotas.entries) {
      if (resolved.where((q) => q.domainId == entry.key).length !=
          entry.value) {
        throw const FormatException('Saved mock exam violates domain quotas.');
      }
    }
    return List.unmodifiable(resolved);
  }

  MockExamResult resultFor(MockAttempt attempt) {
    final resolved = resolve(attempt);
    final correct = resolved
        .where((q) => attempt.answers[q.id] == q.correctAnswerId)
        .length;
    if (attempt.status != MockAttemptStatus.completed ||
        attempt.correctCount != correct) {
      throw const FormatException(
          'A result requires a valid completed attempt.');
    }
    return MockExamResult._(
        attempt, config.practicePassingPercent, isDemo, resolved);
  }
}

/// Constructed only from a validated, completed attempt; never a UI default.
class MockExamResult {
  const MockExamResult._(
      this.attempt, this.threshold, this.isDemo, this.questions);
  static const disclaimer = 'Practice estimate only. This is not an official '
      'DANB result or a prediction of exam performance.';
  final MockAttempt attempt;

  /// Validated questions in attempt order, retained for read-only review.
  final List<Question> questions;
  final double threshold;
  final bool isDemo;
  String get outcome => outcomeFor(
        correctCount: attempt.correctCount!,
        totalQuestions: attempt.questionIds.length,
        thresholdPercent: threshold,
      );

  /// The same "Above/Below practice threshold" wording as [outcome], as a
  /// pure function over a score — lets other screens (e.g. a progress
  /// history list) describe a past attempt's outcome consistently without
  /// re-running this class's full, stricter attempt/blueprint validation,
  /// which is about proving a *current* attempt is genuine, not about
  /// looking up how an already-trusted historical record compares to
  /// today's threshold.
  static String outcomeFor({
    required int correctCount,
    required int totalQuestions,
    required double thresholdPercent,
  }) =>
      correctCount * 100 >= thresholdPercent * totalQuestions
          ? 'Above practice threshold'
          : 'Below practice threshold';
}
