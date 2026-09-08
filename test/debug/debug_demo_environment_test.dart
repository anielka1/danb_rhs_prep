import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/practice_session.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';
import 'package:danb_rhs_prep/features/content/domain/content_validation.dart';

void main() {
  group('determinism', () {
    test('demoProfile is identical across repeated access', () {
      expect(
          DebugDemoEnvironment.demoProfile, DebugDemoEnvironment.demoProfile);
      expect(
          DebugDemoEnvironment.demoProfile.createdAt, DateTime.utc(2026, 1, 1));
    });

    test('demoQuestions are identical across repeated access', () {
      expect(DebugDemoEnvironment.demoQuestions.map(_questionValues).toList(),
          DebugDemoEnvironment.demoQuestions.map(_questionValues).toList());
    });

    test(
        'demoPracticeSession, demoMockAttempt, demoReadinessSnapshot are '
        'identical across repeated access', () {
      expect(DebugDemoEnvironment.demoPracticeSession,
          DebugDemoEnvironment.demoPracticeSession);
      expect(DebugDemoEnvironment.demoMockAttempt,
          DebugDemoEnvironment.demoMockAttempt);
      expect(DebugDemoEnvironment.demoMockAttemptEarlier,
          DebugDemoEnvironment.demoMockAttemptEarlier);
      expect(DebugDemoEnvironment.demoReadinessSnapshot,
          DebugDemoEnvironment.demoReadinessSnapshot);
      expect(DebugDemoEnvironment.demoReadinessSnapshotEarlier,
          DebugDemoEnvironment.demoReadinessSnapshotEarlier);
    });
  });

  group('demo marking', () {
    test('demoExamId is distinct from the real bundled exam ID', () {
      expect(DebugDemoEnvironment.demoExamId, isNot('danb_rhs'));
    });

    test('there are at least 5 demo questions', () {
      expect(
          DebugDemoEnvironment.demoQuestions.length, greaterThanOrEqualTo(5));
    });

    test('every demo question has a unique demo-prefixed id', () {
      final ids = DebugDemoEnvironment.demoQuestions.map((q) => q.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'every demo question id must be unique');
      for (final id in ids) {
        expect(id, startsWith('demo-'));
      }
    });

    test('every demo question is tagged "demo" and not approved', () {
      for (final question in DebugDemoEnvironment.demoQuestions) {
        expect(question.tags, contains('demo'));
        expect(question.status, QuestionStatus.draft,
            reason: 'demo content must never claim any content-review '
                'status other than draft');
        expect(question.isApproved, isFalse,
            reason: 'demo content must never require or claim the real '
                'content-review approval status');
      }
    });

    test(
        'every demo question has deterministic, non-empty content and a '
        'valid correct answer', () {
      for (final question in DebugDemoEnvironment.demoQuestions) {
        expect(question.questionText, isNotEmpty);
        expect(question.answers, isNotEmpty);
        expect(question.correctAnswer, isNotNull,
            reason: 'correctAnswerId must match one of the listed answers');
        expect(question.updatedAt, DateTime.utc(2026, 1, 1),
            reason: 'demo content must use a fixed, deterministic '
                'timestamp, never DateTime.now()');
      }
    });

    test(
        'no demo question contains a clinical/dental-health claim '
        '(demo content is never professionally reviewed, so it must never '
        'assert anything that would require that review)', () {
      final clinicalTerms = RegExp(
        r'radiat|dental|x-ray|xray|patient|diagnos|clinical|dose|expos|'
        r'infection|sterili',
        caseSensitive: false,
      );
      for (final question in DebugDemoEnvironment.demoQuestions) {
        expect(clinicalTerms.hasMatch(question.questionText), isFalse,
            reason: 'demo question "${question.id}" reads as a clinical '
                'claim: "${question.questionText}"');
        expect(clinicalTerms.hasMatch(question.explanation), isFalse,
            reason: 'demo question "${question.id}" explanation reads as '
                'a clinical claim: "${question.explanation}"');
      }
    });
  });

  group('UserSettingsRepository fixture', () {
    test(
        'buildUserSettingsRepository returns the deterministic demo '
        'profile for demoExamId', () async {
      final repo = DebugDemoEnvironment.buildUserSettingsRepository();
      final profile = await repo.loadProfile(DebugDemoEnvironment.demoExamId);
      expect(profile, DebugDemoEnvironment.demoProfile);
    });

    test(
        'each call to buildUserSettingsRepository returns an independent '
        'instance', () async {
      final first = DebugDemoEnvironment.buildUserSettingsRepository();
      final second = DebugDemoEnvironment.buildUserSettingsRepository();
      await first.saveProfile(
        DebugDemoEnvironment.demoProfile.copyWith(dailyGoalQuestions: 999),
      );
      final secondProfile =
          await second.loadProfile(DebugDemoEnvironment.demoExamId);
      expect(secondProfile!.dailyGoalQuestions, 10,
          reason: 'mutating one built repository must not affect another');
    });
  });

  group('ProgressRepository fixture', () {
    test('writes are readable, isolated and reset for a fresh environment',
        () async {
      final first = DebugDemoEnvironment.buildProgressRepository();
      final second = DebugDemoEnvironment.buildProgressRepository();
      const examId = DebugDemoEnvironment.demoExamId;
      final question = DebugDemoEnvironment.demoQuestions.first;
      final state = await first.questionState(examId, question.id);
      await first.saveQuestionState(state.copyWith(bookmarked: true));
      expect(
          (await first.questionState(examId, question.id)).bookmarked, isTrue);
      expect((await second.questionState(examId, question.id)).bookmarked,
          isFalse);
      final restarted = DebugDemoEnvironment.buildProgressRepository();
      expect((await restarted.questionState(examId, question.id)).bookmarked,
          isFalse);
      expect(await first.answerAttemptsForExam('unknown'), isEmpty);
      expect(await first.mockAttempt('unknown'), isNull);
      expect(await first.latestReadinessSnapshot('unknown'), isNull);
      expect((await first.questionState(examId, 'unknown')).timesSeen, 0);
    });

    test(
        'buildProgressRepository returns the seeded practice session, '
        'mock attempt, readiness snapshot, question states, and answer '
        'attempts', () async {
      final repo = DebugDemoEnvironment.buildProgressRepository();

      final attempts =
          await repo.answerAttemptsForExam(DebugDemoEnvironment.demoExamId);
      expect(attempts, DebugDemoEnvironment.demoAnswerAttempts);

      final mockAttempt =
          await repo.mockAttempt(DebugDemoEnvironment.demoMockAttempt.id);
      expect(mockAttempt, DebugDemoEnvironment.demoMockAttempt);

      final readiness =
          await repo.latestReadinessSnapshot(DebugDemoEnvironment.demoExamId);
      expect(readiness, DebugDemoEnvironment.demoReadinessSnapshot);

      final states =
          await repo.questionStatesForExam(DebugDemoEnvironment.demoExamId);
      expect(states, hasLength(DebugDemoEnvironment.demoQuestionStates.length));

      // demoPracticeSession is already completed, so it must not be
      // returned as an in-progress session to resume — that role belongs
      // only to the separate demoInProgressPracticeSession fixture.
      final inProgress =
          await repo.inProgressPracticeSession(DebugDemoEnvironment.demoExamId);
      expect(inProgress, DebugDemoEnvironment.demoInProgressPracticeSession);
      expect(DebugDemoEnvironment.demoPracticeSession.status,
          SessionStatus.completed);
      expect(DebugDemoEnvironment.demoInProgressPracticeSession.status,
          SessionStatus.inProgress);
    });

    test(
        "buildProgressRepository's optional now freshens only the "
        "in-progress session's startedAt (PREP-457), never the exact "
        'fixture the no-args overload above still returns unchanged', () async {
      final DateTime fixedNow = DateTime.utc(2026, 9, 8, 12);
      final repo =
          DebugDemoEnvironment.buildProgressRepository(now: () => fixedNow);

      final PracticeSession? inProgress =
          await repo.inProgressPracticeSession(DebugDemoEnvironment.demoExamId);
      expect(inProgress, isNotNull);
      expect(
          inProgress!.startedAt, fixedNow.subtract(const Duration(minutes: 12)),
          reason: 'freshened relative to the given now, not the fixture\'s '
              'own 2026-01-01 literal — this is what keeps the demo\'s '
              "practice timer from reading as many months old however "
              'long after that date the demo is actually launched');
      expect(
          inProgress.id, DebugDemoEnvironment.demoInProgressPracticeSession.id,
          reason: 'every other field, including identity, is unchanged — '
              'only startedAt differs');
      expect(inProgress.questionIds,
          DebugDemoEnvironment.demoInProgressPracticeSession.questionIds);

      // The underlying fixture accessor itself is untouched — still the
      // exact deterministic literal this class always promises.
      expect(DebugDemoEnvironment.demoInProgressPracticeSession.startedAt,
          DateTime.utc(2026, 1, 1, 13));

      final mockAttempt =
          await repo.mockAttempt(DebugDemoEnvironment.demoMockAttempt.id);
      expect(mockAttempt, DebugDemoEnvironment.demoMockAttempt,
          reason: 'nothing else this factory seeds is affected by now');
    });
  });

  group('ContentRepository fixture', () {
    test('demo package passes the unchanged content validator', () {
      final package = DebugDemoEnvironment.demoContentPackage;
      final result = const ContentValidator().validate(package);
      expect(result.errors, isEmpty);
      expect(package.exam.mockExam.practicePassingPercent, 70);
    });

    test(
        'buildContentRepository serves the demo content package only '
        'under demoExamId', () async {
      final repo = DebugDemoEnvironment.buildContentRepository();
      final package = await repo.loadContentPackage(
        DebugDemoEnvironment.demoExamId,
      );
      expect(package.exam.id, DebugDemoEnvironment.demoExamId);
      // Question has no value-based `==`, so compare by id rather than
      // by object identity (demoQuestions is a getter that builds a
      // fresh list on every access).
      expect(package.questions.map((q) => q.id).toList(),
          DebugDemoEnvironment.demoQuestions.map((q) => q.id).toList());

      // Never claims to be the real, approved-content exam.
      await expectLater(
        repo.loadContentPackage('danb_rhs'),
        throwsA(isA<StateError>()),
      );
    });
  });
}

List<Object?> _questionValues(Question q) => [
      q.id,
      q.examId,
      q.domainId,
      q.topicId,
      q.questionText,
      q.answers.map((a) => [a.id, a.text, a.distractorExplanation]).toList(),
      q.correctAnswerId,
      q.explanation,
      q.references.map((r) => [r.title, r.source, r.section, r.url]).toList(),
      q.difficulty,
      q.status,
      q.version,
      q.updatedAt,
      q.sourceVersion,
      q.tags,
    ];
