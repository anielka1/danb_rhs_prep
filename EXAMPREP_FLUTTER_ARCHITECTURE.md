# ExamPrep Flutter Architecture Specification

## Purpose

This document defines the technical architecture for evolving `danb_rhs_prep` from its current Flutter UI prototype into a production-ready, local-first exam-preparation application that can later support many professional exams.

Read together with:

`EXAMPREP_PRODUCT_AND_SCREEN_SPEC.md`

The product spec defines **what the app does**. This file defines **how it should be implemented in Flutter/Dart**.

---

# 1. Current repository assessment

The repository is currently intentionally small:

- Flutter / Dart
- Material 3
- `MaterialApp` named routes
- custom theme in `lib/theme/app_theme.dart`
- screen widgets under `lib/screens/`
- reusable widgets under `lib/widgets/`
- no production persistence package yet
- no state-management dependency yet
- no purchase/subscription dependency yet
- many screen values are currently hardcoded prototype data

Current `pubspec.yaml` only adds Flutter and `cupertino_icons` at runtime.

This is a good point to introduce architecture incrementally. Do **not** rewrite the entire project or add a large framework stack at once.

---

# 2. Architecture goals

The architecture must be:

- local-first
- offline-capable
- testable
- understandable by a small team
- data-driven
- reusable for many exams
- independent of a backend in V1
- careful about third-party dependencies

Dependency direction:

```text
Flutter UI
   |
   v
Feature Controllers / Session State
   |
   v
Domain Engines / Services
   |
   +-- Question Engine
   +-- Progress Engine
   +-- Readiness Engine
   +-- Adaptive Selector
   +-- Mock Exam Generator
   +-- Subscription Service
   |
   v
Repositories
   |
   +-- Content Repository
   +-- Progress Repository
   +-- Settings Repository
   +-- Subscription Platform Adapter
   |
   v
Local Persistence / JSON / Platform Stores
```

Domain engines must not import Flutter widgets.

---

# 3. Recommended project structure

Evolve toward this structure gradually:

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── app_state.dart
│   └── app_router.dart
├── config/
│   ├── exam_config.dart
│   └── feature_access.dart
├── content/
│   ├── content_repository.dart
│   ├── content_validator.dart
│   └── question_bank_loader.dart
├── domain/
│   ├── models/
│   │   ├── exam.dart
│   │   ├── question.dart
│   │   ├── answer_attempt.dart
│   │   ├── question_state.dart
│   │   ├── mock_attempt.dart
│   │   └── readiness.dart
│   ├── question_engine.dart
│   ├── progress_engine.dart
│   ├── readiness_engine.dart
│   ├── adaptive_question_selector.dart
│   ├── mock_exam_generator.dart
│   └── recommendation_engine.dart
├── data/
│   ├── local/
│   ├── repositories/
│   └── migrations/
├── features/
│   ├── onboarding/
│   ├── home/
│   ├── practice/
│   ├── mock_exam/
│   ├── progress/
│   ├── paywall/
│   └── settings/
├── services/
│   ├── subscription_service.dart
│   ├── analytics_service.dart
│   └── notification_service.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    └── shared reusable widgets

assets/
└── content/
    └── danb_rhs/
        ├── exam_config.json
        └── question_bank.json

