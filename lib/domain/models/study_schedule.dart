/// A durable user exception. Date strings are local calendar dates (YYYY-MM-DD).
/// Mock slots have their own explicit duration, separate from ordinary practice.
class StudyScheduleEntry {
  const StudyScheduleEntry(
      {required this.examId,
      required this.date,
      required this.kind,
      this.minutes,
      this.reservedQuestionIds = const []});
  final String examId, date, kind;
  final int? minutes;
  final List<String> reservedQuestionIds;
}
