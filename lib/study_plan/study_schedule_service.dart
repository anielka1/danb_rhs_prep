import '../domain/models/entitlement.dart';
import '../domain/repositories/progress_repository.dart';
import '../domain/repositories/study_schedule_repository.dart';
import '../features/content/domain/content_package.dart';
import 'study_plan.dart';

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
