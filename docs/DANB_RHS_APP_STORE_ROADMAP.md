# DANB RHS Exam Prep — App Store Readiness Roadmap

**Project:** `anielka1/danb_rhs_prep`  
**Primary platform:** iPhone  
**Secondary platforms:** iPad, then Android  
**Architecture:** Flutter, local-first, configuration-driven  
**Business model:** Free tier plus auto-renewable premium subscriptions  
**Core promise:** **Know when you're ready to pass.**

---

## 1. Product decisions to keep fixed

- [ ] Keep the app usable without creating an account.
- [ ] Treat the existing Flutter prototype as a design reference only.
- [ ] Preserve its calm cream, periwinkle, navy, rounded-card visual direction.
- [ ] Replace all prototype screen content with configuration or real user data.
- [ ] Keep exactly four primary tabs:
  1. Home
  2. Practice
  3. Mock Exam
  4. Progress
- [ ] Put Settings behind a toolbar/profile icon instead of a fifth tab.
- [ ] Keep all core study features usable offline.
- [ ] Never claim that a user passed the official DANB exam.
- [ ] Use wording such as “Practice result,” “Estimated readiness,” and “Mock exam result.”
- [ ] Clearly disclose that the app is not affiliated with or endorsed by DANB.
- [ ] Do not copy official exam questions or copyrighted competitor content.
- [ ] Require professional content review before a question receives `approved` status.
- [ ] Do not add advertising or invasive tracking in V1.

---

## 2. Important sequencing decisions

### Configure early, before feature development finishes

- Apple Developer Program membership.
- Production bundle identifier.
- App Store Connect app record.
- Paid Applications Agreement, banking, and tax information.
- Subscription group and permanent product identifiers.
- Support website, privacy-policy URL, and terms URL.
- Legal review of the app name, DANB references, disclaimers, and question sources.

These administrative tasks can take time and should not block the final release.

### Implement payments after premium features are real

Implement `in_app_purchase` only after Practice, Mock Exam, Progress, and feature
gating work correctly with fake entitlements. The paywall must sell working
features, not placeholders.

### Implement Supabase after the local data model is stable

Do not begin with Supabase. First make onboarding, Practice, Progress,
Readiness, and Mock Exams work offline with local persistence. Add Supabase when
there is a concrete need for cross-device sync, remote question reports,
receipt verification, or controlled content distribution.

### Implement Apple/Google login only with account-based features

Login should be optional and introduced as **Sync Progress**, not as a launch
gate. If Google login is offered for a primary account on iOS, provide the
required equivalent privacy-preserving login option at the same time; Sign in
with Apple is the expected choice.

### Recommended release strategy

1. Build the complete local-first app.
2. Add subscription products and on-device StoreKit entitlement handling.
3. Decide whether V1 truly needs cloud sync.
4. If not, launch without accounts and add sync later.
5. If yes, add Supabase, Sign in with Apple, optional Google login, account
   deletion, RLS, sync, and server-side entitlement verification before release.

---

## 3. Target user journey

```text
App Launch
  -> Welcome
  -> Exam Date
  -> Experience Level
  -> Diagnostic Introduction
  -> Diagnostic Quiz
  -> Diagnostic Result
  -> Main App
       -> Home
       -> Practice
       -> Mock Exam
       -> Progress
       -> Settings
            -> Optional Sync Progress / Account
            -> Subscription
            -> Content and Legal Information
```

Returning users should go directly from app bootstrap to the main app.

---

# PHASE 0 — Business, legal, and Apple setup

## 0.1 Apple accounts and identifiers

- [ ] Enroll the legal owner in the Apple Developer Program.
- [ ] Choose a permanent production bundle ID, for example:
  `com.yourcompany.danbrhsprep`.
- [ ] Replace the current example Android/iOS application identifiers.
- [ ] Register the bundle ID in Certificates, Identifiers & Profiles.
- [ ] Create the app record in App Store Connect.
- [ ] Use the exact same bundle ID in Flutter, Xcode, and App Store Connect.
- [ ] Decide the public app name and subtitle.
- [ ] Reserve the app name in App Store Connect.
- [ ] Set the primary category to Education.
- [ ] Accept the Paid Applications Agreement.
- [ ] Complete banking and tax forms.

## 0.2 Legal and content safety

- [ ] Have a qualified professional review all approved questions,
  explanations, and references.
- [ ] Document who reviewed each content release and when.
- [ ] Confirm that the app name and marketing do not imply DANB endorsement.
- [ ] Add a visible disclaimer in onboarding, Settings, mock results, and the
  App Store description.
- [ ] Create public Privacy Policy, Terms of Use, and Support pages.
- [ ] Add a content-correction and question-report process.
- [ ] Define how quickly reported content issues must be reviewed.
- [ ] Avoid giving individualized medical, legal, or employment advice.

## 0.3 Subscription identifiers — reserve now, implement later

- [ ] Create one subscription group, such as `DANB RHS Premium`.
- [ ] Create three auto-renewable subscriptions in that group:
  - `danb_rhs_premium_weekly`
  - `danb_rhs_premium_monthly`
  - `danb_rhs_premium_3_months`
- [ ] Make all three products unlock the same premium entitlement.
- [ ] Do not make billing periods separate feature tiers.
- [ ] Add localized subscription names and descriptions.
- [ ] Select initial App Store price points.
- [ ] Do not create fake “discount” messaging from arithmetic comparisons.
- [ ] Record the product IDs in `ExamConfig`; never place prices in config.
- [ ] Leave final subscription submission until the paywall is functional.

