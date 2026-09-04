import '../domain/models/answer_attempt.dart';
import '../domain/models/exam_date_precision.dart';
import '../domain/models/experience_level.dart';
import '../domain/models/mock_attempt.dart';
import '../domain/models/practice_session.dart';
import '../domain/models/question_state.dart';
import '../domain/models/readiness_band.dart';
import '../domain/models/readiness_snapshot.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/content_repository.dart';
import '../domain/repositories/fakes/in_memory_content_repository.dart';
import '../domain/repositories/fakes/in_memory_progress_repository.dart';
import '../domain/repositories/fakes/in_memory_user_settings_repository.dart';
import '../domain/repositories/progress_repository.dart';
import '../domain/repositories/user_settings_repository.dart';
import '../features/content/domain/content_package.dart';
import '../features/exams/domain/exam_config.dart';
import '../features/questions/domain/question.dart';

/// Deterministic, synthetic fixtures and injectable fake repositories for
/// exercising app screens without a real backend, a real reviewed content
/// bank, or a real user account.
///
/// **Debug/test only — never activated in release.** Nothing in this file
/// imports Flutter (proven by
/// `test/debug/debug_demo_environment_dependency_direction_test.dart`,
/// mirroring `test/bootstrap/dependency_direction_test.dart`'s existing
/// boundary check), and this class does not decide *when* it is allowed
/// to run. Isolation is a separate **entrypoint**, not a runtime flag:
/// `lib/main.dart` — what plain `flutter run` and
/// `flutter build ios --release --no-codesign` always build from — has
/// zero import or reference to this class at all
/// (`test/main_test.dart`'s isolation check proves this at the source
/// level). The only place this environment is ever activated is
/// `lib/main_demo.dart`, a distinct entrypoint run explicitly via
/// `flutter run -t lib/main_demo.dart` (see that file's own doc comment
/// for exactly what it wires and why). Since `lib/main.dart` has no code
/// path that can reach `DebugDemoEnvironment`, there is nothing for a
/// release build to strip — it was never reachable to begin with.
///
/// All values below are fixed literals — no `DateTime.now()`, no
/// `Random()` — so every fixture is byte-for-byte identical across runs;
/// see `test/debug/debug_demo_environment_test.dart`'s determinism cases.
/// Every demo ID is prefixed `demo-`/`demo_` and every demo [Question]
/// carries the `demo` tag, so demo data can never be mistaken for real
/// user or content data if it ever leaked somewhere it shouldn't.
class DebugDemoEnvironment {
  DebugDemoEnvironment._();

  /// Distinct from the real, bundled exam ID (`kDefaultExamId` /
  /// `'danb_rhs'`, see `AppBootstrapService`) so a demo [ContentRepository]
  /// built from this environment can never satisfy a real bootstrap's
  /// request for the real exam, even if it were wired in by mistake —
  /// `AppBootstrapService` only ever resolves and requests `'danb_rhs'`.
  static const String demoExamId = 'demo_exam';

  static const String _demoQuestionId1 = 'demo-question-1';
  static const String _demoQuestionId2 = 'demo-question-2';
  static const String _demoQuestionId3 = 'demo-question-3';
  static const String _demoQuestionId4 = 'demo-question-4';
  static const String _demoQuestionId5 = 'demo-question-5';
  static const String _demoAnswerCorrect = 'a';
  static const String _demoAnswerIncorrect = 'b';