test/
├── readiness_engine_test.dart
├── adaptive_selector_test.dart
├── mock_exam_generator_test.dart
├── content_validator_test.dart
└── persistence_test.dart
```

Do not move every existing file immediately. Refactor feature-by-feature as functionality is implemented.

---

# 4. State management

## Recommendation

Do not add Riverpod, Bloc, Redux, or another state package solely for architecture fashion.

The current project has no state-management dependency. Start with Flutter-native primitives:

- immutable Dart models
- `ChangeNotifier` for app-wide/service-backed state where appropriate
- `ValueNotifier` for small isolated values
- `StatefulWidget` for truly local ephemeral UI state
- dependency objects passed through constructors or a small app scope

If the application later becomes difficult to manage with these tools, introduce one state package deliberately and migrate incrementally.

## State ownership

### App-wide state

Examples:
- selected exam
- content load state
- current profile
- subscription entitlement

### Feature/session state

Examples:
- current practice question index
- selected answer
- current mock answers
- flags
- remaining mock time

Feature state should die when the feature/session ends unless explicitly persisted.

### Persistent state

Examples:
- user profile
- answer attempts
- bookmarks
- mastery counters
- mock attempts
- readiness snapshots

Persistent state belongs in repositories/local storage, not widget fields.

---

# 5. Navigation

The current app uses `MaterialApp.routes`. That is sufficient during early implementation.

Do not add a routing package unless nested/deep-link navigation becomes painful.

Required primary shell:

```text
MainShell
├── Home
├── Practice
├── Mock Exam
└── Progress
```

Prefer an `IndexedStack` or equivalent shell behavior so switching tabs does not repeatedly push duplicate root screens onto the Navigator stack.

The current bottom-nav implementation pushes named routes. Refactor it so tab switching represents true tab state rather than a growing route history.

Secondary screens can continue using Navigator pushes.

---

# 6. ExamConfig

This is the most important multi-exam abstraction.

Suggested Dart model:

```dart
class ExamConfig {
  final String examId;
  final String examName;
  final String examProvider;
  final String examVersion;
  final String contentVersion;
  final int questionCount;
  final int durationMinutes;
  final PassingScoreConfig passingScore;
  final List<ExamDomain> domains;
  final Map<String, double> domainWeights;
  final PricingProductIds pricingProductIds;
  final FreeTierConfig freeTier;
  final MockExamConfig mockExam;
  final ReadinessConfig readiness;
  final String disclaimer;
}
```

No generic UI should contain logic like:

```dart
if (examId == 'danb-rhs') { ... }
```

Instead, UI and engines read configuration.

---

# 7. Question data model

```dart
class Question {
  final String id;
  final String examId;
  final String domainId;
  final String topicId;
  final String questionText;
  final List<AnswerOption> answers;
  final String correctAnswerId;
  final String explanation;
  final List<QuestionReference> references;
  final int difficulty; // 1-5
  final QuestionStatus status;
  final int version;
  final DateTime updatedAt;
  final String sourceVersion;
  final List<String> tags;
}
```

Supporting models:

```dart
class AnswerOption {
  final String id;
  final String text;
}

class QuestionReference {
  final String title;
  final String source;
  final String? section;
  final Uri? url;
}