### Phase 0 exit criteria

- [ ] Bundle ID and app record exist.
- [ ] Agreements, banking, and tax setup are complete.
- [ ] Subscription IDs are reserved.
- [ ] Public privacy, terms, and support URLs exist.
- [ ] Content ownership and review process are documented.

---

# PHASE 1 — Architecture and content foundation

## 1.1 Existing completed foundation

- [x] Add configurable exam/domain/topic models.
- [x] Add mock-exam, official-scoring, readiness, free-tier, and subscription
  product configuration.
- [x] Add question, answer, reference, status, and versioning models.
- [x] Add bundled JSON content loading.
- [x] Restrict production sessions to `approved` questions.
- [x] Validate duplicate IDs, answers, correct answers, explanations,
  references, domains, topics, weights, and versions.
- [x] Add initial validation tests.
- [x] Configure the current 75-question, 60-minute, 50/25/25 RHS blueprint.

## 1.2 Complete the application boundaries

- [ ] Create repository interfaces for:
  - content
  - progress
  - user settings
  - subscriptions
  - optional sync
- [ ] Keep engines free of Flutter widget and plugin imports.
- [ ] Add immutable models for:
  - `UserProfile`
  - `AnswerAttempt`
  - `QuestionState`
  - `PracticeSession`
  - `MockAttempt`
  - `ReadinessSnapshot`
  - `QuestionReport`
  - `Entitlement`
- [ ] Introduce a simple state-management layer when shared state begins.
- [ ] Prefer Riverpod only if it clearly reduces controller/lifecycle code.
- [ ] Keep Navigator initially; add `go_router` only if deep-link and auth
  routing becomes meaningfully difficult.

### Phase 1 exit criteria

- [ ] Business logic can be unit tested without a device.
- [ ] UI cannot directly query JSON, SQLite, StoreKit, or Supabase.
- [ ] Adding another exam requires config, content, and assets—not new engines.

---

# PHASE 2 — Design system and production app shell

## 2.1 Theme cleanup

- [ ] Preserve the prototype palette as semantic colors:
  - background
  - surface/card
  - primary action
  - primary text
  - secondary text
  - success
  - error
  - warning
  - divider
- [ ] Add complete light and dark themes.
- [ ] Remove hardcoded use of `Colors.white` where semantic surface colors are
  needed.
- [ ] Replace deprecated `withOpacity` calls with supported color APIs.
- [ ] Remove the unbundled hardcoded `SF Pro Display` family or deliberately
  bundle a licensed font.
- [ ] Create spacing tokens: 4, 8, 12, 16, 20, 24, 32, 40.
- [ ] Create consistent radius, elevation, icon, and tap-target tokens.
- [ ] Ensure all interactive controls have at least a 44×44 logical-point
  target on iOS.

## 2.2 Reusable components

- [ ] `AppScaffold`
- [ ] `PrimaryButton`
- [ ] `SecondaryButton`
- [ ] `AppCard`
- [ ] `AppBottomNavigation`
- [ ] `ReadinessRing`
- [ ] `ReadinessCard`
- [ ] `AnswerOptionTile`
- [ ] `DomainProgressRow`
- [ ] `ProgressBar`
- [ ] `EmptyState`
- [ ] `ErrorState`
- [ ] `LoadingState`
- [ ] `SubscriptionProductCard`
- [ ] Adaptive alert/dialog wrapper using Cupertino behavior where beneficial.

## 2.3 Navigation shell

- [ ] Replace `Home / Practice / Stats / Profile` with:
  `Home / Practice / Mock Exam / Progress`.
- [ ] Remove Login from first-launch routing.
- [ ] Move Settings to a toolbar icon.
- [ ] Preserve selected tab state.
- [ ] Use state restoration where practical.
- [ ] Add route-level analytics hooks without adding an analytics SDK yet.

## 2.4 Accessibility

- [ ] Test Dynamic Type at the largest accessibility sizes.
- [ ] Add semantic labels to score rings, charts, answer choices, bookmarks,
  flags, and navigation items.
- [ ] Do not communicate correct/incorrect state using color alone.
- [ ] Verify VoiceOver reading and focus order.
- [ ] Respect Reduce Motion.
- [ ] Ensure contrast meets accessibility expectations in both themes.

### Phase 2 exit criteria

- [ ] Four-tab app shell works on small iPhone, large iPhone, and iPad.
- [ ] Light/dark mode and large text do not break layouts.
- [ ] No final screen depends on prototype-only content.

---

# PHASE 3 — App bootstrap and onboarding

## 3.1 App bootstrap

- [ ] Replace the fixed two-second splash delay with real initialization.
- [ ] Load and validate the selected exam content package.
- [ ] Load local profile, settings, progress, and entitlement cache.
- [ ] Check whether onboarding is complete.
- [ ] Route to onboarding or the main app.
- [ ] Show a recoverable content-error screen if bundled content is invalid.
- [ ] Never require network access to start studying.

## 3.2 Welcome screen

- [ ] Display `DANB RHS Exam Prep` from `ExamConfig`.
- [ ] Add headline: `Know when you're ready to pass.`
- [ ] Add short, calm supporting copy.
- [ ] Add one primary CTA: `Start Preparing`.
- [ ] Start `onboarding_started` analytics event through the internal interface.

## 3.3 Exam-date screen

- [ ] Ask `When is your exam?`
- [ ] Support exact date.
- [ ] Support approximate date.
- [ ] Support `I haven't scheduled it yet`.
- [ ] Validate that a selected date is not in the past.
- [ ] Store date and precision locally.