  /// A deterministic, fully onboarded demo profile.
  static UserProfile get demoProfile => UserProfile(
        examId: demoExamId,
        experienceLevel: ExperienceLevel.studyingAlready,
        examDatePrecision: ExamDatePrecision.notScheduled,
        dailyGoalQuestions: 10,
        notificationsEnabled: false,
        themePreference: ThemePreference.system,
        onboardingComplete: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  /// Five small, synthetic, clearly-labeled demo questions — never the
  /// real reviewed content bank, and never required to hold
  /// `QuestionStatus.approved` (demo data does not go through content
  /// review at all). Deliberately plain general-knowledge/logic trivia,
  /// not anything resembling a dental radiation-health-and-safety claim —
  /// demo content must never carry a clinical assertion that would need
  /// professional review, since it never goes through that review.
  static List<Question> get demoQuestions => [
        Question(
          id: _demoQuestionId1,
          examId: demoExamId,
          domainId: 'demo_domain',
          topicId: 'demo_topic',
          questionText: '[Demo] What is 2 + 2?',
          answers: const [
            Answer(id: _demoAnswerCorrect, text: '4'),
            Answer(id: _demoAnswerIncorrect, text: '5'),
          ],
          correctAnswerId: _demoAnswerCorrect,
          explanation: 'This is a synthetic demo question, not real exam '
              'content.',
          references: const [],
          difficulty: 1,
          status: QuestionStatus.draft,
          version: 1,
          updatedAt: DateTime.utc(2026, 1, 1),
          sourceVersion: 'demo-fixtures-v1',
          tags: const ['demo'],
        ),
        Question(
          id: _demoQuestionId2,
          examId: demoExamId,
          domainId: 'demo_domain',
          topicId: 'demo_topic',
          questionText: '[Demo] What color is the sky on a clear day?',
          answers: const [
            Answer(id: _demoAnswerCorrect, text: 'Blue'),
            Answer(id: _demoAnswerIncorrect, text: 'Green'),
          ],
          correctAnswerId: _demoAnswerCorrect,
          explanation: 'This is a synthetic demo question, not real exam '
              'content.',
          references: const [],
          difficulty: 1,
          status: QuestionStatus.draft,
          version: 1,
          updatedAt: DateTime.utc(2026, 1, 1),
          sourceVersion: 'demo-fixtures-v1',
          tags: const ['demo'],
        ),
        Question(
          id: _demoQuestionId3,
          examId: demoExamId,
          domainId: 'demo_domain',
          topicId: 'demo_topic',
          questionText: '[Demo] How many days are in a week?',
          answers: const [
            Answer(id: _demoAnswerCorrect, text: '7'),
            Answer(id: _demoAnswerIncorrect, text: '10'),
          ],
          correctAnswerId: _demoAnswerCorrect,
          explanation: 'This is a synthetic demo question, not real exam '
              'content.',
          references: const [],
          difficulty: 1,
          status: QuestionStatus.draft,
          version: 1,
          updatedAt: DateTime.utc(2026, 1, 1),
          sourceVersion: 'demo-fixtures-v1',
          tags: const ['demo'],
        ),
        Question(
          id: _demoQuestionId4,
          examId: demoExamId,
          domainId: 'demo_domain',
          topicId: 'demo_topic',
          questionText: '[Demo] What is the capital of France?',
          answers: const [
            Answer(id: _demoAnswerCorrect, text: 'Paris'),
            Answer(id: _demoAnswerIncorrect, text: 'Berlin'),
          ],
          correctAnswerId: _demoAnswerCorrect,
          explanation: 'This is a synthetic demo question, not real exam '
              'content.',
          references: const [],
          difficulty: 1,
          status: QuestionStatus.draft,
          version: 1,
          updatedAt: DateTime.utc(2026, 1, 1),
          sourceVersion: 'demo-fixtures-v1',
          tags: const ['demo'],
        ),
        Question(
          id: _demoQuestionId5,
          examId: demoExamId,
          domainId: 'demo_domain',
          topicId: 'demo_topic',
          questionText: '[Demo] Which shape has exactly three sides?',
          answers: const [
            Answer(id: _demoAnswerCorrect, text: 'Triangle'),
            Answer(id: _demoAnswerIncorrect, text: 'Square'),
          ],
          correctAnswerId: _demoAnswerCorrect,
          explanation: 'This is a synthetic demo question, not real exam '
              'content.',
          references: const [],
          difficulty: 1,
          status: QuestionStatus.draft,
          version: 1,
          updatedAt: DateTime.utc(2026, 1, 1),
          sourceVersion: 'demo-fixtures-v1',
          tags: const ['demo'],
        ),
      ];

  /// A minimal but fully valid [ExamConfig] so [demoContentPackage] can be
  /// served through the same [ContentRepository] interface production
  /// code depends on, without a second real exam existing anywhere.
  static const ExamConfig _demoExamConfig = ExamConfig(
    id: demoExamId,
    name: 'Demo Exam',
    provider: 'Demo',
    examVersion: 'demo-1',
    contentVersion: 'demo-1',
    domains: [
      DomainConfig(
        id: 'demo_domain',
        name: 'Demo Domain',
        weight: 1.0,
        topics: [TopicConfig(id: 'demo_topic', name: 'Demo Topic')],
      ),
    ],
    mockExam: MockExamConfig(
      questionCount: 5,
      durationMinutes: 10,
      practicePassingPercent: 0.7,
      allowsBackNavigation: true,
      timed: false,
    ),
    officialScoring: OfficialScoringConfig(
      scaleMinimum: 0,
      scaleMaximum: 100,
      passingScaledScore: 70,
      isComputerAdaptive: false,
    ),
    readiness: ReadinessConfig(
      weights: ReadinessWeights(
        recentAccuracy: 0.3,
        domainMastery: 0.3,
        mockPerformance: 0.2,
        repeatedMastery: 0.1,
        coverage: 0.1,
      ),
      thresholds: [
        ReadinessThreshold(
            minimum: 0, label: 'Starting', band: ReadinessBand.starting),
        ReadinessThreshold(
            minimum: 70,
            label: 'Getting close',
            band: ReadinessBand.gettingClose),
      ],
      priorScore: 50,
      minimumEvidenceQuestions: 1,
      recencyHalfLifeDays: 14,
      weakDomainPenalty: 0.1,
    ),
    subscriptionProductIds: SubscriptionProductIds(
      weekly: 'demo.weekly',
      monthly: 'demo.monthly',
      threeMonths: 'demo.three_months',
    ),
    freeTier: FreeTierConfig(
      dailyPracticeQuestions: 10,
      diagnosticQuestions: 2,
      includedMockExams: 0,
    ),
    disclaimer: 'This is synthetic demo content, not a real exam.',
  );

  static ContentPackage get demoContentPackage => ContentPackage(
        exam: _demoExamConfig,
        contentVersion: 'demo-1',
        sourceVersion: 'demo-fixtures-v1',
        generatedAt: DateTime.utc(2026, 1, 1),
        questions: demoQuestions,
      );

  static PracticeSession get demoPracticeSession => PracticeSession(
        id: 'demo-practice-session-1',
        examId: demoExamId,
        mode: PracticeMode.quickPractice,
        questionIds: const [_demoQuestionId1, _demoQuestionId2],
        status: SessionStatus.completed,
        startedAt: DateTime.utc(2026, 1, 1, 9),
        completedAt: DateTime.utc(2026, 1, 1, 9, 10),
      );

  static MockAttempt get demoMockAttempt => MockAttempt(
        id: 'demo-mock-attempt-1',
        examId: demoExamId,
        questionIds: const [_demoQuestionId1, _demoQuestionId2],
        answers: const {
          _demoQuestionId1: _demoAnswerCorrect,
          _demoQuestionId2: _demoAnswerCorrect,
        },
        flaggedQuestionIds: const {},
        status: MockAttemptStatus.completed,
        startedAt: DateTime.utc(2026, 1, 1, 10),
        durationMinutes: 10,
        completedAt: DateTime.utc(2026, 1, 1, 10, 10),
        correctCount: 2,
      );

  static List<AnswerAttempt> get demoAnswerAttempts => [
        AnswerAttempt(
          id: 'demo-attempt-1',
          examId: demoExamId,
          questionId: _demoQuestionId1,
          domainId: 'demo_domain',
          topicId: 'demo_topic',
          difficulty: 1,
          sessionId: demoPracticeSession.id,
          sessionType: AttemptSessionType.practice,
          selectedAnswerId: _demoAnswerCorrect,
          isCorrect: true,
          answeredAt: DateTime.utc(2026, 1, 1, 9, 5),
        ),
        AnswerAttempt(
          id: 'demo-attempt-2',
          examId: demoExamId,
          questionId: _demoQuestionId2,
          domainId: 'demo_domain',
          topicId: 'demo_topic',
          difficulty: 1,
          sessionId: demoPracticeSession.id,
          sessionType: AttemptSessionType.practice,
          selectedAnswerId: _demoAnswerCorrect,
          isCorrect: true,
          answeredAt: DateTime.utc(2026, 1, 1, 9, 9),
        ),
      ];

  static List<QuestionState> get demoQuestionStates => [
        QuestionState(
          examId: demoExamId,
          questionId: _demoQuestionId1,
          bookmarked: false,
          timesSeen: 1,
          timesCorrect: 1,
          timesIncorrect: 0,
          consecutiveCorrect: 1,
          lastAnsweredAt: DateTime.utc(2026, 1, 1, 9, 5),
        ),
        QuestionState(
          examId: demoExamId,
          questionId: _demoQuestionId2,
          bookmarked: false,
          timesSeen: 1,
          timesCorrect: 1,
          timesIncorrect: 0,
          consecutiveCorrect: 1,
          lastAnsweredAt: DateTime.utc(2026, 1, 1, 9, 9),
        ),
      ];

  static ReadinessSnapshot get demoReadinessSnapshot => ReadinessSnapshot(
        id: 'demo-readiness-1',
        examId: demoExamId,
        calculatedAt: DateTime.utc(2026, 1, 1, 11),
        overallScore: 72,
        band: ReadinessBand.gettingClose,
        recentAccuracyComponent: 0.8,
        domainMasteryComponent: 0.7,
        mockPerformanceComponent: 0.75,
        repeatedMasteryComponent: 0.6,
        coverageComponent: 0.5,
        evidenceConfidence: 0.6,
        uniqueQuestionsAnswered: 2,
      );

  /// A synchronously fully-seeded [UserSettingsRepository] — the only
  /// fixture wired into the app today, and only from the demo entrypoint
  /// (see `lib/main_demo.dart`'s own doc comment, and
  /// `AppBootstrapService.userSettingsRepository`, the injection point it
  /// uses). [ProgressRepository]/[ContentRepository]
  /// below have no existing production injection point yet (progress,
  /// readiness, and practice/mock content wiring are explicitly deferred
  /// to later phases per `BootstrapLocalStore`'s own doc comment) — they
  /// exist as ready-to-use fixtures for when that wiring is added, and
  /// are exercised today only by
  /// `test/debug/debug_demo_environment_test.dart`.
  static UserSettingsRepository buildUserSettingsRepository() {
    return InMemoryUserSettingsRepository(seedProfile: demoProfile);
  }

  static ProgressRepository buildProgressRepository() {
    return InMemoryProgressRepository(
      seedAnswerAttempts: demoAnswerAttempts,
      seedQuestionStates: demoQuestionStates,
      seedPracticeSessions: [demoPracticeSession],
      seedMockAttempts: [demoMockAttempt],
      seedReadinessSnapshots: [demoReadinessSnapshot],
    );
  }

  static ContentRepository buildContentRepository() {
    return InMemoryContentRepository({demoExamId: demoContentPackage});
  }
}
