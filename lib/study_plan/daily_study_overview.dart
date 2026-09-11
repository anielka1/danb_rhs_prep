import '../bootstrap/bootstrap_session_controller.dart';
import '../domain/models/practice_session.dart';
import '../domain/models/answer_attempt.dart';
import '../domain/models/study_schedule.dart';
import '../domain/repositories/progress_repository.dart';
import '../domain/repositories/study_schedule_repository.dart';
import '../practice_session/practice_generator.dart';
import 'study_plan.dart';
import 'study_schedule_service.dart';

/// One read model shared by Home and session completion; no new persisted state.
class DailyStudyOverview {
  const DailyStudyOverview(this.plan, this.active, this.attempts, this.sessions,
      this.reserve, this.quota);
  final StudyPlanProjection plan;
  final PracticeSession? active;
  final List<AnswerAttempt> attempts;
  final List<PracticeSession> sessions;
  final Set<String> reserve;
  final int? quota;
  static Future<DailyStudyOverview> load(BootstrapSessionController session,
      ProgressRepository repository, DateTime Function() now) async {
    final snapshot = session.snapshot;
    final active =
        await repository.inProgressPracticeSession(snapshot.selectedExamId);
    final attempts =
        await repository.answerAttemptsForExam(snapshot.selectedExamId);
    final schedule = repository is StudyScheduleRepository
        ? await (repository as StudyScheduleRepository)
            .studySchedule(snapshot.selectedExamId)
        : <StudyScheduleEntry>[];
    final sessions = repository is StudyScheduleRepository
        ? await (repository as StudyScheduleRepository)
            .practiceSessionsForExam(snapshot.selectedExamId)
        : <PracticeSession>[];
    final mocks = await repository.mockAttemptsForExam(snapshot.selectedExamId);
    final instant = now();
    final limit = maxFreePracticeQuestionsToday(
        entitlement: snapshot.entitlement,
        now: instant,
        answeredToday:
            practiceAttemptsAnsweredToday(attempts: attempts, now: instant),
        dailyLimit:
            snapshot.contentPackage.exam.freeTier.dailyPracticeQuestions);
    final reserve = await effectiveMockReserve(
        repository: repository,
        package: snapshot.contentPackage,
        entitlement: snapshot.entitlement,
        now: instant,
        examDate: snapshot.examDateSelection?.date);
    final plan = const StudyPlanPolicy().project(
        now: instant,
        localToday: instant,
        timezone: instant.timeZoneName,
        exam: snapshot.contentPackage.exam,
        preferences: snapshot.profile?.studyPlanPreferences,
        pool: snapshot.contentPackage.questions,
        attempts: attempts,
        examDate: snapshot.examDateSelection?.date,
        dailyQuestionLimit: snapshot.entitlement.isActiveAt(instant)
            ? null
            : snapshot.contentPackage.exam.freeTier.dailyPracticeQuestions,
        remainingUtcQuota: limit,
        sessions: sessions,
        mockBudgets: {
          for (final e in schedule)
            if (e.minutes != null) e.date: e.minutes!
        },
        reservedIds: reserve,
        additionalSeenIds: mocks.expand((m) => m.answers.keys).toSet(),
        overrides: {
          for (final e in schedule)
            e.date: StudyDayType.values.firstWhere((t) => t.name == e.kind,
                orElse: () => StudyDayType.study)
        });
    return DailyStudyOverview(plan, active, attempts, sessions, reserve, limit);
  }

  DailyTaskProgress progress(DateTime date) {
    final day =
        plan.days.where((d) => d.date == calendarDate(date)).firstOrNull;
    // The active saved set remains the action even if it began on an older day.
    final commitments = active?.mode == PracticeMode.planned
        ? [active!]
        : sessions
            .where((s) =>
                s.mode == PracticeMode.planned && s.planDate == dateKey(date))
            .toList();
    if (commitments.isEmpty) {
      return DailyTaskProgress(
          day?.recordedAnswers ?? 0,
          day?.newIds.length ?? 0,
          day?.reviewIds.length ?? 0,
          day?.status == StudyDayStatus.completed);
    }
    var done = 0, fresh = 0, reviews = 0;
    for (final s in commitments) {
      final answered = attempts
          .where((a) => a.sessionId == s.id)
          .map((a) => a.questionId)
          .toSet();
      for (final id in s.questionIds) {
        if (s.status == SessionStatus.completed || answered.contains(id)) {
          done++;
        } else if (s.reviewQuestionIds.contains(id)) {
          reviews++;
        } else {
          fresh++;
        }
      }
    }
    return DailyTaskProgress(
        done,
        fresh,
        reviews,
        fresh + reviews == 0 &&
            commitments.every((s) => s.status == SessionStatus.completed));
  }
}

class DailyTaskProgress {
  const DailyTaskProgress(this.done, this.fresh, this.reviews, this.completed);
  final int done, fresh, reviews;
  final bool completed;
  int get remaining => fresh + reviews;
}