## 3.4 Experience-level screen

- [ ] Offer:
  - Just starting
  - Studying already
  - Taking the exam again
- [ ] Store selection locally.

## 3.5 Diagnostic

- [ ] Add diagnostic introduction with question count and approximate time.
- [ ] Generate a blueprint-balanced 10–20 question diagnostic.
- [ ] Use approved questions only.
- [ ] Cover every configured domain.
- [ ] Do not show explanations until the diagnostic is complete.
- [ ] Persist in-progress answers.
- [ ] Calculate initial readiness from actual performance.

## 3.6 Diagnostic result

- [ ] Show readiness score and label.
- [ ] Show evidence confidence because the sample is small.
- [ ] Show domain breakdown.
- [ ] Show strongest and weakest area.
- [ ] Add the readiness disclaimer.
- [ ] CTA: `Start My Study Plan`.
- [ ] Mark onboarding complete only after the result is saved.

### Phase 3 exit criteria

- [ ] A new user reaches Home without creating an account.
- [ ] Onboarding survives app restart.
- [ ] Returning users skip onboarding.
- [ ] Diagnostic results contain no random or hardcoded values.

---

# PHASE 4 — Professional question-content pipeline

## 4.1 Canonical content format

- [ ] Finalize JSON schema for exam package and questions.
- [ ] Publish a JSON Schema file for editor validation.
- [ ] Create a CSV template for content editors.
- [ ] Create a CSV-to-canonical-JSON conversion tool.
- [ ] Include stable IDs, version, source version, review status, reviewer,
  review date, and timestamps.
- [ ] Support optional distractor explanations.
- [ ] Support multiple references.

## 4.2 Validation

- [ ] Reject duplicate question and answer IDs.
- [ ] Reject missing question text or explanation.
- [ ] Reject missing/unknown correct answers.
- [ ] Reject invalid domain/topic mappings.
- [ ] Reject difficulty outside 1–5.
- [ ] Reject malformed references and incompatible exam versions.
- [ ] Warn on missing references and unusually short explanations.
- [ ] Produce a human-readable validation report for content editors.

## 4.3 Editorial workflow

- [ ] Define transitions: `draft -> reviewed -> approved -> retired`.
- [ ] Require reviewer identity before approval.
- [ ] Require every factual question to have an acceptable source.
- [ ] Add a second-person approval step for sensitive or disputed questions.
- [ ] Keep retired questions addressable for historical statistics.
- [ ] Maintain release notes per content version.
- [ ] Do not ship development samples as approved content.

## 4.4 Initial production bank

- [ ] Define the minimum question count per domain and topic.
- [ ] Ensure the bank can generate a complete 75-question mock without
  violating blueprint weights.
- [ ] Add enough alternatives to reduce frequent repetition.
- [ ] Balance difficulties 1–5.
- [ ] Run professional accuracy, clarity, bias, and reference review.
- [ ] Run a final duplicate/similarity review.

### Phase 4 exit criteria

- [ ] No production question lives inside Dart UI code.
- [ ] Every production question is approved and traceable to a source/reviewer.
- [ ] The bank can satisfy all diagnostic, practice, and mock generators.

---

# PHASE 5 — Local persistence

## 5.1 Database setup

- [ ] Add Drift/SQLite only now, when persistence is being implemented.
- [ ] Add schema versioning and migrations from day one.
- [ ] Create tables for:
  - user profile
  - answer attempts
  - per-question state
  - practice sessions
  - mock attempts
  - readiness snapshots
  - pending question reports
  - installed content releases
  - cached entitlement
- [ ] Use UUIDs for append-only attempts and reports.
- [ ] Store all timestamps in UTC.
- [ ] Create indexes for exam, question, topic, session, and timestamp queries.

## 5.2 Repositories

- [ ] Implement `ContentRepository`.
- [ ] Implement `ProgressRepository`.
- [ ] Implement `UserSettingsRepository`.
- [ ] Add in-memory fakes for tests.
- [ ] Keep SQL out of widgets and engines.

## 5.3 Reliability

- [ ] Write migration tests.
- [ ] Test app restart and process termination.
- [ ] Test content retirement without deleting historical attempts.
- [ ] Test atomic content-package activation and rollback.
- [ ] Add corruption/error recovery that does not silently erase progress.

### Phase 5 exit criteria

- [ ] Progress, bookmarks, incorrect history, settings, and mock results survive
  restart.
- [ ] The complete core product works in airplane mode.

---

# PHASE 6 — Practice experience

## 6.1 Practice hub

- [ ] Quick Practice buttons: 5, 10, and 20 questions.
- [ ] Focus modes:
  - Weak Areas
  - Incorrect Questions
  - Bookmarked Questions
  - Unseen Questions
- [ ] Browse by domain and topic.
- [ ] Add Custom Quiz.
- [ ] Display appropriate empty states.
- [ ] Ask the feature-access service before opening premium-only modes.

## 6.2 Question engine

- [ ] Filter approved questions only.
- [ ] Filter by exam/domain/topic/status/difficulty.
- [ ] Avoid duplicate IDs within one session.
- [ ] Support unseen, incorrect, bookmarked, and weak-area inputs.
- [ ] Handle a smaller available pool without crashing.
- [ ] Return clear errors for impossible custom filters.

## 6.3 Practice question screen

- [ ] Progress indicator and `Question X of Y`.
- [ ] Clear question text with Dynamic Type support.
- [ ] Answer options with letter and text semantics.
- [ ] Bookmark action.
- [ ] Report Problem action.
- [ ] Submit Answer CTA disabled until an answer is selected.
- [ ] Prevent double submission.
- [ ] Record the attempt exactly once.