enum QuestionStatus {
  draft,
  reviewed,
  approved,
  retired,
}
```

Only `approved` questions are eligible for production sessions.

---

# 8. Content storage

## V1

Ship versioned JSON files in Flutter assets.

Example:

```text
assets/content/danb_rhs/exam_config.json
assets/content/danb_rhs/question_bank.json
```

Declare the asset directory in `pubspec.yaml`.

The app loads and validates the content at startup.

## Future updates

When remote updates provide clear value:

1. download a version manifest
2. download candidate content package
3. validate package locally
4. write to temporary local storage
5. atomically activate it only after successful validation
6. keep previous valid package for rollback

A full backend is not required for this.

---

# 9. Content validation

Validation must reject or report:

- duplicate question IDs
- missing question text
- fewer than two answers
- duplicate answer IDs within a question
- missing correct answer
- correctAnswerId not found among answers
- missing explanation
- difficulty outside 1-5
- unknown domain
- unknown topic
- malformed references
- incompatible exam ID/version
- invalid domain weights

Warnings may include:

- no reference
- non-HTTPS reference URL
- unusually short explanation

Validation should be unit tested independently from Flutter UI.

---

# 10. Local persistence

The app needs structured local persistence for progress. Do not store growing attempt history as one giant JSON preference value.

## Recommended approach

Use SQLite through a lightweight Dart/Flutter persistence layer. A typed SQLite package such as Drift is a reasonable choice when implementation begins because the data is relational, versioned, query-heavy, and needs migrations.

Do not add it until the persistence phase is actually implemented.

## Tables / entities

### user_profile

- exam_id
- onboarding_completed
- exam_date nullable
- exam_date_precision
- experience_level
- daily_goal
- created_at
- updated_at

### answer_attempt

- id UUID
- exam_id
- question_id
- domain_id
- topic_id
- difficulty
- selected_answer_id
- is_correct
- answered_at
- mode: diagnostic / practice / mockExam
- session_id

### question_state

Composite identity: exam_id + question_id

- is_bookmarked
- times_seen
- times_correct
- consecutive_correct
- last_seen_at
- last_was_correct

### mock_attempt

- id
- exam_id
- started_at
- completed_at
- percent_correct
- question_ids JSON/text payload or normalized child table
- flagged_question_ids
- domain_result_snapshot

### readiness_snapshot

- id
- exam_id
- created_at
- score
- label
- evidence_confidence
- recent_accuracy_component
- domain_mastery_component
- mock_component
- repeated_mastery_component
- coverage_component
- weakest_domain_id nullable
- weakest_topic_id nullable

Historical attempts must remain valid even when a question is later retired.

---

# 11. Repository interfaces

UI should not query SQLite directly.

Suggested interfaces:

```dart
abstract interface class ProgressRepository {
  Future<void> recordAttempt(AnswerAttempt attempt);
  Future<List<AnswerAttempt>> attemptsForExam(String examId);
  Future<QuestionState?> questionState(String examId, String questionId);
  Future<void> saveQuestionState(QuestionState state);
  Future<void> saveReadinessSnapshot(ReadinessSnapshot snapshot);
}
```

```dart
abstract interface class ContentRepository {
  Future<ExamConfig> loadExamConfig(String examId);
  Future<List<Question>> approvedQuestions(String examId);
  Future<Question?> questionById(String examId, String questionId);
}
```

Repositories make engines testable without a real database.

---

# 12. Question Engine

Responsibilities:

- obtain approved questions
- filter by domain/topic
- filter unseen/bookmarked/incorrect
- filter difficulty when requested
- create sessions without duplicates
- enforce available question count

The Question Engine should not calculate Readiness Score.

---

# 13. Practice session state

Suggested model/controller:

```dart
class PracticeSessionController extends ChangeNotifier {
  final List<Question> questions;
  int currentIndex;
  String? selectedAnswerId;
  bool answerSubmitted;
  DateTime startedAt;
  // session result counters
}
```

On submit:

```text
selected answer
   -> evaluate correctness
   -> persist AnswerAttempt
   -> update QuestionState
   -> expose feedback to UI
   -> next question
```

After session completion:

```text
aggregate session
   -> ProgressEngine
   -> ReadinessEngine
   -> optional readiness snapshot
   -> Practice Result
