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

- [x] Enroll the legal owner in the Apple Developer Program.
- [x] Choose the permanent production bundle ID:
  `com.anielkad.danbrhsprep`.
- [x] Replace the current example Android/iOS application identifiers.
- [x] Register the bundle ID in Certificates, Identifiers & Profiles.
- [x] Create the app record in App Store Connect.
- [x] Use the exact same bundle ID in Flutter, Xcode, and App Store Connect.
- [x] Decide the public app name and subtitle.
- [x] Reserve the app name in App Store Connect.
- [x] Set the primary category to Education.
- [x] Accept the Paid Applications Agreement.
- [x] Complete banking and tax forms.

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

- [x] Create repository interfaces for:
  - content
  - progress
  - user settings
  - subscriptions
  - optional sync
- [x] Keep engines free of Flutter widget and plugin imports.
- [x] Add immutable models for:
  - `UserProfile`
  - `AnswerAttempt`
  - `QuestionState`
  - `PracticeSession`
  - `MockAttempt`
  - `ReadinessSnapshot`
  - `QuestionReport`
  - `Entitlement`
- [ ] Introduce a simple state-management layer when shared state begins.
  (No shared cross-screen state exists yet — every screen only has local
  `setState` UI state — so no controller layer was added; see PR notes.)
- [ ] Prefer Riverpod only if it clearly reduces controller/lifecycle code.
  (Not applicable until the item above applies.)
- [x] Keep Navigator initially; add `go_router` only if deep-link and auth
  routing becomes meaningfully difficult.

### Phase 1 exit criteria