## 6.4 Inline answer feedback

- [ ] Display Correct or Incorrect using icon, text, and color.
- [ ] Identify the selected answer and correct answer.
- [ ] Display explanation and references.
- [ ] Display optional distractor explanations.
- [ ] Add `Next Question` as the primary action.
- [ ] Do not unnecessarily open a separate explanation route.

## 6.5 Practice result

- [ ] Correct/total and accuracy.
- [ ] Time spent.
- [ ] Domain breakdown.
- [ ] Strongest and weakest area.
- [ ] Readiness change only when meaningful.
- [ ] Actions for weak-area practice, another session, and Home.

### Phase 6 exit criteria

- [ ] Every answer updates real persisted progress.
- [ ] Practice works completely offline.
- [ ] Free daily limits are calculated from persisted attempts.

---

# PHASE 7 — Home, Progress, Readiness, and adaptive study

## 7.1 Final Home screen content

Remove the prototype calendar agenda. The final Home should contain, in this
order:

### Header

- [ ] Greeting or neutral `Today` title.
- [ ] Settings icon.
- [ ] Exam countdown, or `Exam date not scheduled` with `Set Exam Date` action.

### Readiness card

- [ ] Large readiness percentage ring.
- [ ] Readiness label: Starting / Developing / Getting Close / Exam Ready /
  Strongly Prepared.
- [ ] Evidence-confidence indicator or explanatory sentence.
- [ ] Link to Readiness Detail.
- [ ] Always show estimate disclaimer in detail view.

### Recommended study card

- [ ] One recommended action generated from real data.
- [ ] Example title: `Practice your weakest area`.
- [ ] Example reason: `Radiation Protection has 3 recent mistakes`.
- [ ] Estimated duration or question count.
- [ ] Primary CTA such as `Start 10-Minute Practice`.
- [ ] Continue an unfinished session when appropriate.

### Daily progress

- [ ] Questions completed today / daily goal.
- [ ] Streak.
- [ ] Total answered.
- [ ] Weakest topic.
- [ ] Compact progress visualization that remains accessible without color.

### Home states

- [ ] New user with diagnostic only.
- [ ] Low evidence.
- [ ] No exam date.
- [ ] Daily goal complete.
- [ ] No weak area yet.
- [ ] Premium recommendation that requires a paywall.
- [ ] Offline mode.

## 7.2 Progress engine

- [ ] Total and unique questions answered.
- [ ] Recent accuracy.
- [ ] Daily/weekly completion.
- [ ] Streak with a documented timezone rule.
- [ ] Domain and topic mastery.
- [ ] Incorrect and bookmarked counts.
- [ ] Mock-history aggregates.

## 7.3 Readiness algorithm

- [ ] Implement deterministic default weighting:
  - 30% recent practice accuracy
  - 25% domain mastery
  - 25% mock performance
  - 10% repeated mastery
  - 10% coverage
- [ ] Apply configurable exponential recency decay.
- [ ] Apply small difficulty evidence multipliers.
- [ ] Use configured domain blueprint weights.
- [ ] Apply a weak-domain penalty.
- [ ] Start mock performance neutrally when there are no mock attempts.
- [ ] Require repeated correct demonstrations for mastery.
- [ ] Blend with prior score based on evidence confidence.
- [ ] Clamp the final result to 0–100.
- [ ] Persist explainable component snapshots.

## 7.4 Adaptive selector

- [ ] Prioritize weak domain/topic evidence.
- [ ] Boost previously incorrect questions.
- [ ] Boost unseen and stale questions.
- [ ] Prefer difficulty near estimated ability.
- [ ] Reduce mastered-question frequency without permanently removing it.
- [ ] Keep adaptive selection out of blueprint-weighted Mock Exams.

## 7.5 Progress screens

- [ ] Progress overview.
- [ ] Readiness Detail with all components.
- [ ] Domain Detail.
- [ ] Topic Detail.
- [ ] Mock history and attempt detail.
- [ ] Accessible trend chart with textual summary.

### Phase 7 exit criteria

- [ ] No progress value is hardcoded or random.
- [ ] Readiness is deterministic and covered by unit tests.
- [ ] Home clearly answers: `What should I study today?`

---

# PHASE 8 — Mock Exam

## 8.1 Generator

- [ ] Generate exactly 75 questions from config.
- [ ] Allocate domain counts using deterministic largest-remainder rounding.
- [ ] Match the 50/25/25 blueprint.
- [ ] Avoid duplicates.
- [ ] Prefer questions not recently used when alternatives exist.
- [ ] Fail clearly when the bank cannot satisfy the blueprint.
- [ ] Never silently change configured weights.

## 8.2 Mock intro

- [ ] Show count, duration, timed status, navigation rule, and practice
  threshold.
- [ ] Explain that the official exam uses scaled computer-adaptive scoring and
  that the app mock is an estimate.
- [ ] Gate premium access here.

## 8.3 Mock session

- [ ] 60-minute timer from config.
- [ ] Persist start time instead of relying only on an in-memory countdown.
- [ ] Save selected answers and flags locally.
- [ ] No correctness or explanations during the session.
- [ ] Question navigator with current/answered/unanswered/flagged states.
- [ ] Respect configured back-navigation behavior.
- [ ] Restore after app backgrounding or termination.
- [ ] Warn before finishing with unanswered questions.

## 8.4 Mock result

