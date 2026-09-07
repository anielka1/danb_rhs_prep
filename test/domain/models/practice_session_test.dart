import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/practice_session.dart';

void main() {
  PracticeSession buildSession({
    SessionStatus status = SessionStatus.inProgress,
    DateTime? completedAt,
    String? contentVersion,
  }) {
    return PracticeSession(
      id: 'session-1',
      examId: 'danb-rhs',
      mode: PracticeMode.quickPractice,
      questionIds: const ['q1', 'q2', 'q3'],
      status: status,
      startedAt: DateTime.utc(2026, 1, 1),
      completedAt: completedAt,
      contentVersion: contentVersion,
    );
  }

  test('equal field values produce equal instances and hash codes', () {
    final a = buildSession();
    final b = buildSession();
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('questionIds is not modifiable', () {
    final session = buildSession();
    expect(() => session.questionIds.add('q4'), throwsUnsupportedError);
  });

  test('copyWith can mark a session completed', () {
    final session = buildSession();
    final completedAt = DateTime.utc(2026, 1, 1, 1);

    final completed = session.copyWith(
      status: SessionStatus.completed,
      completedAt: completedAt,
    );

    expect(completed.status, SessionStatus.completed);
    expect(completed.completedAt, completedAt);
  });

  test('a completed status without completedAt violates the invariant', () {
    expect(
      () => buildSession(status: SessionStatus.completed),
      throwsArgumentError,
    );
  });

  test('a completedAt on a non-completed session violates the invariant', () {
    expect(
      () => buildSession(
        status: SessionStatus.inProgress,
        completedAt: DateTime.utc(2026, 1, 1, 1),
      ),
      throwsArgumentError,
    );
  });

  test(
      'contentVersion defaults to null, survives copyWith, and '
      'participates in equality', () {
    final withoutVersion = buildSession();
    expect(withoutVersion.contentVersion, isNull);

    final withVersion = buildSession(contentVersion: '2026.1');
    expect(withVersion, isNot(equals(withoutVersion)));
    expect(withVersion.contentVersion, '2026.1');
    expect(withVersion, equals(buildSession(contentVersion: '2026.1')));

    final completed = withVersion.copyWith(
      status: SessionStatus.completed,
      completedAt: DateTime.utc(2026, 1, 1, 1),
    );
    expect(completed.contentVersion, '2026.1',
        reason: 'copyWith must not drop the content version it was not '
            'asked to change');
  });
}