- [x] Business logic can be unit tested without a device.
- [x] UI cannot directly query JSON, SQLite, StoreKit, or Supabase.
- [ ] Adding another exam requires config, content, and assets—not new engines.
  (The content/config/domain layer is already exam-agnostic, but screens
  still show hardcoded prototype text rather than reading from
  `ExamConfig`/`ContentPackage`, so this isn't true end-to-end yet.)

---

# PHASE 2 — Design system and production app shell

## 2.1 Theme cleanup

- [x] Preserve the prototype palette as semantic colors:
  - background
  - surface/card
  - primary action
  - primary text
  - secondary text
  - success
  - error
  - warning
  - divider
- [x] Add complete light and dark themes.
- [x] Remove hardcoded use of `Colors.white` where semantic surface colors are
  needed.
- [x] Replace deprecated `withOpacity` calls with supported color APIs.
- [x] Remove the unbundled hardcoded `SF Pro Display` family or deliberately
  bundle a licensed font.
- [x] Create spacing tokens: 4, 8, 12, 16, 20, 24, 32, 40.
- [x] Create consistent radius, elevation, icon, and tap-target tokens.
- [x] Ensure all interactive controls have at least a 44×44 logical-point
  target on iOS.

## 2.2 Reusable components

- [x] `AppScaffold`
- [x] `PrimaryButton`
- [x] `SecondaryButton`
- [x] `AppCard`
- [x] `AppBottomNavigation`
- [x] `ReadinessRing`
- [x] `ReadinessCard`
- [x] `AnswerOptionTile`
- [x] `DomainProgressRow`
- [x] `ProgressBar`
- [x] `EmptyState`
- [x] `ErrorState`
- [x] `LoadingState`
- [x] `SubscriptionProductCard`
- [x] Adaptive alert/dialog wrapper using Cupertino behavior where beneficial.

## 2.3 Navigation shell

- [x] Replace `Home / Practice / Stats / Profile` with:
  `Home / Practice / Mock Exam / Progress`.
- [x] Remove Login from first-launch routing.
- [x] Move Settings to a toolbar icon.
- [x] Preserve selected tab state.
- [x] Use state restoration where practical.
- [x] Add route-level analytics hooks without adding an analytics SDK yet.

## 2.4 Accessibility

- [x] Test Dynamic Type at the largest accessibility sizes. (Extended:
  every text-bearing/reachable screen now has an automated pass at a
  4.0x stress scale — chosen because manual on-device testing at the
  real iOS AX5 category found overflow beyond what a plain 3.0x probe
  caught — on the small-phone viewport, with no global text-scale
  clamping.)
- [x] Add semantic labels to score rings, charts, answer choices, bookmarks,
  flags, and navigation items. (No flag/report control exists in the UI
  yet — nothing to label; will be covered when that control is built.)
- [x] Do not communicate correct/incorrect state using color alone.
- [ ] Verify VoiceOver reading and focus order. (Reading/focus *order* is
  covered by automated semantics-tree-traversal tests; actual VoiceOver
  operation has not been performed — see
  `docs/ACCESSIBILITY_MANUAL_VERIFICATION.md`. Leaving unchecked until
  that manual pass is run.)
- [x] Respect Reduce Motion.
- [x] Ensure contrast meets accessibility expectations in both themes.

### Phase 2 exit criteria

- [x] Four-tab app shell works on small iPhone, large iPhone, and iPad.
  (Evidence: `test/screens/phase_2_exit_criteria_test.dart`, 18 tests
  covering all four tabs at 320x568, 430x932, and 834x1194 — tab
  selection, re-selection safety, visual/semantic selected state, Settings
  open/close + Back, inactive-tab semantics exclusion, and disabled
  future-feature controls exposing no tap action. All pass.)
- [x] Light/dark mode and large text do not break layouts. (Evidence: the
  same test file's theme + text-scale matrix — 3 viewports x 2 themes
  (light/dark) x 2 scales (1.0x/4.0x) x all 4 tabs, 12 tests, all pass
  with no overflow exceptions; selected/disabled states and bottom-nav
  usability confirmed distinguishable at every combination.

  `AppScaffold`'s adaptive header (single-row when the title fits, a
  stacked leading/actions-row-then-full-width-title layout when it
  doesn't, sharing one scroll region with the body in that case — no
  `FittedBox`, no fixed height budget) is unchanged from the prior pass
  and still fully covered by `test/screens/essential_label_visibility_test.dart`.

  The bottom nav went through two corrections. A first pass removing
  `TextOverflow.ellipsis` used `FittedBox(fit: scaleDown)` to guarantee
  no overflow — rejected on review, since shrinking essential text after
  layout overrides the user's chosen accessibility text size just as
  much as truncating it does. A second pass replaced that with a
  measure-then-switch design (plain four-column `Row` vs. a horizontally
  scrollable fallback) — but the *measurement* used `flutter test`'s
  synthetic fallback font, which renders every character as a fixed box
  exactly as wide as the font size, not real Roboto glyph metrics. Under
  that synthetic font, "Practice"/"Progress" (single 8-character words,
  no natural wrap point) measured ~88px against an 80px quarter-column
  at 320px width — an 8px shortfall with no clean fix (a forced mid-word
  break like "Practic"/"e" is arguably worse than truncation) — which
  would have made the scrollable fallback the *normal* phone-width
  layout, not an accessibility-only one.

  Investigating that discrepancy (vendoring the real Roboto files
  Flutter itself ships and bundles into every build — Apache 2.0,
  `test/fonts/`, loaded by `test/flutter_test_config.dart` — and
  re-measuring through the actual rendered widget tree) confirmed it was
  purely a test-font artifact: real Roboto renders "Practice" at ~41px
  and "Progress" at ~44px at 1.0x, comfortably inside an 80px column with
  room to spare. `lib/widgets/app_bottom_navigation.dart` was corrected
  accordingly:

  - Per-item horizontal padding dropped from `AppSpacing.md` (12px/side)
    to `AppSpacing.xs` (4px/side) — the excess wasn't needed even before
    the font-measurement fix, and every viewport has generous margin now.
  - The fit decision measures each label's *widest single word* (not the
    whole label) against the true equal-column width: multi-word labels
    like "Mock Exam" wrap onto a second line on their own once given
    that real width — no manual line-splitting — and the bar's height
    just grows to fit whichever item needs the most lines. Only when
    even a label's widest word doesn't fit — verified to require ~2.0x+
    on a 320px phone, never true at 1.0x on any of the four required
    widths — does the bar fall back to the horizontally scrollable
    layout, where every item keeps its full natural size.
  - The bar is now a `StatefulWidget` owning a `ScrollController`, with
    the selected tab automatically scrolled into view (via
    `Scrollable.ensureVisible`, a no-op if already visible, so a user's
    manual scroll position is never reset unnecessarily) after initial
    construction, state restoration, a programmatic tab change, and any
    parent rebuild — immediately (no animation) under Reduce Motion.
    `mounted` is checked before any post-frame callback touches state.

  `test/widgets/app_bottom_navigation_adaptive_test.dart` (new) proves:
  all four labels visible with zero horizontal scrolling and every tap
  target ≥44×44 at 320/375/430/iPad at 1.0x; the fallback activates (and
  is proven necessary) at 4.0x/320×568, with no `FittedBox`, no
  `didExceedMaxLines`, and painted size matching natural
  (pre-transform) layout size — the same real-vs-natural-size comparison
  technique from the previous pass, which does detect a genuine
  `FittedBox` shrink (verified against a synthetic fixture) — and the
  requested 4.0x `TextScaler` reaching every label; automatic reveal on
  initial selection, on a programmatic change to an off-screen tab
  (without resetting state or leaking post-frame work past disposal),
  and immediately (not animated) under Reduce Motion.
  `test/screens/essential_label_visibility_test.dart` continues to cover
  `AppScaffold` titles and was re-verified against this correction.

  **Correction to the above**: that second pass had also added an
  explicit `fontFamily: 'Roboto'` to the *production* label style (both
  the `TextPainter` measurement and the rendered `Text`), reasoning that
  it was "already this app's real default font on every platform." That
  claim doesn't hold in general — Flutter's platform typography can
  resolve differently by platform/configuration, and this app had
  earlier and deliberately removed a different hardcoded, unbundled font
  name (see `test/theme/app_theme_test.dart`'s "theme does not declare
  the removed unbundled font family") specifically so text renders
  through the theme's real resolution rather than an assumption baked
  into a widget. `lib/widgets/app_bottom_navigation.dart` was corrected
  again: the hardcoded `fontFamily: 'Roboto'` is gone from production
  code entirely. Both the label's `TextPainter` measurement and its
  rendered `Text` now resolve their style through one shared private
  function, `_resolveLabelStyle`, which merges only size/weight/color
  onto `DefaultTextStyle.of(context).style` — the same resolution `Text`
  performs internally — so measurement and rendering use the literal
  same style by construction and can't drift apart, and neither
  hardcodes a font family. The fit-decision measurement uses the wider
  of the selected/unselected resolved styles for every label regardless
  of which tab is actually selected, so the fixed-vs-scrollable choice
  can't flip merely because a different tab becomes selected (proven at
  a near-threshold scale in
  `test/widgets/app_bottom_navigation_font_resolution_test.dart`).

  The Roboto files under `test/fonts/` remain, but only as deterministic
  *test* infrastructure (loaded solely by `test/flutter_test_config.dart`,
  not declared as a pubspec asset, not referenced anywhere in `lib/`) —
  they replace `flutter test`'s synthetic fallback font so measurements
  in tests match real glyph proportions, they do not claim or enforce
  what font production actually uses. Production measurement uses
  whatever the real resolved theme/platform label style is, whatever
  that turns out to be on a given platform.

  Fixing the font-measurement issue also surfaced two pre-existing,
  unrelated test bugs: `test/screens/main_shell_test.dart` and
  `test/screens/reduce_motion_test.dart` hardcoded a literal day number
  ("Wed 19"/day "19") from `HomeScreen`'s real-date week strip (itself
  fixed to use `DateTime.now()` in an earlier pass) — those tests
  silently broke the moment the real calendar moved into a new week
  while this task was in progress. Both now compute the expected
  day/label at run time instead of hardcoding it, matching the pattern
  `test/screens/phase_2_exit_criteria_test.dart` already used correctly.)