- [ ] Practice percentage.
- [ ] Above/below practice threshold wording.
- [ ] Domain breakdown.
- [ ] Time used.
- [ ] Strongest and weakest domains.
- [ ] Comparison with previous mock attempts.
- [ ] Review incorrect answers.
- [ ] Readiness update and disclaimer.

### Phase 8 exit criteria

- [ ] Mock generation always obeys config and blueprint.
- [ ] Session recovery works.
- [ ] No screen claims official exam passage.

---

# PHASE 9 — Payments and subscriptions

**Implement this phase after premium features and fake entitlement gates work.**

## 9.1 Entitlement architecture before StoreKit

- [ ] Define `Entitlement.free` and `Entitlement.premium`.
- [ ] Define a platform-independent `SubscriptionService`.
- [ ] Define `FeatureAccessService`.
- [ ] Centralize premium features:
  - unlimited practice
  - mock exams
  - weak-area practice
  - incorrect-question practice
  - advanced custom quiz
  - advanced progress
  - readiness history
- [ ] Build a fake subscription service for tests and previews.
- [ ] Confirm every premium feature returns to the requested action after a
  successful purchase.

## 9.2 Add Flutter in-app purchases

- [ ] Add Flutter's official `in_app_purchase` package.
- [ ] Enable the In-App Purchase capability in Xcode.
- [ ] Load product identifiers from `ExamConfig`.
- [ ] Query products from the store.
- [ ] Display only store-provided localized price and billing period.
- [ ] Listen to the purchase stream before initiating purchases.
- [ ] Handle pending, purchased, restored, canceled, and error states.
- [ ] Verify purchases before granting permanent entitlement.
- [ ] Call purchase completion after verification where required.
- [ ] Restore purchases.
- [ ] Refresh entitlement on app launch and foreground.
- [ ] Cache the last valid entitlement for graceful offline use.
- [ ] Handle expiration, billing retry, grace period, revocation, refund, and
  product-unavailable states.

## 9.3 Paywall

- [ ] Headline: `Pass With Confidence`.
- [ ] Explain premium outcomes, not pressure tactics.
- [ ] Show all available products returned by StoreKit.
- [ ] Make one option visually recommended without false scarcity.
- [ ] Clearly show billing period and recurring nature.
- [ ] Link Terms and Privacy.
- [ ] Add Restore Purchases.
- [ ] Add Manage Subscription where supported.
- [ ] Allow dismissal and continued free use.
- [ ] Do not use fake countdowns, fake discounts, or preselected hidden consent.
- [ ] Do not link to external digital purchase methods from the iOS app unless
  an applicable storefront entitlement/rule explicitly permits it.

## 9.4 Payment testing

- [ ] Create an Xcode StoreKit configuration for local tests.
- [ ] Test each product and product-not-found state.
- [ ] Create App Store Connect sandbox testers.
- [ ] Test new purchase, cancel, pending approval, restore, renewal, expiration,
  grace period, billing retry, refund/revocation, and network interruption.
- [ ] Test on a physical iPhone.
- [ ] Test through TestFlight before submission.

### Phase 9 exit criteria

- [ ] No price is hardcoded.
- [ ] Purchases cannot double-unlock or remain pending forever.
- [ ] Restore works on a fresh install.
- [ ] Free study remains usable when the store is unavailable.

---

# PHASE 10 — Supabase and optional authentication

**Start only after local persistence and offline engines are stable.**

## 10.1 Decide whether V1 needs Supabase

### Recommended V1: no mandatory account

- [ ] Launch and study locally without authentication.
- [ ] Use Apple restore purchases for accountless subscription restoration.
- [ ] Queue question reports locally if remote submission is unavailable.
- [ ] Defer cloud sync if schedule or complexity threatens product quality.

### Add Supabase when at least one is required

- Cross-device progress sync.
- Account-based subscription entitlement sync.
- Remote question-report submission.
- Controlled content-package distribution and rollback.
- Server-side App Store transaction validation and notifications.

## 10.2 Supabase project setup

- [ ] Create separate development and production projects.
- [ ] Add `supabase_flutter` only when this phase begins.
- [ ] Keep project URL and publishable key in environment configuration.
- [ ] Never ship secret/service-role keys inside the app.
- [ ] Install and use Supabase CLI migrations.
- [ ] Commit migrations to the repository.
- [ ] Do not make production schema changes manually in the dashboard.
- [ ] Enable Row Level Security before granting client access.
- [ ] Add explicit owner-only policies for every user table.
- [ ] Run Security Advisor and resolve findings.
- [ ] Configure backups and recovery expectations.

## 10.3 Suggested cloud schema

- [ ] `profiles`
- [ ] `user_exam_settings`
- [ ] `answer_attempts`
- [ ] `question_states`
- [ ] `practice_sessions`
- [ ] `mock_attempts`
- [ ] `readiness_snapshots`
- [ ] `question_reports`
- [ ] `entitlements`
- [ ] `content_releases`
- [ ] `devices` only if genuinely needed; avoid collecting device data by
  default.

## 10.4 Local-first sync rules

- [ ] Local SQLite remains the source used by screens during normal study.
- [ ] Sync happens in the background when signed in and online.
- [ ] Use UUIDs and append-only merge for answer attempts and sessions.
- [ ] Use updated timestamps and deterministic last-write rules for settings
  and bookmarks.
- [ ] Never overwrite a newer local attempt with stale server state.
- [ ] Make sync retryable and idempotent.
- [ ] Display sync status in Settings, not as a blocking global spinner.
- [ ] Allow sign-out without deleting local progress unless the user requests it.
- [ ] Define exactly what happens when two devices edit the same setting.

## 10.5 Authentication UX

