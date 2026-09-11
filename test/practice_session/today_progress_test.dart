import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/practice_session/today_progress.dart';
import '../study_plan/fixtures.dart';

void main() {
  final q = fixture(count: 1).questions.single;
  final now = DateTime(2026, 9, 11);
  test('today excludes historical attempts and counts repeated answers', () {
    final stats = TodayProgress.fromAttempts([
      answer(q, now, seconds: 45),
      answer(q, now, id: 'repeat', correct: false, seconds: 30),
      answer(q, now.subtract(const Duration(days: 1)), seconds: 200),
    ], now);
    expect(stats.answered, 2);
    expect(stats.accuracyLabel, '50%');
    expect(stats.timeLabel, '1 min 15 sec');
  });
  test('unknown duration never becomes zero or a partial total', () {
    expect(TodayProgress.fromAttempts([], now).timeLabel, 'Not available');
    expect(TodayProgress.fromAttempts([], now).accuracyLabel, '—');
    expect(
        TodayProgress.fromAttempts(
                [answer(q, now), answer(q, now, seconds: 5)], now)
            .timeLabel,
        'Not available');
  });
  test('captured local date takes precedence over UTC timestamp', () {
    expect(
        TodayProgress.fromAttempts([
          answer(q, DateTime.utc(2026, 9, 12),
              localDay: '2026-09-11', seconds: 10)
        ], now)
            .answered,
        1);
  });
}