```

---

# 14. Progress Engine

Responsibilities:

- total questions answered
- unique questions answered
- recent accuracy
- domain accuracy
- topic accuracy
- streak
- daily/weekly goal progress
- mastery
- mock history summaries

Do not calculate these values independently inside multiple screens.

---

# 15. Readiness Score

The algorithm must be deterministic and transparent.

All component weights are configurable per exam.

Recommended default raw score:

```text
30% recent practice accuracy
25% domain mastery
25% mock performance
10% repeated mastery
10% coverage
```

## Recent practice accuracy

Weight attempts by:

- recency
- difficulty

Recency uses exponential decay.

Default half-life: 21 days.

Conceptually:

```text
recencyWeight = 0.5 ^ (ageInDays / halfLifeDays)
```

Difficulty evidence multiplier can map 1-5 to approximately 0.8-1.2.

## Domain mastery

Calculate recency-weighted/smoothed accuracy per domain and combine according to configured domain weights.

Apply a weak-domain penalty so one dangerous knowledge gap cannot be hidden by strong performance elsewhere.

## Mock performance

Use recent mock scores with stronger weight on newer attempts.

No mock history should begin neutral, not as an automatic failure.

## Repeated mastery

Reward questions demonstrated correct repeatedly rather than once.

A simple V1 mastery rule can require at least two correct demonstrations with no recent contradictory evidence.

## Coverage

Coverage combines:

- unique questions attempted
- breadth across configured domains

## Evidence confidence

Avoid presenting a highly precise score from tiny samples.

```text
confidence = min(1, sqrt(uniqueQuestionsAnswered / minimumEvidenceQuestions))
```

Then:

```text
finalScore = priorScore + confidence * (rawComposite - priorScore)
```

Recommended defaults:

- prior score: 40
- minimum evidence questions: 40

## Labels

Configurable defaults:

- 0-39 Starting
- 40-59 Developing
- 60-74 Getting Close
- 75-84 Exam Ready
- 85-100 Strongly Prepared

Always surface the disclaimer that readiness does not guarantee official exam success.

---

# 16. Adaptive question selection

Keep V1 understandable.

Recommended priority components:

```text
34% weak domain/topic
22% previously incorrect need
18% unseen / not recently seen
16% difficulty fit
10% spaced reinforcement
```

## Weakness

Higher priority when recent topic/domain performance is lower.

## Incorrect need

Previously missed questions receive a boost until mastery is demonstrated.

## Novelty

Questions never seen or not seen recently receive a boost.

## Difficulty fit

Prefer questions around the learner's estimated ability rather than constantly serving only the hardest questions.

## Reinforcement

Mastered questions decrease in frequency but return after enough time.

## Important rule

Adaptive selection is for study sessions. It must **not** distort blueprint weighting in Mock Exams.

---

# 17. Recommendation Engine

Home should ask this engine for a recommended action.

Inputs:

- exam date
- questions answered today
- daily goal
- weak topics
- recent mistakes
- unseen pool
- subscription access

Output example:

```dart
class StudyRecommendation {
  final PracticeMode mode;
  final int questionCount;
  final String title;
  final String reason;
  final String? domainId;
  final String? topicId;
}
```

Example:

`Practice 10 Radiation Safety questions — this is currently your weakest area.`

---

# 18. Mock Exam Generator

Inputs:

- ExamConfig
- approved question bank
- user history

Responsibilities:

- select configured number of questions
- respect official/configured domain weights
- avoid duplicate IDs
- avoid recently seen questions when enough alternatives exist
- fail clearly when the bank cannot satisfy the blueprint

Do not silently change blueprint weights just to generate an exam.

## Rounding domain counts

Use a deterministic largest-remainder or equivalent allocation so configured weights sum to the exact exam question count.

---

# 19. Mock session state

Suggested controller owns:

- immutable generated question IDs
- current index
- selected answer per question ID
- flagged IDs
- startedAt
- remaining time
- completion state

Persist enough in-progress state to recover from normal app backgrounding/termination where practical.

Mock question UI never receives correctness until the attempt is finished.

---

# 20. Subscription architecture

Flutter must not scatter purchase logic across widgets.

Define a platform-neutral interface:

```dart
abstract interface class SubscriptionService {
  Future<List<SubscriptionProduct>> loadProducts();
  Future<PurchaseResult> purchase(String productId);
  Future<void> restorePurchases();
  Future<Entitlement> currentEntitlement();
  Stream<Entitlement> entitlementChanges();
}
```

On iOS, the implementation must use Apple's in-app purchase infrastructure through an appropriate Flutter bridge/plugin. Android can use the same service interface with Google Play billing.

Product IDs come from `ExamConfig`, never from paywall widgets.

UI displays localized store-provided price and billing period.

## Entitlement model

V1 only needs:

```text
free
premium
```

Do not make weekly/monthly/3-month products separate feature tiers. They grant the same premium entitlement with different billing durations.

---

# 21. Feature access / paywall gate

Centralize gating:

```dart
enum PremiumFeature {
  unlimitedPractice,
  mockExam,
  weakAreas,
  incorrectPractice,
  advancedProgress,
  readinessHistory,
}
```

A `FeatureAccessService` decides whether the current entitlement/free-tier allowance permits the action.

Flow:

```text
User requests feature
   -> FeatureAccessService
      -> allowed -> continue
      -> blocked -> present Paywall
         -> purchase success -> return to requested feature