- [ ] Label the optional feature `Sync Progress`.
- [ ] Explain what data leaves the device before sign-in.
- [ ] Offer `Continue without an account` during onboarding and Settings.
- [ ] Do not request name, birthday, phone number, or profile photo unless needed.
- [ ] Add a clear signed-in state, sign-out action, and sync status.

## 10.6 Sign in with Apple — implement first

- [ ] Enable the Sign in with Apple capability for the bundle ID and Xcode
  target.
- [ ] Configure Apple provider settings in Supabase.
- [ ] Use native Sign in with Apple on iOS where possible.
- [ ] Generate and verify a cryptographic nonce.
- [ ] Exchange the Apple identity token with Supabase.
- [ ] Store the user's display name only when Apple supplies it on first sign-in.
- [ ] Support Apple's private relay email.
- [ ] Test canceled, failed, revoked, and repeated sign-in flows.
- [ ] Document credential/key rotation responsibilities if an OAuth secret is
  used.

## 10.7 Google login — optional, implement after Apple

- [ ] Add Google login only if there is clear user demand.
- [ ] Create iOS and Android OAuth clients in Google Cloud.
- [ ] Configure bundle IDs, URL schemes, and redirect URIs.
- [ ] Configure the Google provider in Supabase.
- [ ] Exchange Google ID/access tokens through Supabase Auth.
- [ ] Test account collision when Apple and Google use the same email.
- [ ] Implement explicit account linking rather than creating duplicate progress.
- [ ] Keep Sign in with Apple equally visible on iOS.

## 10.8 Account deletion — required when accounts exist

- [ ] Add `Delete Account` inside Settings.
- [ ] Explain that cloud progress will be permanently deleted.
- [ ] Reauthenticate when appropriate.
- [ ] Delete or anonymize server data not legally required to be retained.
- [ ] Remove Auth identity through a secured server/Edge Function.
- [ ] Revoke provider credentials where applicable.
- [ ] Decide separately whether local progress is retained or erased, and ask
  the user clearly.
- [ ] Test deletion for Apple private-relay and Google accounts.

### Phase 10 exit criteria

- [ ] The app remains fully usable when signed out or offline.
- [ ] Every client-accessible table has tested RLS policies.
- [ ] Google login is never offered on iOS without the required equivalent
  privacy-preserving login option.
- [ ] Account deletion can be initiated inside the app.

---

# PHASE 11 — Server-side subscription verification

This phase is recommended before public release if Supabase is included.

- [ ] Create a Supabase Edge Function for transaction verification.
- [ ] Keep Apple keys and credentials only in server-side secrets.
- [ ] Verify signed StoreKit transaction information.
- [ ] Store original transaction ID, product ID, expiration, status, and last
  verified time.
- [ ] Use idempotent upserts so repeated notifications are safe.
- [ ] Configure App Store Server Notifications V2 endpoint.
- [ ] Validate notification signatures and environment.
- [ ] Handle subscribed, renewed, expired, grace-period, billing-retry,
  refunded, revoked, and upgraded/downgraded events.
- [ ] Keep entitlement decisions behind a repository/service interface.
- [ ] Reconcile server entitlement with on-device StoreKit state.
- [ ] Never trust a client-supplied `isPremium` boolean.
- [ ] Test sandbox and production environment separation.
- [ ] Add structured server logs without storing unnecessary personal data.

### Accountless alternative

If V1 has no Supabase account, use StoreKit's current entitlements and Restore
Purchases on device. Keep the server-verification interface available for a
future account/sync release.

---

# PHASE 12 — Settings, privacy, support, and legal screens

## 12.1 Settings

- [ ] Exam Date.
- [ ] Daily Goal.
- [ ] Notifications.
- [ ] Theme: System / Light / Dark if manual override is offered.
- [ ] Current subscription plan.
- [ ] Upgrade.
- [ ] Restore Purchases.
- [ ] Manage Subscription.
- [ ] Optional Sync Progress / account state.
- [ ] Sign Out when signed in.
- [ ] Delete Account when account creation exists.
- [ ] Exam version, content version, and last updated date.
- [ ] App version and build number.

## 12.2 Support and legal

- [ ] Report a Problem.
- [ ] Contact Support.
- [ ] Privacy Policy.
- [ ] Terms of Use.
- [ ] Exam disclaimer.
- [ ] Content sources/review statement.
- [ ] Subscription terms.
- [ ] Acknowledgements/licenses for dependencies.

## 12.3 Question reporting

- [ ] Categories: incorrect answer, incorrect explanation, outdated, typo,
  unclear, other.
- [ ] Attach exam ID, question ID/version, content version, and app version.
- [ ] Do not attach user answers or personal information unnecessarily.
- [ ] Queue offline.
- [ ] Submit through Supabase only when configured and permitted.
- [ ] Add an admin/editorial triage workflow outside the app.

---

# PHASE 13 — Notifications, analytics, and operational visibility

## 13.1 Notifications

- [ ] Ask for notification permission only after explaining the benefit.
- [ ] Offer local study reminders based on exam date and preferences.
- [ ] Keep reminders optional and editable.
- [ ] Do not send manipulative urgency messages.
- [ ] Avoid Supabase/push infrastructure if local notifications are sufficient.

## 13.2 Analytics

- [ ] Keep an `AnalyticsService` interface with no-op/debug implementation.
- [ ] Track only product events needed for improvement:
  - onboarding started/completed
  - diagnostic completed
  - practice started/completed
  - mock started/completed
  - paywall viewed
  - purchase started/completed
  - question reported
