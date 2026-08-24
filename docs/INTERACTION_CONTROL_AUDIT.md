# Interaction Control Audit

Every `IconButton`/button/switch/segmented control/`InkWell`/`GestureDetector`/
tappable card/navigation item/dialog action in `lib/screens` and
`lib/widgets`, as of the accessibility-follow-up task. Status is verified in
code (and, where noted, by a test) — nothing here is asserted from visual
inspection alone.

Statuses: **Working** (does what it visibly claims), **Partially working**
(navigates/responds, but the effect doesn't fully match its label — e.g. a
"Retake"/"Next" action that dismisses rather than genuinely repeating/
advancing), **No-op** (found with an empty callback, or a `setState`-only
bool nothing else read, and no other effect), **Disabled** (the fix applied
to every no-op found: reachable, but the feature behind it doesn't exist
yet, so it's made properly non-interactive and excluded from
accessibility — except one, see below), **Fixed → Working** (the one no-op
that *did* get a real implementation instead of being disabled), **Future
feature** (not yet reachable from any screen at all), **Remove** (none
found — nothing was dead code with no plausible future use).

## Summary counts

**14 no-op controls were found** (empty callback or an unread `setState`
bool): 13 were disabled, and 1 — the "Dark Mode" switch — was given a real
implementation (the System/Light/Dark selector) instead, since app-wide
theming is a completed Phase 2.1 feature that just needed wiring, unlike
the other 13 which all depend on Phase 3+ business logic (auth, practice/
mock engines, progress persistence) or an undefined feature. A prior
version of this task's report undercounted this as "11" by only tallying
the empty-callback (`() {}`) cases and missing the 3 unread-`setState`-bool
cases (Push Notifications, Dark Mode, Sound Effects) from the same count;
14 is the correct total. Separately, 3 controls were found **Partially
working** (real navigation, but the effect doesn't match the label) — see
the table below.

| Screen | Control | Current behavior | Status | Intended behavior | Roadmap phase |
| --- | --- | --- | --- | --- | --- |
| SplashScreen | *(none)* | 2s timer auto-navigates to MainShell | Working | — | 2.3 (done) |
| LoginScreen | Close icon | `Navigator.maybePop()` | Working | — | 2.3 (done) |
| LoginScreen | Log In / Sign Up segmented toggle | `setState` swaps which segment is visually selected; form fields below are identical either way | Working | Segment selection is the only claimed behavior; distinct sign-up fields belong with real auth | Phase 4 (auth) |
| LoginScreen | Password visibility icon | `setState` toggles `obscureText` | Working (has a real, visible effect) | — | 2.3 (done) |
| LoginScreen | "Forgot Password?" | was `onPressed: () {}` | **No-op → Disabled** | Password reset flow | Phase 4 (auth) |
| LoginScreen | "Get Started" | `pushReplacementNamed(MainShell.route)` | Working | Prototype login proceeds into the app; no real credential check | Phase 4 (auth) |
| LoginScreen | Google sign-in | was `onPressed: () {}` | **No-op → Disabled** | Google OAuth | Phase 4 (auth) |
| LoginScreen | Apple sign-in | was `onPressed: () {}` | **No-op → Disabled** | Sign in with Apple | Phase 4 (auth) |
| HomeScreen | Settings toolbar icon | `pushNamed(ProfileSettingsScreen.route)` | Working | — | 2.3 (done) |
| HomeScreen | Week-strip day buttons (×7) | `setState` changes the selected day | Working | — | 2.3 (done) |
| HomeScreen | "Start Practicing" (in the "No study tasks yet" empty state) | `pushNamed(ExamOverviewScreen.route)` | Working | — | 2.3 (done). Replaced the prior "Mock Exam Session" fake-schedule card during the Phase 2 prototype-content audit — see `docs/PROTOTYPE_CONTENT_AUDIT.md` |
| HomeScreen | Floating "+" action button | was `onPressed: () {}` | **No-op → Disabled** | No defined feature or roadmap phase found for this affordance | Unclear — flagged for a product decision |
| MainShell | Home / Practice / Mock Exam / Progress tabs | `AppBottomNavigation` → `_onTabSelected`, switches the `IndexedStack` index | Working (tested) | — | 2.3 (done) |
| ExamOverviewScreen | Back icon | `Navigator.maybePop()` | Working | — | 2.3 (done) |
| ExamOverviewScreen | "Start Practice Exam" | `pushNamed(PracticeQuestionScreen.route)` | Working | — | 2.3 (done) |
| PracticeQuestionScreen | Close icon | `Navigator.maybePop()` | Working | — | 2.3 (done) |
| PracticeQuestionScreen | Answer option tiles (×4) | `setState` changes the selected option | Working | — | 2.3 (done) |
| PracticeQuestionScreen | "Submit Answer" | `pushNamed(AnswerExplanationScreen.route)` | **Partially working** | Navigates, but doesn't evaluate the tapped option — the review screen it opens shows fixed, hardcoded correct/incorrect state unrelated to what was tapped here | Phase 6 (practice engine) |
| PracticeQuestionScreen | Previous | was `onPressed: () {}` | **No-op → Disabled** | Move to the prior question in a session | Phase 6 (practice engine — no multi-question session exists yet) |
| PracticeQuestionScreen | Next | was `onPressed: () {}` | **No-op → Disabled** | Move to the next question in a session | Phase 6 (practice engine) |
| AnswerExplanationScreen | Back icon | `Navigator.maybePop()` | Working | — | 2.3 (done) |
| AnswerExplanationScreen | Bookmark icon | was `onPressed: () {}` | **No-op → Disabled** | Toggle `QuestionState.bookmarked` via `ProgressRepository` | Phase 6/7 (progress persistence) — infra exists at the repository layer, but this screen has no real `examId`/`questionId` to bookmark against (its content is entirely hardcoded); wiring requires this screen to carry a real `Question`, not just a control fix |
| AnswerExplanationScreen | "Next Question" | `Navigator.maybePop()` | **Partially working** | Dismisses back to the practice screen rather than genuinely advancing to another question | Phase 6 (practice engine) |
| PracticeSummaryScreen | "Review Mistakes" | was `onPressed: () {}` | **No-op → Disabled** | Show missed questions from the completed session | Phase 6/7 (needs stored attempt data) |
| PracticeSummaryScreen | "Back to Home" | `pushNamedAndRemoveUntil(MainShell.route)` | Working | — | 2.3 (done) |
| MockExamResultsScreen | Back icon | `Navigator.maybePop()` | Working | — | 2.3 (done) |
| MockExamResultsScreen | "Review Answers" | was `onPressed: () {}` | **No-op → Disabled** | Show the full answer review for the completed attempt | Phase 8 (mock exam engine) |
| MockExamResultsScreen | "Retake Exam" | `Navigator.maybePop()` | **Partially working** | Dismisses rather than starting a genuinely new attempt | Phase 8 (mock exam engine) |
| MockExamScreen | "View Exam Info" | `pushNamed(ExamOverviewScreen.route)` | Working (honest placeholder, from prior accessibility work) | — | 2.3 (done) |
| ProgressScreen | "Start Practicing" (in the "No progress yet" empty state) | `pushNamed(ExamOverviewScreen.route)` | Working | — | 2.3 (done). Added during the Phase 2 prototype-content audit, replacing a fully non-interactive fake-stats display — see `docs/PROTOTYPE_CONTENT_AUDIT.md` |
| ProfileSettingsScreen | Back icon | `Navigator.maybePop()` | Working | — | 2.3 (done) |
| ProfileSettingsScreen | Push Notifications switch | was `setState`-only, nothing else read the bool | **No-op → Disabled** | Real notification permission + scheduling | Later phase (not yet in roadmap) |
| ProfileSettingsScreen | Appearance selector | was a "Dark Mode" `Switch` that only set a local, unused bool | **Fixed → Working** (tested) | System/Light/Dark, app-wide, immediate | 2.4 (this task) |
| ProfileSettingsScreen | Sound Effects switch | was `setState`-only, nothing else read the bool | **No-op → Disabled** | Real audio-feedback system | Later phase (not yet in roadmap) |
| ProfileSettingsScreen | "Edit Profile" | was `onTap: () {}` | **No-op → Disabled** | Account management | Phase 4 (auth) |
| ProfileSettingsScreen | "Change Password" | was `onTap: () {}` | **No-op → Disabled** | Account management | Phase 4 (auth) |
| ProfileSettingsScreen | "Sign Out" | `pushNamedAndRemoveUntil(LoginScreen.route)` | Working | — | 2.3 (done) |
| `AppDialog` (Material + Cupertino) | Dialog actions | `Navigator.pop(action.value)` | Working (tested) | — | 2.2 (done) |
| `ReadinessCard` | "View Details" | Calls caller-supplied `onViewDetail` | Working when a screen supplies one | Not currently mounted on any screen | Progress phase (not yet built) |
| `SubscriptionProductCard` | Card tap (`onSelect`) | Calls caller-supplied `onSelect` | Working when a screen supplies one; card itself never imports StoreKit | Not currently mounted on any screen | Phase 5 (subscriptions/StoreKit) |

## Notes

- **"Remove"** status: none found. Every no-op control maps to a real,
  plausible future feature (or, for the Home FAB, at least a real
  affordance a product decision could assign a feature to) — nothing was
  dead code safe to delete outright.
- Controls already covered by the Section 2.3/2.4 navigation and
  accessibility work (tab bar, Settings/back navigation, dialog actions)
  are listed here for completeness but were not re-touched.