```

Screens must not implement store transaction logic.

---

# 22. Free-tier limits

Store limits in `ExamConfig`, for example:

```dart
class FreeTierConfig {
  final int dailyPracticeQuestions;
  final int diagnosticQuestions;
  final int includedMockExams;
}
```

Daily usage is calculated from persisted attempts, not an easily reset widget counter.

---

# 23. Analytics

V1 should not add an invasive third-party analytics SDK.

Define a no-op/debug interface:

```dart
abstract interface class AnalyticsService {
  void track(String event, {Map<String, Object?> properties = const {}});
}
```

Event vocabulary:

- onboarding_started
- onboarding_completed
- diagnostic_completed
- practice_started
- practice_completed
- mock_exam_started
- mock_exam_completed
- paywall_viewed
- trial_started
- subscription_started
- question_reported

Never include answer text, email, or unnecessary personal information in analytics.

---

# 24. Account strategy

The current prototype contains a Login/Sign Up screen with placeholder credentials.

For V1, remove mandatory authentication from the core flow.

Reasons:

- local-first progress does not require an account
- subscriptions are platform entitlements
- account creation adds friction and privacy/compliance work
- no backend currently provides enough benefit to justify it

The existing login screen can be removed from the launch flow or retained outside production navigation until a real account use case exists.

---

# 25. Theme and design system

The current `AppTheme` already centralizes colors, radii, spacing, and text styles. Preserve this idea.

Required improvements:

- add explicit light and dark themes
- avoid relying on a hardcoded `SF Pro Display` family unless that font is actually bundled/available as intended; prefer platform/system typography unless a licensed bundled font is deliberately added
- use semantic theme colors rather than direct `Colors.white` throughout feature widgets
- add spacing scale rather than only one screen padding value
- make components resilient to text scaling

Reusable components should include:

- PrimaryButton
- SecondaryButton
- AppCard
- ReadinessRing / ReadinessCard
- AnswerOptionTile
- ProgressBar
- EmptyState
- ErrorState
- DomainProgressRow
- SubscriptionProductCard

---

# 26. Accessibility

Every interactive component should:

- expose semantic labels
- have adequate tap targets
- not rely on color alone for correct/incorrect state
- support large text without clipping
- preserve logical focus order
- respect platform reduce-motion preferences where animations exist

Question answers should expose both option letter and answer text to screen readers.

---

# 27. Offline rules

Never block these on network availability:

- reading bundled/downloaded questions
- Practice
- bookmarks
- incorrect history
- Weak Areas
- Mock Exam
- Progress
- Readiness calculation

Network-dependent operations must fail gracefully:

- subscription purchase/restore
- content updates
- remote report submission
- optional analytics

---

# 28. Content versioning

Every content package carries:

- examVersion
- contentVersion
- sourceVersion
- generatedAt

Every question carries:

- version
- updatedAt
- sourceVersion
- status

Retirement rule:

```text
approved -> retired
```

Retired questions:

- disappear from new sessions
- remain addressable by ID for historical statistics when possible
- are never physically required to be deleted from history

---

# 29. Question report architecture

A report object should contain:

```dart
class QuestionReport {
  final String id;
  final String examId;
  final String questionId;
  final int questionVersion;
  final String contentVersion;
  final QuestionReportType type;
  final String? note;
  final DateTime createdAt;
}
```

Without a backend, save pending reports locally. A future support transport can submit them without changing the question UI contract.

---

# 30. Testing strategy

Use `flutter_test` and pure Dart tests wherever possible.

Required automated tests:

## Content
- valid bank accepted
- duplicate ID rejected
- missing answer rejected
- invalid correct answer rejected
- invalid domain/topic rejected
- missing explanation rejected

## Readiness
- deterministic result
- recent attempts matter more than old attempts
- difficulty weighting works
- weak-domain penalty works
- evidence confidence prevents extreme low-sample score
- threshold labels map correctly

## Adaptive selection
- weak topics get higher priority
- incorrect questions get boosted
- stale/unseen questions get boosted
- mastered questions are reduced but not permanently removed

## Mock generation
- exact configured question count
- no duplicates
- domain weighting allocation
- approved-only questions
- clear failure when pool is insufficient

## Subscription
- free entitlement
- premium entitlement
- expired/non-active transaction does not unlock premium
- successful entitlement unlocks premium features

## Persistence
- attempt survives repository reload
- bookmark survives reload
- mock attempt survives reload
- retired content does not erase historical attempts

## Widget tests
Prioritize:
- onboarding navigation
- answer submission/feedback
- free-tier paywall gate
- mock finish confirmation
- empty states

---

# 31. Implementation milestones

## Phase 1 — foundation

- keep current UI working
- add ExamConfig models
- add Question models
- add bundled JSON content loader
- add validator
- tests for content

## Phase 2 — onboarding

- replace login-first launch
- Welcome
- Exam Date
- Experience Level
- Diagnostic Intro
- persist onboarding state

## Phase 3 — real Practice

- QuestionEngine
- PracticeSessionController
- real question data
- answer recording
- inline explanation
- bookmarks/report actions
- Practice Result

## Phase 4 — persistence + progress

- add local database
- repositories
- replace hardcoded Progress values
- streak/daily goal
- domain/topic summaries

## Phase 5 — readiness + adaptive learning

- ReadinessEngine
- snapshots
- Home redesign around readiness/recommendation
- AdaptiveQuestionSelector
- Weak Areas
- Incorrect/Unseen modes

## Phase 6 — Mock Exam

- MockExamGenerator
- session timer
- flags
- navigator
- finish confirmation
- persisted results
- mock history

## Phase 7 — subscriptions

- store integration
- product loading
- entitlement service
- feature gates
- paywall
- restore/manage subscription

## Phase 8 — content workflow

- CSV-to-canonical-JSON tool
- content version installation
- atomic update/rollback
- report queue

## Phase 9 — quality

- dark mode
- accessibility
- iPhone/Android device matrix
- offline QA
- performance
- full test suite
- legal/App Store/Play compliance review

---

# 32. Rules for Claude Code / coding agents

Before modifying code:

1. Read this document.
2. Read `EXAMPREP_PRODUCT_AND_SCREEN_SPEC.md`.
3. Inspect existing relevant files.
4. Preserve working UI unless the current phase explicitly replaces it.
5. Implement one coherent feature at a time.
6. Run `flutter analyze`.
7. Run relevant `flutter test` tests.
8. Fix errors introduced by the change.
9. Do not introduce a backend unless explicitly requested.
10. Do not introduce a new dependency without explaining why the standard library/current dependencies are insufficient.
11. Do not hardcode exam-specific rules into generic widgets.
12. Do not replace real store pricing with constants.
13. Do not generate random readiness values.
14. Do not claim official exam success.

---

# 33. Target data flow after an answer

```text
PracticeQuestionScreen
   |
   v