- [ ] Never send question text, answer text, email, or free-form report notes to
  general analytics.
- [ ] Avoid cross-app tracking and advertising identifiers.
- [ ] If a third-party SDK is added, update privacy disclosures and review its
  privacy manifest/data behavior first.

## 13.3 Error logging

- [ ] Add privacy-conscious crash/error reporting only when operationally
  necessary.
- [ ] Scrub tokens, emails, question text, purchase payloads, and personal data.
- [ ] Define retention and access controls.
- [ ] Log content version, app version, error code, and non-personal diagnostic
  context.

---

# PHASE 14 — Automated testing and quality gates

## 14.1 Unit tests

- [ ] Content codec and validator.
- [ ] Question filtering and selection.
- [ ] Adaptive selection.
- [ ] Mock blueprint allocation and generation.
- [ ] Progress aggregation.
- [ ] Readiness calculation and labels.
- [ ] Evidence confidence.
- [ ] Free-tier limits.
- [ ] Entitlement and feature access.
- [ ] Sync conflict rules if Supabase is added.

## 14.2 Persistence tests

- [ ] Migration tests from every released schema version.
- [ ] Attempt/bookmark/mock persistence across reopen.
- [ ] Content retirement with preserved history.
- [ ] Content-package rollback.
- [ ] Interrupted write recovery.

## 14.3 Widget tests

- [ ] Bootstrap and onboarding routing.
- [ ] Diagnostic flow.
- [ ] Practice selection/submission/feedback.
- [ ] Home empty and low-evidence states.
- [ ] Paywall gates and purchase states.
- [ ] Mock finish confirmation.
- [ ] Settings and account deletion entry point.
- [ ] Large-text layouts.

## 14.4 Integration tests

- [ ] First launch through diagnostic and Home.
- [ ] Complete Practice session and verify Progress/Home update.
- [ ] Complete and restore interrupted Mock Exam.
- [ ] Purchase with StoreKit test configuration.
- [ ] Restore premium on fresh install.
- [ ] Sign in/sync/sign out if Supabase is enabled.
- [ ] Account deletion if accounts are enabled.

