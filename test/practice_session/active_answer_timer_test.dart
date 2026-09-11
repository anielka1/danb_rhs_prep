import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/practice_session/active_answer_timer.dart';

void main() {
  test('background and inactivity are excluded; interaction resumes counting',
      () {
    var now = DateTime(2026, 9, 11);
    final timer = ActiveAnswerTimer(now: () => now)..start();
    now = now.add(const Duration(seconds: 30));
    timer.stop();
    now = now.add(const Duration(hours: 1));
    expect(timer.elapsed.inSeconds, 30);
    timer.start();
    now = now.add(const Duration(minutes: 10));
    expect(timer.elapsed.inSeconds, 150);
    timer.interaction();
    now = now.add(const Duration(seconds: 10));
    expect(timer.elapsed.inSeconds, 160);
    timer.reset();
    expect(timer.elapsed, Duration.zero);
  });
}