- [ ] No final screen depends on prototype-only content. (See
  `docs/PROTOTYPE_CONTENT_AUDIT.md`. `HomeScreen`, `ProfileSettingsScreen`,
  `ProgressScreen`, and `ExamOverviewScreen` (PREP-460: real exam
  duration/question count and per-domain approved-question coverage,
  replacing the hardcoded "1.5 Hours · 100 Questions · Intermediate"
  and invented 5-topic list) were fixed to use real data or an honest
  empty/unavailable state. `PracticeQuestionScreen` and
  `AnswerExplanationScreen` are reachable today and still depend on
  hardcoded prototype question content that requires Phase 6
  content-package and practice-engine work to resolve honestly. Left
  unchecked until those are addressed.)

---

# PHASE 3 — App bootstrap and onboarding

## 3.1 App bootstrap

- [x] Replace the fixed two-second splash delay with real initialization.
  (`SplashScreen` no longer owns a `Timer`; its lifetime is entirely
  determined by `AppBootstrapService.initialize()` completing. Evidence:
  `test/main_test.dart` — a source-content check that no `Timer(`/
  `Duration(seconds: 2)` remains, plus "the splash screen stays visible"
  while a controlled `Completer`-backed content loader is deliberately
  left unresolved for 5 (virtual) seconds.)
