import '../domain/models/entitlement.dart';
import '../domain/models/mock_attempt.dart';
import '../domain/models/practice_session.dart';
import '../domain/models/study_schedule.dart';
import '../domain/repositories/progress_repository.dart';
import '../domain/repositories/study_schedule_repository.dart';
import '../features/content/domain/content_package.dart';
import '../mock_exam/mock_exam_blueprint.dart';
import 'study_plan.dart';

class StudyScheduleService {
  const StudyScheduleService();
  Future<String?> change(
      {required ProgressRepository repository,
      required ContentPackage package,
      required Entitlement entitlement,
      required DateTime now,
      required DateTime date,
      required StudyDayType type,
      DateTime? moveTo,
      int? mockMinutes,
      bool reserveUnseen = false,
      DateTime? examDate}) async {
    if (repository is! StudyScheduleRepository) {
      throw StateError('Calendar storage is unavailable.');
    }
    final store = repository as StudyScheduleRepository;
    final today = calendarDate(now), target = calendarDate(date);
    if (!target.isAfter(today) ||
        moveTo != null && !calendarDate(moveTo).isAfter(today)) {
      throw StateError('Only future sessions can be changed.');
    }
    if (examDate != null &&
        (!target.isBefore(calendarDate(examDate)) ||
            moveTo != null &&
                !calendarDate(moveTo).isBefore(calendarDate(examDate)))) {
      throw StateError('Choose a study day before the exam.');
    }
    final sessions = await store.practiceSessionsForExam(package.exam.id);
    final locked = sessions
        .where((s) => s.status != SessionStatus.abandoned)
        .map((s) => s.planDate)
        .whereType<String>()
        .toSet();
    if (locked.contains(dateKey(target)) ||
        moveTo != null && locked.contains(dateKey(moveTo))) {
      throw StateError('Started and completed sessions cannot be moved.');
    }
    final entries = await store.studySchedule(package.exam.id);
    final updated = entries
        .where((e) =>
            e.date != dateKey(target) &&
            (moveTo == null || e.date != dateKey(moveTo)))
        .toList();
    var reserved = <String>[];
    String? notice;
    if (type == StudyDayType.mock) {
      final previous = await repository.mockAttemptsForExam(package.exam.id);
      if (previous.any((a) => a.status == MockAttemptStatus.inProgress)) {
        throw StateError(
            'Finish your active mock exam before scheduling another.');
      }
      if (!entitlement.isActiveAt(now) &&
          previous.length >= package.exam.freeTier.includedMockExams) {
        throw StateError('No mock exam allowance is available.');
      }
      if (mockMinutes != package.exam.mockExam.durationMinutes) {
        throw StateError(
            'A mock needs its own ${package.exam.mockExam.durationMinutes}-minute slot.');
      }
      final blueprint = MockExamBlueprint.fromPackage(package);
      if (reserveUnseen && previous.isEmpty) {
        final seen = (await repository.answerAttemptsForExam(package.exam.id))
            .map((a) => a.questionId)
            .toSet();
        seen.addAll(sessions
            .where((s) => s.status == SessionStatus.inProgress)
            .expand((s) => s.questionIds));
        final unseen = package.approvedQuestions
            .where((q) => !seen.contains(q.id))
            .map((q) => q.id)
            .toSet();
        final preferred =
            MockExamBlueprint.fromPackage(package, preferredQuestionIds: unseen)
                .questions;
        final candidate = preferred.map((q) => q.id).toSet();
        final topics = package.approvedQuestions.map((q) => q.topicId).toSet();
        final ordinaryTopics = package.approvedQuestions
            .where((q) => !candidate.contains(q.id))
            .map((q) => q.topicId)
            .toSet();
        if (candidate.every(unseen.contains) &&
            ordinaryTopics.containsAll(topics)) {
          reserved = candidate.toList();
        } else {
          notice =
              'Mock scheduled without a reserve: the ordinary pool needs these questions to preserve topic coverage.';
        }
      }
      if (blueprint.questions.isEmpty) {
        throw StateError('Mock content unavailable');
      }
      // One future mock reservation at a time; replacing/cancelling releases IDs.
      updated.removeWhere((e) => e.kind == 'mock');
    }
    if (moveTo != null) {
      if (entries.any((e) =>
          (e.date == dateKey(target) || e.date == dateKey(moveTo)) &&
          e.kind == 'mock')) {
        throw StateError(
            'Cancel the mock and schedule its separate time slot on the new date.');
      }
      updated.add(StudyScheduleEntry(
          examId: package.exam.id, date: dateKey(target), kind: 'rest'));
      updated.add(StudyScheduleEntry(
          examId: package.exam.id, date: dateKey(moveTo), kind: type.name));
      notice =
          'Session moved. The destination keeps one daily time budget; excess work stays in the projection.';
    } else {
      updated.add(StudyScheduleEntry(
          examId: package.exam.id,
          date: dateKey(target),
          kind: type.name,
          minutes: type == StudyDayType.mock ? mockMinutes : null,
          reservedQuestionIds: reserved));
    }
    await store.saveStudySchedule(package.exam.id, updated);
    return notice;
  }
}

/// Reservations stop restricting ordinary practice after the first mock starts,
/// when access is lost, or when the appointment is cancelled/expired.
Future<Set<String>> effectiveMockReserve(
    {required ProgressRepository repository,
    required ContentPackage package,
    required Entitlement entitlement,
    required DateTime now,
    DateTime? examDate}) async {
  if (repository is! StudyScheduleRepository) return {};
  final previous = await repository.mockAttemptsForExam(package.exam.id);
  if (previous.isNotEmpty ||
      !entitlement.isActiveAt(now) &&
          package.exam.freeTier.includedMockExams < 1) {
    return {};
  }
  final schedule = await (repository as StudyScheduleRepository)
      .studySchedule(package.exam.id);
  final approved = package.approvedQuestions.map((q) => q.id).toSet();
  final entries = schedule.where((e) =>
      e.kind == 'mock' &&
      !DateTime.parse(e.date).isBefore(calendarDate(now)) &&
      (examDate == null ||
          DateTime.parse(e.date).isBefore(calendarDate(examDate))));
  final ids = entries.expand((e) => e.reservedQuestionIds).toSet();
  if (!approved.containsAll(ids)) return {};
  final availableTopics =
      package.approvedQuestions.map((q) => q.topicId).toSet();
  final ordinaryTopics = package.approvedQuestions
      .where((q) => !ids.contains(q.id))
      .map((q) => q.topicId)
      .toSet();
  if (!ordinaryTopics.containsAll(availableTopics)) return {};
  return ids;
}
