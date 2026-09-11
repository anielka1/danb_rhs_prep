import '../domain/models/answer_attempt.dart';

/// Local-day UI statistics. The free allowance continues to use UTC elsewhere.
/// Stored local dates survive travel; legacy records use the device's local date.
class TodayProgress {
  TodayProgress._(this.answered, this.correct, this.answeringSeconds);
  final int answered, correct;
  final int? answeringSeconds;
  factory TodayProgress.fromAttempts(
      List<AnswerAttempt> attempts, DateTime now) {
    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final today = attempts
        .where((a) =>
            (a.localAnsweredDate ?? key(a.answeredAt.toLocal())) == key(now))
        .toList();
    final reliable = today.isNotEmpty &&
        today.every((a) =>
            a.activeDurationSeconds != null && a.activeDurationSeconds! >= 0);
    return TodayProgress._(
        today.length,
        today.where((a) => a.isCorrect).length,
        reliable
            ? today.fold<int>(0, (sum, a) => sum + a.activeDurationSeconds!)
            : null);
  }
  String get accuracyLabel =>
      answered == 0 ? '—' : '${(correct * 100 / answered).round()}%';
  String get timeLabel {
    final s = answeringSeconds;
    if (s == null) return 'Not available';
    return s < 60 ? '$s sec' : '${s ~/ 60} min ${s % 60} sec';
  }
}