- [x] Load and validate the selected exam content package. (New
  `lib/bootstrap/app_bootstrap_service.dart` loads through the existing,
  plain-Dart `ContentRepository` interface — not the Flutter-importing
  `ExamContentLoader`/`BundledExamContentLoader` directly — confirms the
  loaded package's `exam.id` matches the selected exam, and validates
  with the existing, unmodified `ContentValidator`, no validation logic
  duplicated. The production adapter, `BundledContentRepository` (new,
  `lib/features/content/data/bundled_content_repository.dart`), delegates
  to `BundledExamContentLoader`/`rootBundle` and is wired only from
  `main.dart`, so `app_bootstrap_service.dart` and everything it directly
  imports carry no Flutter dependency, direct or transitive — see
  `test/bootstrap/dependency_direction_test.dart` for a source-level
  proof of that boundary. Evidence: `test/bootstrap/app_bootstrap_service_test.dart`,
  including one test that loads the real bundled DANB RHS content
  through the real `BundledContentRepository`/`BundledExamContentLoader`/
  `rootBundle`, not a fixture; and `test/bootstrap/production_wiring_test.dart`,
  which additionally proves the *exact* production wiring — the real
  `BundledContentRepository` plus `SharedPreferencesBootstrapLocalStore`
  plus `DriftUserSettingsRepository` (PREP-661/662), no network —
  succeeds against the real bundled asset end to end, not just
  algorithm-level test doubles.)
- [ ] Load local profile, settings, progress, and entitlement cache.
  **Not fully implemented — left unchecked.** What is genuinely, durably
  loaded today: selected exam ID, theme preference, the onboarding-complete
  flag, a readiness/progress *snapshot* (not full practice history), and
  a cached entitlement snapshot, all through the new
  `SharedPreferencesBootstrapLocalStore` — genuine local persistence, not
  an in-memory fake (`InMemoryBootstrapLocalStore` exists only for tests,
  matching this codebase's established fakes/ convention; see
  `test/bootstrap/shared_preferences_bootstrap_local_store_test.dart` for
  round-trip and corrupt-entry-handling evidence, and
  `test/bootstrap/production_wiring_test.dart` for the same store wired
  exactly as `main.dart` wires it). What remains **not** implemented: a
  production `DriftUserSettingsRepository` adapter is injected into
  `AppBootstrapService` in `main.dart` (PREP-661/662 — see Section 5.2),
  but nothing yet calls its `saveProfile`, so `loadProfile` still always
  returns `null` in practice — a real stored user profile is still never
  loaded, only ever honestly absent, until onboarding is wired to save
  one; and bootstrap itself (`AppBootstrapService.initialize`) still only
  eagerly loads the lightweight readiness *snapshot*, not full practice
  history — that history now does persist in a real database
  (`DriftProgressRepository` over the new `AppDatabase`, PREP-661), just
  queried on demand by `HomeScreen`/`ProgressScreen` rather than eagerly
  during bootstrap. Both gaps are real, deferred work, not rounding
  error — this checkbox stays unchecked until onboarding actually saves
  a profile through the repository and bootstrap itself loads more than
  the snapshot.

  The cached entitlement snapshot is a **last-known local cache, not
  authoritative purchase verification**: it is user-editable
  `SharedPreferences` data, not a verified receipt, and nothing here
  contacts StoreKit/Play Billing. A missing, corrupt, or expired
  entitlement cache always resolves to free tier (see
  `Entitlement.free`), and no premium feature gating exists anywhere
  based on this value — real verification is Phase 9's job. See the doc
  comments on `BootstrapReady.entitlement` and
  `BootstrapLocalStore.readEntitlementSnapshot` for the same boundary
  documented in code.
- [x] Check whether onboarding is complete. (An explicit, persisted
  boolean in `BootstrapLocalStore` — not inferred from any profile
  field. Defaults to incomplete when never set.)
