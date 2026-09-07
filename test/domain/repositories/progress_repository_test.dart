import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/domain/repositories/progress_repository.dart';

void main() {
  group('canonicalAnsweredAt (PREP-664)', () {
    test('truncates milliseconds and microseconds to zero', () {
      final result =
          canonicalAnsweredAt(DateTime.utc(2026, 1, 1, 12, 30, 45, 123, 456));

      expect(result, DateTime.utc(2026, 1, 1, 12, 30, 45));
    });

    test(
        'is a true no-op for a value that already has whole-second '
        'precision', () {
      final alreadyCanonical = DateTime.utc(2026, 1, 1, 12, 30, 45);
      expect(canonicalAnsweredAt(alreadyCanonical), alreadyCanonical);
    });

    test(
        'converts to UTC before truncating, not after — a local value '
        'is normalized to the correct UTC instant, not merely stripped '
        'of its sub-second component while still in local time', () {
      final local = DateTime(2026, 1, 1, 12, 30, 45, 123, 456);
      final result = canonicalAnsweredAt(local);

      expect(result.isUtc, isTrue);
      // The instant must match `local` converted to UTC and truncated —
      // not `local`'s own field values (e.g. hour 12) reinterpreted as
      // if they were already UTC.
      final DateTime expectedUtc = local.toUtc();
      expect(
        result,
        DateTime.utc(expectedUtc.year, expectedUtc.month, expectedUtc.day,
            expectedUtc.hour, expectedUtc.minute, expectedUtc.second),
      );
    });
  });

  group('canonicalizeAnswerAttempt (PREP-664)', () {
    AnswerAttempt buildAttempt({required DateTime answeredAt}) {
      return AnswerAttempt(
        id: 'attempt-1',
        examId: 'danb-rhs',
        questionId: 'q1',
        domainId: 'radiation-protection',
        topicId: 'shielding',
        difficulty: 2,
        sessionId: 'session-1',
        sessionType: AttemptSessionType.practice,
        selectedAnswerId: 'a1',
        isCorrect: true,
        answeredAt: answeredAt,
        contentVersion: '2026.1',
      );
    }

    test(
        'only answeredAt changes — every other field is preserved '
        'exactly', () {
      final original =
          buildAttempt(answeredAt: DateTime.utc(2026, 1, 1, 12, 30, 45, 999));
      final canonical = canonicalizeAnswerAttempt(original);

      expect(canonical.answeredAt, DateTime.utc(2026, 1, 1, 12, 30, 45));
      expect(canonical.id, original.id);
      expect(canonical.examId, original.examId);
      expect(canonical.questionId, original.questionId);
      expect(canonical.domainId, original.domainId);
      expect(canonical.topicId, original.topicId);
      expect(canonical.difficulty, original.difficulty);
      expect(canonical.sessionId, original.sessionId);
      expect(canonical.sessionType, original.sessionType);
      expect(canonical.selectedAnswerId, original.selectedAnswerId);
      expect(canonical.isCorrect, original.isCorrect);
      expect(canonical.contentVersion, original.contentVersion);
    });

    test(
        'two attempts differing only in sub-second precision '
        'canonicalize to equal values', () {
      final a =
          buildAttempt(answeredAt: DateTime.utc(2026, 1, 1, 12, 30, 45, 1, 2));
      final b = buildAttempt(
          answeredAt: DateTime.utc(2026, 1, 1, 12, 30, 45, 999, 999));

      expect(canonicalizeAnswerAttempt(a), canonicalizeAnswerAttempt(b));
    });
  });
}