PracticeSessionController.submitAnswer()
   |
   +--> QuestionEngine evaluates correctness
   |
   +--> ProgressRepository records AnswerAttempt
   |
   +--> ProgressRepository updates QuestionState
   |
   v
UI shows inline feedback
   |
   v
Session completion
   |
   +--> ProgressEngine aggregates
   |
   +--> ReadinessEngine recalculates
   |
   +--> readiness snapshot persisted when appropriate
   |
   v
Practice Result -> Home / Progress reflect new data
```

---

# 34. Target data flow after a mock exam

```text
MockExamGenerator
   -> MockSessionController
   -> local in-progress state
   -> finish
   -> calculate score/domain results
   -> persist AnswerAttempts
   -> persist MockAttempt
   -> ProgressEngine
   -> ReadinessEngine
   -> persist ReadinessSnapshot
   -> Mock Exam Result
```

---

# 35. Final architecture principle

The app should have a simple UI sitting on top of deterministic domain logic.

```text
CONFIG + CONTENT
       |
       v
QUESTION / MOCK / PROGRESS ENGINES
       |
       v
READINESS + RECOMMENDATIONS
       |
       v
SIMPLE FLUTTER SCREENS
```

Adding a second exam should primarily mean adding a new `ExamConfig`, a new validated question bank, and exam-specific assets/content — not rebuilding navigation, Practice, Progress, Mock Exam, subscriptions, or Readiness from scratch.