## 14.5 Required checks for every phase

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build ios --simulator
```

- [ ] Fix errors and warnings introduced by the phase.
- [ ] Track existing prototype info-level lint debt and reduce it before release.
- [ ] Add CI for formatting, analysis, tests, and at least one build target.
- [ ] Protect `main` so pull requests and checks are required.

---

# PHASE 15 — iOS production configuration

## 15.1 Xcode and Flutter project

- [ ] Set production bundle identifier.
- [ ] Set display name.
- [ ] Set minimum supported iOS version intentionally.
- [ ] Configure automatic/manual signing for the correct Apple team.
- [ ] Add In-App Purchase capability.
- [ ] Add Sign in with Apple capability only if authentication is implemented.
- [ ] Remove unused capabilities and permission descriptions.
- [ ] Add final app icon set, including 1024×1024 marketing icon.
- [ ] Add production launch screen.
- [ ] Verify portrait/iPad orientations intentionally.
- [ ] Verify iPad layouts if iPad compatibility is declared.
- [ ] Update version and build number.
- [ ] Review third-party SDK signatures and privacy manifests.
- [ ] Confirm export-compliance answers.
- [ ] Archive with release configuration.

## 15.2 App behavior review

- [ ] No placeholder or lorem-ipsum content.
- [ ] No dead buttons or fake schedules.
- [ ] No debug banner or debug-only screens.
- [ ] No mandatory login without significant account-based functionality.
- [ ] Subscription purchase, restore, and manage links work.
- [ ] Privacy/terms/support links work.
- [ ] Offline core study works.
- [ ] Content error states are recoverable.
- [ ] All claims and disclaimers are accurate.

---

# PHASE 16 — App Store Connect and TestFlight

## 16.1 App Store metadata

- [ ] App name and subtitle.
- [ ] Description focused on benefits and actual features.
- [ ] Keywords without competitor or misleading trademark use.
- [ ] Support URL.
- [ ] Marketing URL if available.
- [ ] Privacy Policy URL.
- [ ] Copyright owner.
- [ ] Age rating questionnaire.
- [ ] Education category.
- [ ] App privacy answers covering the app and every included SDK.
- [ ] Export compliance.
- [ ] Content-rights declaration.

## 16.2 Screenshots

- [ ] Capture real final app screens, not design mockups that misrepresent the
  product.
- [ ] Include Home readiness/recommendation.
- [ ] Include Practice and explanation.
- [ ] Include Mock Exam.
- [ ] Include Progress.
- [ ] Include paywall only if useful and accurate.
- [ ] Prepare required iPhone sizes.
- [ ] Prepare iPad screenshots if the app is submitted for iPad.
- [ ] Avoid official endorsement language or guaranteed-pass claims.

## 16.3 Subscription review information

- [ ] Complete localization and pricing for every subscription.
- [ ] Add review screenshot showing the paywall.
- [ ] Ensure product status is ready for submission.
- [ ] Attach/submit subscriptions with the app as required.
- [ ] Explain premium access and Restore Purchases in review notes.

## 16.4 TestFlight

- [ ] Upload an archive to App Store Connect.
- [ ] Complete encryption/export questions.
- [ ] Run internal TestFlight testing first.
- [ ] Run external testing with a small representative group.
- [ ] Test install, update, fresh install, and data migration.
- [ ] Test every subscription with sandbox/TestFlight.
- [ ] Test purchase restoration using another device.
- [ ] Test account deletion and social login if included.
- [ ] Review crashes, feedback, and screenshots from testers.
- [ ] Fix all release-blocking defects before App Review.

---

# PHASE 17 — App Review submission

- [ ] Select the final build in App Store Connect.
- [ ] Select the subscription products for review.
- [ ] Provide clear review notes explaining:
  - where the paywall is
  - how to restore purchases
  - which features are premium
  - how to access account deletion, if applicable
  - that the app is local-first and works without an account
- [ ] Provide a working review account only if an authenticated feature requires
  one.
- [ ] Confirm all backend services are in production mode and available.
- [ ] Confirm support and privacy links are live.
- [ ] Confirm no beta/test wording appears in the binary or metadata.
- [ ] Submit for review.
- [ ] Monitor App Store Connect messages and respond with precise reproduction
  details if questioned.

### Final release gate

- [ ] All automated tests pass.
- [ ] No analyzer errors or warnings.
- [ ] Physical-device smoke tests pass.
- [ ] Purchase/restore/expiration tests pass.
- [ ] Accessibility review passes.
- [ ] Professional content approval is complete.
- [ ] Privacy disclosures match actual data collection.
- [ ] Account deletion works if accounts exist.
- [ ] Legal/support pages are live.
- [ ] App Review notes are complete.

---

# PHASE 18 — Post-launch operations

- [ ] Monitor crashes, purchase failures, content reports, and support requests.
- [ ] Review conversion without using invasive tracking.
- [ ] Respond quickly to inaccurate/outdated question reports.
- [ ] Maintain content releases and retire questions safely.
- [ ] Review the official DANB outline at least annually and on announced changes.
- [ ] Test every iOS/Flutter/plugin upgrade before release.
- [ ] Rotate Apple/Supabase secrets before expiration.
- [ ] Verify subscription products remain available in every intended storefront.
- [ ] Run restore-purchase regression tests for each release.
- [ ] Maintain database backups and restore drills if Supabase is used.
- [ ] Keep Privacy Nutrition Label and policy pages aligned with actual behavior.

---

## 19. Recommended dependency timing

| Dependency/capability | Add when | Reason |
|---|---|---|
| Current Flutter/Material/Cupertino | Now | Core UI |
| Riverpod or equivalent | When shared controllers begin | Avoid premature state abstraction |
| Drift/SQLite | Phase 5 | Real relational local persistence |
| `in_app_purchase` | Phase 9 | Premium features and gates are already functional |
| `url_launcher` | Phase 9/12 | Terms, privacy, support, manage subscription |
| `supabase_flutter` | Phase 10 only if sync/backend is approved | Cloud auth/sync/reporting |
| Sign in with Apple support | Phase 10 before/with Google login | iOS login compliance and privacy |
| Google Sign-In support | Phase 10 after Apple, optional | Additional account convenience |
| Crash reporting SDK | Late QA, only if justified | Minimize data collection and SDK risk |

---

## 20. Condensed execution order

1. **Apple/legal setup:** reserve bundle ID, app record, URLs, and subscription
   IDs.
2. **Foundation:** finish models, repositories, app boundaries, and tests.
3. **Design shell:** production theme, four tabs, accessibility.
4. **Onboarding:** local-first welcome, date, experience, diagnostic.
5. **Content pipeline:** professionally reviewed, versioned question bank.
6. **Persistence:** Drift/SQLite and migrations.
7. **Practice:** real sessions, feedback, bookmarks, reports.
8. **Home/Progress:** recommendation, readiness, adaptive practice.
9. **Mock Exam:** blueprint generation, timer, recovery, results.
10. **Payments:** StoreKit through `in_app_purchase`, feature gates, paywall.
11. **Supabase decision:** add only for real cloud benefits.
12. **Authentication:** optional Sync Progress; Apple first, Google optional.
13. **Server entitlements:** transaction verification and notifications if cloud
    accounts exist.
14. **Legal/settings/privacy:** complete user controls and disclosures.
15. **QA:** automated, device, accessibility, offline, purchase, and migration
    testing.
16. **TestFlight:** internal, external, sandbox subscriptions.
17. **App Review:** metadata, screenshots, privacy, review notes, submission.
18. **Operations:** content updates, support, monitoring, and compliance.

---

## 21. Official implementation references

- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple auto-renewable subscriptions](https://developer.apple.com/app-store/subscriptions/)
- [Configure subscriptions in App Store Connect](https://developer.apple.com/help/app-store-connect/manage-subscriptions/offer-auto-renewable-subscriptions/)
- [Test auto-renewable subscriptions](https://developer.apple.com/documentation/storekit/testing-an-auto-renewable-subscription)
- [Apple account deletion requirement](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
- [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)
- [Flutter in-app purchase overview](https://docs.flutter.dev/resources/in-app-purchases-overview)
- [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup)
- [Supabase Flutter user-management guide](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- [Supabase Sign in with Apple](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Supabase Sign in with Google](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Supabase Row Level Security and deployment responsibility](https://supabase.com/docs/guides/deployment/shared-responsibility-model)
- [Supabase API key guidance](https://supabase.com/docs/guides/getting-started/api-keys)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

---

## 22. Definition of App Store ready

The app is App Store ready only when it has real reviewed content, real local
persistence, complete onboarding and study flows, deterministic readiness,
blueprint-correct mock exams, StoreKit-tested subscriptions, functional legal
and support links, accurate privacy disclosures, passing automated/device tests,
and a production TestFlight build. Supabase and login are required only if the
released app includes cloud/account features; if accounts are included, secure
sync, Sign in with Apple parity, RLS, and in-app account deletion become release
requirements.