- [x] Route to onboarding or the main app. (`SplashScreen` replaces
  itself with `OnboardingEntryScreen` or `MainShell` depending on that
  flag — never Login. Evidence: `test/main_test.dart`'s "successful
  bootstrap routing" group. `OnboardingEntryScreen`'s own "Continue"
  save is itself now failure-safe: a persistence failure keeps the user
  on the onboarding screen with an accessible live-region error and a
  Retry action, rather than silently entering the main app on an unsaved
  flag; a secondary "Continue for this session" action lets the user
  proceed without durable persistence when they choose to, without ever
  claiming the save succeeded. Evidence:
  `test/screens/onboarding_entry_screen_test.dart`'s "onboarding-save
  failure handling" group.)
- [x] Show a recoverable content-error screen if bundled content is
  invalid. (`SplashScreen` shows the existing `ErrorState` component
  with a safe, generic message and a Retry action that re-runs the
  complete bootstrap operation; duplicate taps while retrying cannot
  start a concurrent run, since the button itself disappears during
  loading. Evidence: `test/main_test.dart`'s "content failure" group.)
- [x] Never require network access to start studying. (`AppBootstrapService`
  has no HTTP/Supabase/auth/StoreKit-shaped dependency anywhere in its
  constructor or implementation, nor does anything it directly depends on
  — evidence includes a source-content check for exactly that
  (`test/bootstrap/dependency_direction_test.dart`,
  `test/bootstrap/app_bootstrap_service_test.dart`'s "no remote
  dependency is reachable" group), plus `test/bootstrap/offline_behavior_test.dart`
  proving the bootstrap *algorithm* succeeds offline, and
  `test/bootstrap/production_wiring_test.dart` additionally proving the
  real production wiring itself — real bundled asset, real
  `SharedPreferences`-backed store — succeeds with no network access.)

## 3.2 Welcome screen

- [x] Display `DANB RHS Exam Prep` from `ExamConfig`. (New
  `lib/screens/welcome_screen.dart` reads `BootstrapSessionScope.of(context)`
  and renders `contentPackage.exam.name` — never a hardcoded screen
  string. `content.json`'s `exam.name` already held the correct value, so
  no content-data change was needed. Evidence:
  `test/screens/welcome_screen_test.dart`'s "exam identity" group,
  including a test that injects a *different* fake exam name and asserts
  that (not the real DANB string) is what renders — proving there is no
  hardcoded fallback.)
- [x] Add headline: `Know when you're ready to pass.` (Exact string,
  asserted verbatim in `welcome_screen_test.dart`.)
- [x] Add short, calm supporting copy. (Exact string — `Build confidence
  with focused practice, clear explanations, and progress you can
  understand.` — asserted verbatim.)
- [x] Add one primary CTA: `Start Preparing`. (Exactly one `PrimaryButton`
  in the default state; no Login/Sign Up/Skip/secondary CTA anywhere in
  that state. Activation is guarded against duplicate taps and reuses
  Section 3.1's recoverable save-failure behavior — including its
  "Continue for this session" secondary action — only once a save has
  actually failed, not as a second CTA on the welcome content itself.)
- [x] Start `onboarding_started` analytics event through the internal
  interface. (`AnalyticsService` gained a plain-Dart `trackEvent(String
  name, {Map<String, Object?> properties})` method — no SDK added, no
  Flutter/vendor import. Fires exactly once per CTA activation (not on
  render, not again on Retry), carries only the non-sensitive `exam_id`
  sourced from `ExamConfig`, and a throwing analytics implementation
  never blocks onboarding. Evidence: `welcome_screen_test.dart`'s "CTA
  behavior and analytics" group.)

Replaces Section 3.1's minimal `OnboardingEntryScreen` (deleted, along
with its test file) with the production `WelcomeScreen` above — routed
at `/welcome`, wired from `SplashScreen`/`main.dart`. The
onboarding-completion bridge (persist `onboardingComplete`, enter
`MainShell`) is unchanged from Section 3.1 and stays explicitly
documented in code as temporary, pending Section 3.3's real next step.

## 3.3 Exam-date screen

- [x] Ask `When is your exam?`. (New `lib/screens/exam_date_screen.dart`,
  `ExamDateScreen`, route `/onboarding/exam-date` — pushed (not
  replaced) from `WelcomeScreen`'s `Start Preparing`, so Back returns to
  Welcome. Exact heading and supporting copy asserted verbatim in
  `test/screens/exam_date_screen_test.dart`.)
- [x] Support exact date. (Selecting "I know the exact date" reveals a
  date selector backed by the real Material `showDatePicker`, localized
  via `MaterialLocalizations.formatMediumDate` — no formatting
  dependency added.)
- [x] Support approximate date. (Same date-selector mechanism, under "I
  have an approximate date" — a distinct `ExamDatePrecision.approximate`
  value, not a duplicate. `ExamDatePrecision` now lives in its own leaf
  file, `lib/domain/models/exam_date_precision.dart` — extracted out of
  `UserProfile` so `ExamDateSelection` can depend on the enum without
  depending on the `UserProfile` aggregate merely to reuse it; both
  models import the leaf one-way, and it imports nothing itself.
  Evidence: `test/domain/models/exam_date_precision_dependency_test.dart`.)
- [x] Support `I haven't scheduled it yet`. (`ExamDatePrecision.notScheduled`;
  choosing it clears any in-progress date.)
- [x] Validate that a selected date is not in the past. (Two layers, per
  the roadmap's explicit "outside the picker too" requirement: the
  picker's own `firstDate: today` (from an injected clock, never a
  direct `DateTime.now()` in validation logic), and the independent,
  picker-agnostic `isExamDateSelectionValid` function
  (`lib/domain/models/exam_date_selection.dart`), re-checked immediately
  before saving and also applied when prefilling a *restored* selection
  — a previously-saved date that has since passed is not presented as
  valid; the precision choice stays visible and an accessible live-region
  message asks for a new date, per `ExamDateSelection`'s and the
  screen's tests.)
- [x] Store date and precision locally. (New `ExamDateSelection` domain
  value — reusing the leaf `ExamDatePrecision`, not a new enum —
  persisted through new `BootstrapLocalStore.readExamDateSelection`/
  `writeExamDateSelection` methods, implemented in both
  `SharedPreferencesBootstrapLocalStore` (as one atomic versioned JSON
  value under a single key, never separate drift-prone keys) and
  `InMemoryBootstrapLocalStore`. Decoding now strictly rejects an
  impossible calendar date: `year`/`month`/`day` must each be genuine
  integers, and the constructed `DateTime`'s own year/month/day are
  round-tripped back against what was stored — Dart's `DateTime`
  constructor silently normalizes an invalid date (e.g. `DateTime(2026,
  2, 31)` becomes a March date) rather than throwing, so this round-trip
  check is what actually catches and rejects that, instead of silently
  persisting the normalized/rolled-forward date. An unsupported JSON
  `version` is rejected the same way. Loaded during bootstrap into
  `BootstrapReady.examDateSelection` so the screen can prefill a
  returning user's choice. No fake `UserProfile` is created to hold
  this — the production `DriftUserSettingsRepository` adapter exists
  (PREP-661/662), but nothing here saves through it yet, exactly as
  Section 3.1 already documented. Evidence:
  `test/domain/models/exam_date_selection_test.dart`,
  `test/bootstrap/shared_preferences_bootstrap_local_store_test.dart`'s
  "exam date selection" group (including its "impossible calendar date"
  subgroup), and `test/bootstrap/app_bootstrap_service_test.dart`.)

`WelcomeScreen`'s `Start Preparing` now emits `onboarding_started` and
routes here instead of marking onboarding complete directly (evidence:
`test/screens/welcome_screen_test.dart`). This screen's own `Continue`
still uses the Section 3.1/3.2 temporary completion bridge — persist
`onboardingComplete`, enter `MainShell` — isolated to
`_ExamDateScreenState._continue` and documented there as pending Section
3.4, which replaces only its "on success" branch.

**Navigation stack on completion:** both the successful-persistence path
and the explicit "Continue for this session" path now use
`Navigator.pushAndRemoveUntil(..., (route) => false)`, not
`pushReplacement` — `MainShell` becomes the sole, root route, carrying
the successful `BootstrapReady` snapshot via `BootstrapSessionScope`
exactly as before, so a system Back gesture/button afterward has
nothing left to pop to and cannot reveal Welcome, Exam Date, or Splash.
Welcome → Exam Date remains a plain `push` (unaffected), so Back from
Exam Date still returns to Welcome, and a save failure never triggers
this navigation at all. Every manually constructed `MaterialPageRoute`
carries the correct `RouteSettings.name` (`ExamDateScreen.route` for
Welcome → Exam Date, `MainShell.route` for both completion paths into
Main), so `AnalyticsNavigatorObserver` reports the real named-route
sequence, not anonymous routes. Evidence:
`test/screens/onboarding_navigation_stack_test.dart`, including its
"named-route analytics" group, which drives the real
`AnalyticsNavigatorObserver`/`FakeAnalyticsService` through the actual
Welcome → Exam Date → Main flow and asserts the exact ordered sequence
`['/welcome', '/onboarding/exam-date', '/main']` (each reported exactly
once, with no duplicate from the stack-clearing route removal), that
`onboarding_started` remains a single generic event carrying only the
non-sensitive exam ID, that a no-op Back-from-Main attempt reports
nothing further, and that the session-only continuation path also
reports `/main` correctly.

**Accessibility verification:** `test/screens/exam_date_screen_semantics_test.dart`
adds a real `SemanticsNode`-tree traversal test (not a widget-coordinate
proxy) confirming the exposed order — heading, supporting copy, the
three choices, the date selector when applicable, a validation/save
error when present, then Continue/Retry — plus that choice cards expose
selected/unselected state, the date selector is entirely absent (not
merely hidden) when unscheduled is chosen, the save-failure/stale-date
error is a live region announced exactly once, and Continue exposes its
disabled/loading state correctly. The earlier widget-coordinate check in
`exam_date_screen_test.dart` is kept only as a separate layout-regression
check and is now explicitly labeled as such, not as accessibility
verification. **Manual VoiceOver operation has not been performed and
remains outstanding** — these are automated proxies for it, not a
replacement.

## 3.4 Experience-level screen

- [x] Offer:
  - Just starting
  - Studying already
  - Taking the exam again

  (New `lib/screens/experience_level_screen.dart`, `ExperienceLevelScreen`,
  route `/onboarding/experience-level` — pushed (not replaced) from
  `ExamDateScreen`'s `Continue`, so Back returns there with the exam-date
  selection still visible. Exactly these three mutually-exclusive
  choices, each exposing a full visible label, selected/unselected
  semantics, and a radio icon so selection is never conveyed by color
  alone; none preselected on a fresh install. Evidence:
  `test/screens/experience_level_screen_test.dart` and the real
  `SemanticsNode`-tree traversal in
  `test/screens/experience_level_screen_semantics_test.dart`.)
- [x] Store selection locally.

  (`ExperienceLevel` extracted, unchanged, into its own leaf file —
  `lib/domain/models/experience_level.dart` — reusing the existing
  serialized values (`justStarting`, `studyingAlready`, `retakingExam`;
  no migration needed since nothing changed). `BootstrapLocalStore`
  gained `readExperienceLevel`/`writeExperienceLevel`, implemented in
  both `SharedPreferencesBootstrapLocalStore` (one versioned JSON value
  — `{version, value}`) and `InMemoryBootstrapLocalStore`. `value` is
  produced by an explicit mapping —
  `experienceLevelToStorageValue`/`experienceLevelFromStorageValue` in
  the new `lib/domain/models/experience_level_codec.dart` leaf — not
  `.name`/`.index`/`byName`/enum-order lookup, so a later rename of the
  Dart enum symbol or a reordering of its values cannot silently change
  what's read from or written to existing installs. All three values
  round-trip through the exact expected stored string; an unknown value,
  malformed JSON, or unsupported/missing version all return null safely,
  and a corrupt entry never affects exam date, onboarding, entitlement,
  or theme. The production `DriftUserSettingsRepository` adapter exists
  (PREP-661/662), but nothing here saves through it yet, so this is still
  never routed through a `UserProfile`. Evidence:
  `test/domain/models/experience_level_dependency_test.dart`,
  `test/domain/models/experience_level_codec_test.dart` (exact stored
  strings, unknown-value handling, and source guards proving neither the
  codec nor the persistence adapter uses `.name`/`.index`/`byName`/
  enum-order lookup), and
  `test/bootstrap/shared_preferences_bootstrap_local_store_test.dart`'s
  "experience level" group.)

`ExamDateScreen`'s `Continue` now saves the exam-date selection, updates
the current session, and pushes `ExperienceLevelScreen` — it no longer
writes `onboardingComplete` or routes to `MainShell` itself.
`ExperienceLevelScreen`'s own `Continue` now owns that temporary
completion bridge (persist `onboardingComplete`, clear the onboarding
stack via `pushAndRemoveUntil`, enter `MainShell` with both saved
answers present in the session), isolated to
`_ExperienceLevelScreenState._continue` and documented there as pending
Section 3.5, which replaces only its "on success" branch.

**Session synchronization:** the "current session" above is now one
shared, genuinely-mutable `BootstrapSessionController`
(`lib/bootstrap/bootstrap_session_controller.dart`) — not the
forward-only chain of copied immutable `BootstrapReady` snapshots this
section originally shipped with, which only updated routes navigated to
*after* a save and left any route already underneath (e.g. Exam Date,
once the user had moved on to Experience Level) holding a stale
snapshot. `SplashScreen` creates the controller exactly once per app
session; every onboarding route and `MainShell` forward that same
instance via `BootstrapSessionScope`'s `controllerOf`/`snapshotOf`
accessors, never constructing a new one. A failed write never updates
the controller. This means: saving Exam Date, going to Experience Level,
backing all the way out to Welcome, and starting over reaches a *brand
new* `ExamDateScreen` that still correctly prefills the previously-saved
date — the scenario a forward-only copy could not handle. Evidence:
`test/screens/onboarding_navigation_stack_test.dart`'s "shared session
controller identity and re-entry" group (controller identity across
every route, the full backward-navigation/re-entry scenario, and
experience-level prefill surviving a completion failure), plus its
existing full-flow, session-sync, and route-analytics coverage.

## 3.5 Diagnostic

- [ ] Add diagnostic introduction with question count and approximate time.
- [ ] Generate a blueprint-balanced 10–20 question diagnostic.
- [ ] Use approved questions only.
- [ ] Cover every configured domain.
- [ ] Do not show explanations until the diagnostic is complete.
- [ ] Persist in-progress answers.
- [ ] Calculate initial readiness from actual performance.

**Blocked pending human-approved content inventory.** The mandatory
approved-content preflight (attempted before any engine work) found zero
`approved` questions in any of the three configured domains — only
`rhs-dev-001`/`rhs-dev-002` exist, both `draft`, and `infection_control` has
no questions at all. A 15-question blueprint-balanced diagnostic needs at
least 7/4/4 approved questions across `purpose_technique`/
`radiation_protection`/`infection_control` respectively; see
`content_workbench/danb_rhs/content_inventory.md` for the full gate result
and per-domain gap. A follow-up task built the unbundled content-authoring
workbench (`content_workbench/danb_rhs/`), authoring guide, review
checklist, approval workflow, and a structural validator
(`tool/validate_candidate_questions.dart`) — but drafting candidate
questions was also withheld, because the repository contains no
authoritative source material (no bundled DANB RHS outline document, no
CDC/FDA/ADA guidance, no textbook) for any domain beyond the existing
domain/topic/weight structure, which alone is insufficient for factual
questions. Section 3.5 implementation begins only once a qualified human
reviewer supplies real source material, candidate questions are drafted and
reviewed against it, and at least 7/4/4 approved questions are promoted
into `assets/content/danb_rhs/content.json`.

A narrow correction pass hardened the workbench itself (still no
questions drafted, no Section 3.5 checkbox touched): reviewer approvals
are now bound to content via SHA-256 over deterministic canonical JSON
(`sha256-canonical-json-v1`, domain-separated), replacing an earlier
FNV-1a fingerprint that wasn't collision-resistant enough for this
purpose — a decision recorded under any other or missing algorithm is
treated as unsupported/legacy and requires renewed review, never silently
accepted. Source-document handling was corrected to a safe policy:
licensed/restricted material must never be committed to this repository
merely to support authoring (a citation is not proof of redistribution
rights) — it stays in the reviewer's own authorized storage, optionally
mirrored locally in the git-ignored `content_workbench/private_sources/`;
only genuinely redistributable public documents may be committed, as a
deliberate per-document decision. `tool/validate_candidate_questions.dart`
gained a `--require-ready` mode that evaluates the actual *bundled*
production content (not the workbench) for the configured approved-inventory
allocation, exiting `2` specifically when validation succeeds but bundled
approved inventory is insufficient — currently the case, honestly.

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

- [x] Implement `ContentRepository`. (`BundledContentRepository`.)
- [x] Implement `ProgressRepository`. (`DriftProgressRepository`, PREP-661/662.)
- [x] Implement `UserSettingsRepository`. (`DriftUserSettingsRepository`, PREP-661/662.)
- [x] Add in-memory fakes for tests. (`InMemoryContentRepository`,
  `InMemoryProgressRepository`, `InMemoryUserSettingsRepository`.)
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
