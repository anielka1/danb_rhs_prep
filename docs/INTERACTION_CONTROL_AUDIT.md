# Interaction Control Audit

Every `IconButton`/button/switch/segmented control/`InkWell`/`GestureDetector`/
tappable card/navigation item/dialog action in `lib/screens` and
`lib/widgets`, as re-verified for **PREP-652** against the actual current
code (not the prior version of this document, which predated PREP-648
through PREP-651 and had gone stale on several rows — see "PREP-652
changes" below). Status is verified in code (and, where noted, by a test)
— nothing here is asserted from visual inspection alone.

Statuses: **Working** (does what it visibly claims), **Partially working**
(navigates/responds, but the effect doesn't fully match its label),
**No-op** (found with an empty callback, or a `setState`-only bool nothing
else read, and no other effect), **Disabled** (reachable, but the feature
behind it doesn't exist yet, so it's made properly non-interactive and
excluded from accessibility), **Fixed → Working** (a control that used to
be a no-op or partially working and now has a real implementation),
**Removed** (the control, or the screen containing it, no longer exists).

## PREP-652 changes

A fresh sweep of `lib/screens` and `lib/widgets` found **zero** currently
reachable no-op controls: every control is either genuinely working or
properly disabled with a doc comment explaining why. The only no-op-shaped
controls left anywhere in the codebase belonged to `LoginScreen` — three
disabled auth buttons (Forgot Password, Google, Apple sign-in) inside a
screen that had been fully unreachable from production navigation since
PREP-645 (no route registered it, nothing else constructed it). Since the
screen could never be reached at all, "disable and wait for the feature"
made no sense — **`lib/screens/login_screen.dart` was deleted outright**,
along with every reference to it (5 test files updated;
`test/screens/accountless_no_login_test.dart` now asserts the file and
every reference to it stay gone).

Also added: an end-to-end smoke test
(`test/end_to_end_smoke_test.dart`) walking onboarding → Home → Practice
(answer every question in the real, possibly-resumed session) → feedback
→ Summary → Progress, plus a separate Mock Exam + Settings smoke test —
both driven through the real `lib/main_demo.dart` composition root, the
same way an actual accountless user would use the app. This is the first
test that exercises the *entire* clickable chain continuously rather than
one screen/flow at a time; both passed against the current code with no
behavioral defect found, confirming the milestone's controls genuinely
connect end to end.

Several rows below describe controls that PREP-648–651 already fixed
(their PracticeQuestionScreen/AnswerExplanationScreen/MockExamScreen
rework) or changed the navigation mechanism of (named routes replaced
with direct `MaterialPageRoute` pushes carrying real content/repository
values, since a screen reached via the static route table cannot see the
ambient `BootstrapSessionScope` a tab can) — those are marked below.

## Summary counts

**Before PREP-652:** 14 no-op controls existed at the time of the prior
audit; by the time of this one, 3 of those (`PracticeQuestionScreen`
Submit Answer's evaluation, Previous/Next, and
`AnswerExplanationScreen`'s "Next Question") had already been fixed to
**Working** by PREP-649's practice-session rework, and 3 controls this
document previously listed no longer exist at all (`ProfileSettingsScreen`
"Sign Out", `MockExamResultsScreen` "Review Answers" and "Retake Exam" —
removed by PREP-645/650 respectively). **PREP-652 itself removes 3 more**
(`LoginScreen`'s Forgot Password, Google, and Apple sign-in) by deleting
the unreachable screen that contained them. That leaves **8 disabled
no-op-shaped controls**, all reachable, all with a real future feature and
an explicit doc comment: `HomeScreen`'s floating "+" button,
`AnswerExplanationScreen`'s bookmark icon, `PracticeSummaryScreen`'s
"Review Mistakes", and `ProfileSettingsScreen`'s Push Notifications
switch, Sound Effects switch, "Edit Profile", and "Change Password".

| Screen | Control | Current behavior | Status | Intended behavior | Roadmap phase |
| --- | --- | --- | --- | --- | --- |
| SplashScreen | *(none)* | Bootstrap-driven; navigates once bootstrap resolves | Working | — | 2.3 (done) |
| HomeScreen | Settings toolbar icon | `pushNamed(ProfileSettingsScreen.route)` | Working | — | 2.3 (done) |
| HomeScreen | Week-strip day buttons (×7) | `setState` changes the selected day | Working | — | 2.3 (done) |
| HomeScreen | "Continue" / "Start Practicing" (study-tasks card) | `Navigator.push(MaterialPageRoute)` into `ExamOverviewScreen` with the real content package + progress repository — label reflects whether `ProgressRepository.inProgressPracticeSession` finds a real in-progress session | Working (tested) | — | 2.3 (done); label logic added by PREP-648 |
| HomeScreen | Floating "+" action button | `onPressed: null`, documented | Disabled | No defined feature or roadmap phase found for this affordance | Unclear — flagged for a product decision |
| MainShell | Home / Practice / Mock Exam / Progress tabs | `AppBottomNavigation` → `_onTabSelected`, switches the `IndexedStack` index | Working (tested) | — | 2.3 (done). "Practice" tab now renders `ExamOverviewScreen` directly (PREP-649), not a separately pushed route |
| ExamOverviewScreen | Back icon | `Navigator.maybePop()` | Working | — | 2.3 (done) |
| ExamOverviewScreen | "Start Practice Exam" | Creates or resumes a real `PracticeSession` via the injected `ProgressRepository`/content package, pushes `PracticeQuestionScreen` scoped to a real `PracticeSessionController` | Working (tested) | — | Fixed by PREP-649 |
| PracticeQuestionScreen | Close icon | `Navigator.maybePop()` | Working | — | 2.3 (done) |
| PracticeQuestionScreen | Answer option tiles | `setState` tracks the pending selection before submit; disabled/read-only for an already-answered question reached via Previous | Working | — | 2.3 (done) |
| PracticeQuestionScreen | "Submit Answer" / "View Explanation" | Calls `PracticeSessionController.submitAnswer`, which evaluates the tapped option against the real correct answer, before navigating to a scoped `AnswerExplanationScreen` | **Fixed → Working** (tested) | — | Fixed by PREP-649 (previously **Partially working**: navigated but never evaluated the answer) |
| PracticeQuestionScreen | Previous / Next | `controller.moveTo(...)`, gated by `canGoToPrevious`/`canGoToNext` — real multi-question session navigation | **Fixed → Working** (tested) | — | Fixed by PREP-649 (previously **No-op → Disabled**) |
| AnswerExplanationScreen | Back icon | `Navigator.maybePop()` | Working | — | 2.3 (done) |
| AnswerExplanationScreen | Bookmark icon | `onPressed: null`, documented | Disabled | Toggle `QuestionState.bookmarked` via `ProgressRepository` | A real `examId`/`questionId` exists here now (PREP-649); wiring the toggle itself is a separate, undescoped feature, not a control fix |
| AnswerExplanationScreen | "Next Question" / "Finish" | `controller.moveTo(index+1)` + push a fresh `PracticeQuestionScreen`, or — on the last question — `controller.complete()` + navigate to `PracticeSummaryScreen` | **Fixed → Working** (tested) | — | Fixed by PREP-649 (previously **Partially working**: dismissed rather than advancing) |
| PracticeSummaryScreen | "Review Mistakes" | `onPressed: null`, documented | Disabled | Show missed questions from the completed session | Needs its own review screen/flow — undescoped |
| PracticeSummaryScreen | "Back to Home" | `Navigator.popUntil` back to the existing `MainShell` route (not `pushNamedAndRemoveUntil`, which would re-enter through the static route table with no `BootstrapSessionScope` ancestor) | Working (tested) | — | Mechanism fixed by PREP-649 (found while wiring real session state) |
| MockExamScreen | Loading / failed / unavailable states | `MockExamController.load()`; `ErrorState`'s "Try Again" retries; the unavailable state's "View Exam Info" opens a real `ExamOverviewScreen` | Working (tested) | — | Added by PREP-650 |
| MockExamScreen | "Start Mock Exam" / "Resume Mock Exam" | Pushes the real mock-exam instructions screen for the loaded `MockExamController` | Working (tested) | — | Added by PREP-650 |
| MockExamScreen (instructions) | "Begin exam" / "Resume exam" / "Try Again" | `controller.start()` then pushes `MockExamQuestionScreen`; back is disabled while busy | Working (tested) | — | Added by PREP-650 |
| MockExamQuestionScreen | Answer option tiles | `controller.answer(...)`; disabled only when the timer has expired | Working (tested) | — | Added by PREP-650 |
| MockExamQuestionScreen | "Flag question" / "Remove flag" | `controller.toggleFlag()` | Working (tested) | — | Added by PREP-650 |
| MockExamQuestionScreen | "Previous question" / "Next question" / question-navigator grid | `controller.moveTo(index)`, gated by `canMoveTo` (respects the configured back-navigation rule); non-actionable grid items carry no tap semantics | Working (tested) | — | Added by PREP-650 |
| MockExamQuestionScreen | "Finish mock exam" | Confirmation dialog (unanswered-question warning), then `controller.finish()` | Working (tested) | — | Added by PREP-650 |
| MockExamQuestionScreen | Exit icon | `Navigator.pop()`, disabled while a save is pending | Working (tested) | — | Added by PREP-650 |
| MockExamResultsScreen | Back icon | Rendered only `if (canPop)`; `Navigator.pop()` | Working (tested) | — | Mechanism changed by PREP-650 |
| MockExamResultsScreen | "Back to Mock Exam" | `Navigator.pop()` | Working (tested) | — | Added by PREP-650 |
| ProgressScreen | "Start Practicing" (empty state) / "Practice More" | `Navigator.push(MaterialPageRoute)` into `ExamOverviewScreen` with real content/repository | Working (tested) | — | 2.3 (done); "Practice More" added by PREP-651 |
| ProgressScreen | Error state "Try Again" | Retries the load; a `_loading` guard prevents a second concurrent load from a rapid repeat tap | Working (tested) | — | Added by PREP-651 |
| ProfileSettingsScreen | Back icon | `Navigator.maybePop()` | Working | — | 2.3 (done) |
| ProfileSettingsScreen | Push Notifications switch | `onChanged: null`, documented | Disabled | Real notification permission + scheduling | Later phase (not yet in roadmap) |
| ProfileSettingsScreen | Appearance selector | System/Light/Dark, app-wide, immediate | Working (tested) | — | 2.4 (done) |
| ProfileSettingsScreen | Sound Effects switch | `onChanged: null`, documented | Disabled | Real audio-feedback system | Later phase (not yet in roadmap) |
| ProfileSettingsScreen | "Edit Profile" | `onTap: null`, documented | Disabled | Account management | Phase 4 (auth) |
| ProfileSettingsScreen | "Change Password" | `onTap: null`, documented | Disabled | Account management | Phase 4 (auth) |
| `AppDialog` (Material + Cupertino) | Dialog actions | `Navigator.pop(action.value)` | Working (tested) | — | 2.2 (done) |
| `ReadinessCard` | "View Details" | Calls caller-supplied `onViewDetail` | Working when a screen supplies one | Not currently mounted on any screen | Progress phase (not yet built) |
| `SubscriptionProductCard` | Card tap (`onSelect`) | Calls caller-supplied `onSelect` | Working when a screen supplies one; card itself never imports StoreKit | Not currently mounted on any screen | Phase 5 (subscriptions/StoreKit) |

## Notes

- **`LoginScreen` — removed entirely (PREP-652).** It was unreachable from
  any real navigation path since PREP-645 (no registered route, nothing
  else constructed it) yet still carried three disabled no-op-shaped
  controls. Since the whole screen could never be reached, keeping it
  "disabled and waiting for a feature" no longer made sense — it was
  deleted, along with every reference to it. See
  `test/screens/accountless_no_login_test.dart`.
- **"Removed" vs "Disabled"**: every other no-op found (in this and the
  prior audit) maps to a real, reachable screen and a plausible future
  feature, so disabling (not removing) remains correct for those —
  `LoginScreen` is the only case where the *entire screen*, not just one
  control, was unreachable.
- Controls already covered by the Section 2.3/2.4 navigation and
  accessibility work (tab bar, Settings/back navigation, dialog actions)
  are listed here for completeness but were not re-touched.
