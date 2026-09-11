import 'dart:math';
import '../domain/models/answer_order.dart';
import '../domain/models/answer_attempt.dart';
import '../domain/models/practice_session.dart';
import '../domain/models/entitlement.dart';
import '../domain/repositories/progress_repository.dart';
import '../features/content/domain/content_package.dart';
import '../features/questions/domain/question.dart';
import '../practice_session/practice_generator.dart';
import '../practice_session/practice_session_controller.dart';
import 'study_plan.dart';

/// Uses the existing validation, eligibility and persistence gates. A started set
/// is immutable; projection updates never replace its question order or kinds.
class PlannedSessionService {
  const PlannedSessionService();
  Future<PracticeSessionController> start(
      {required ContentPackage package,
      required ProgressRepository repository,
      required Entitlement entitlement,
      required DateTime Function() now,
      StudyPlanDay? day,
      bool diagnostic = false,
      Set<String> reservedIds = const {},
      Random? random}) async {
    final active = await repository.inProgressPracticeSession(package.exam.id);
    final history = await repository.answerAttemptsForExam(package.exam.id);
    final eligible = PracticeGenerator.select(
            package: package,
            questionStates: const [],
            requestedCount: package.questions.length)
        .questions;
    final byId = {for (final q in eligible) q.id: q};
    if (active != null) {
      if (diagnostic && active.mode != PracticeMode.diagnostic) {
        throw const PracticeGenerationUnavailable(
            "Finish your active practice session first, or skip the diagnostic.");
      }
      if (active.questionIds.any((id) => !byId.containsKey(id))) {
        throw const PracticeGenerationUnavailable(
            'This saved session contains unavailable content. Your history is preserved.');
      }
      return PracticeSessionController.resume(
          session: active,
          questions: active.questionIds.map((id) => byId[id]!).toList(),
          progressRepository: repository,
          now: now);
    }
    final List<Question> questions;
    if (diagnostic) {
      if (history.any((a) => a.sessionType == AttemptSessionType.diagnostic)) {
        throw const PracticeGenerationUnavailable(
            'Your diagnostic is already recorded. Continue with your study plan.');
      }
      questions = diagnosticQuestions(package, reservedIds);
    } else {
      if (day == null || day.date != calendarDate(now())) {
        throw const PracticeGenerationUnavailable(
            'Refresh today’s plan before starting.');
      }
      final ids = day.questionIds;
      if (history.any((a) =>
          a.localAnsweredDate == dateKey(now()) &&
          ids.contains(a.questionId))) {
        throw const PracticeGenerationUnavailable(
            'Your work has been saved. Refresh your remaining plan.');
      }
      if (ids.isEmpty) {
        throw const PracticeGenerationUnavailable(
            'No questions are assigned today.');
      }
      final cap = maxFreePracticeQuestionsToday(
          entitlement: entitlement,
          now: now(),
          answeredToday:
              practiceAttemptsAnsweredToday(attempts: history, now: now()),
          dailyLimit: package.exam.freeTier.dailyPracticeQuestions);
      if (cap != null && ids.length > cap) {
        throw const PracticeGenerationUnavailable(
            'Your allowance changed. Refresh today’s plan. The free limit renews at 00:00 UTC.');
      }
      if (ids.toSet().length != ids.length ||
          ids.any((id) => !byId.containsKey(id) || reservedIds.contains(id))) {
        throw const PracticeGenerationUnavailable(
            'The available content changed. Refresh your plan.');
      }
      questions = ids.map((id) => byId[id]!).toList();
    }
    final session = PracticeSession(
        id: 'planned-${now().toUtc().microsecondsSinceEpoch}',
        examId: package.exam.id,
        mode: diagnostic ? PracticeMode.diagnostic : PracticeMode.planned,
        questionIds: questions.map((q) => q.id).toList(),
        answerOrder: AnswerOrder.shuffled(questions, random ?? Random()),
        status: SessionStatus.inProgress,
        startedAt: now().toUtc(),
        contentVersion: package.contentVersion,
        planDate: dateKey(now()),
        reviewQuestionIds: diagnostic ? const [] : day!.reviewIds);
    // Must be durable before opening the first question; failure is retryable.
    await repository.savePracticeSession(session);
    return PracticeSessionController(
        session: session,
        questions: questions,
        progressRepository: repository,
        now: now);
  }

  List<Question> diagnosticQuestions(
      ContentPackage package, Set<String> reservedIds) {
    final count = package.exam.freeTier.diagnosticQuestions;
    final pool = PracticeGenerator.select(
            package: package,
            questionStates: const [],
            requestedCount: package.questions.length)
        .questions
        .where((q) => q.isApproved && !reservedIds.contains(q.id))
        .toList();
    final domains = package.exam.domains;
    final quotas = {for (final d in domains) d.id: (d.weight * count).floor()};
    final ranked = [...domains]..sort((a, b) {
        final c = (b.weight * count - quotas[b.id]!)
            .compareTo(a.weight * count - quotas[a.id]!);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    final remainder = count - quotas.values.fold<int>(0, (a, b) => a + b);
    for (var i = 0; i < remainder; i++) {
      quotas[ranked[i].id] = quotas[ranked[i].id]! + 1;
    }
    final selected = <Question>[];
    for (final d in domains) {
      final candidates = pool.where((q) => q.domainId == d.id).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      if (candidates.length < quotas[d.id]!) {
        throw PracticeGenerationUnavailable(
            'The diagnostic needs $count approved questions across all areas. You can skip it and set up your plan.');
      }
      selected.addAll(candidates.take(quotas[d.id]!));
    }
    return selected;
  }
}
