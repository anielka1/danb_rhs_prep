import '../models/study_schedule.dart';
import '../models/practice_session.dart';

abstract interface class StudyScheduleRepository {
  Future<List<StudyScheduleEntry>> studySchedule(String examId);

  /// Replace exceptions in one transaction (moving a day never half-saves).
  Future<void> saveStudySchedule(
      String examId, List<StudyScheduleEntry> entries);
  Future<List<PracticeSession>> practiceSessionsForExam(String examId);
}
