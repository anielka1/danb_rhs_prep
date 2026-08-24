# Prototype Content Audit

Scope: every screen that is currently **reachable** by a real navigation
path from app launch, per the Phase 2 exit-criteria task. Reachability was
checked by grepping every `.pushNamed`/`.pushReplacementNamed`/
`.pushNamedAndRemoveUntil` call site for each screen's route, not just its
registration in `main.dart`'s route table.

`PracticeSummaryScreen` and `MockExamResultsScreen` are registered in the
route table but have **zero** real navigation consumers anywhere in
`lib/` — nothing currently pushes their routes. They are listed here for
completeness (their content is prototype-only) but are out of scope for
the "no final screen depends on prototype-only content" exit criterion,
since a user cannot currently reach them. Wiring them up is Phase 6/8
work (real practice-session and mock-exam engines), at which point their
content must be revisited.

| Screen | Content/data | Current source | Acceptable static UI copy? | Prototype-only? | Required production source | Roadmap phase | Action |
|---|---|---|---|---|---|---|---|
| SplashScreen | "DANB RHS Prep" title, "Ace Your Radiation Health and Safety Exam" tagline | Hardcoded string | Yes — final app branding/tagline | No | n/a | n/a | None needed |
| LoginScreen | "Welcome to DANB RHS Prep" heading, "Log In"/"Sign Up" toggle, field labels, "or connect with" | Hardcoded string | Yes — stable interface copy | No | n/a | n/a | None needed |
| LoginScreen | Email/password field values | Was hardcoded to `dental.assistant@danb.org` / `password123` (fake pre-filled credentials, implying a signed-in identity that was never authenticated) | No | Yes | Real authentication (Phase 3) | Phase 3 | **Fixed in this task**: fields now start empty |
| LoginScreen | Email field hint text (`dental.assistant@danb.org`) | Hardcoded string | Yes — an example-format hint, not a claim about a real account | No | n/a | n/a | None needed |
| LoginScreen | Branding text was "Welcome to PrepMaster" (inconsistent with the app's actual name, used everywhere else) | Hardcoded string | N/A — not fake data, but inconsistent/incorrect static copy | No | n/a | n/a | **Fixed in this task**: corrected to "Welcome to DANB RHS Prep" |
| LoginScreen | Forgot Password / Google / Apple sign-in | No-op controls | — | — | Real auth backend | Phase 3 | Already disabled (Task 2); not a content issue, tracked in `docs/INTERACTION_CONTROL_AUDIT.md` |
| MainShell / AppBottomNavigation | "Home", "Practice", "Mock Exam", "Progress" tab labels | Hardcoded strings | Yes — final navigation labels | No | n/a | n/a | None needed |
| HomeScreen | "Today" header, date | Was a hardcoded fixed date | No | Yes | System clock (no repository needed) | n/a | **Fixed in this task**: now `DateTime.now()`-derived, always correct |
| HomeScreen | Week-strip day selector | Derived from `DateTime.now()` | Yes | No | n/a | n/a | None needed |
| HomeScreen | Daily task/schedule cards ("Complete Chapter 5 Quiz", "Weekly Mock Exam #3", etc.) | Was hardcoded fake schedule data presented as the user's real plan | No | Yes | Study-planning repository (not yet designed) | Unscheduled / Phase 6+ | **Fixed in this task**: replaced with an honest `EmptyState` ("No study tasks yet") with a working "Start Practicing" action |
| HomeScreen | Quick-add floating action button | No-op control | — | — | Undefined feature | Undefined | Already disabled (Task 2) |
| ProfileSettingsScreen | "Sarah Jenkins" / "sarah.j@dentalprep.com" | Was hardcoded fake identity | No | Yes | Real authentication/profile (Phase 3) | Phase 3 | **Fixed in this task**: replaced with honest "Guest" / "Not signed in" |
| ProfileSettingsScreen | Rank / Study Hours / Exams Taken stat values | Was hardcoded fake numbers ("#12", "47h", "23") presented as the current user's real stats | No | Yes | Progress-tracking repository (Phase 5/6) | Phase 5/6 | **Fixed in this task**: replaced with an honest "not yet available" placeholder (`—` visually, full sentence via semantics) |
| ProfileSettingsScreen | Appearance selector (System/Light/Dark) | Real `ThemeModeController`, wired to `MaterialApp.themeMode` | Yes — real, working feature | No | n/a | n/a | Fixed in Task 2; verified again here |
| ProfileSettingsScreen | Push Notifications / Sound Effects toggles, Edit Profile / Change Password | No-op controls | — | — | Notification/audio/auth systems | Various later phases | Already disabled (Task 2) |
| ExamOverviewScreen | "Practice Exam Prep", "About Certification" body copy | Hardcoded string | Yes — final educational/explanatory copy | No | n/a | n/a | None needed |
| ExamOverviewScreen | "1.5 Hours · 100 Questions · Intermediate" | Hardcoded string presented as the real exam's specs | No | Yes | Real content package / exam blueprint (only 2 draft sample questions currently exist in `assets/content/danb_rhs/content.json`) | Phase 6 (content authoring) | **Deferred**: left as a documented placeholder; wiring real counts requires the content package to be complete, out of this task's scope |
| ExamOverviewScreen | Topic list names and per-topic question counts | Hardcoded string, mirrors the real exam blueprint's domain/topic names but with invented counts | No | Yes | Real content package | Phase 6 | **Deferred**, same reasoning as above |
| ExamOverviewScreen | Per-topic locked/unlocked icon | Was a hardcoded fake progression gate (3 of 5 topics "locked") with no backing unlock system | No | Yes | A real progression/unlock system (not yet designed) | Unscheduled | **Fixed in this task**: removed the fake lock/check icons; every topic now shows the same neutral icon |
| PracticeQuestionScreen | Question text, 4 answer options, "QUESTION 12 OF 100" | Hardcoded single fake question, fake position-in-set | No | Yes | Real content package + a practice-session engine (Phase 6) | Phase 6 | **Deferred**: two real draft sample questions exist in `content.json`, but wiring them in requires new async content-loading infrastructure and would still leave fake session-progress chrome around them — a content/engine change beyond this task's control-level scope. Classified unfinished. |
| PracticeQuestionScreen | Timer ("24:18") | Hardcoded, static (does not run) | No | Yes | Real timed-session engine | Phase 6/8 | **Deferred**, same reasoning |
| PracticeQuestionScreen | Previous / Next question controls | No-op controls | — | — | Multi-question session engine | Phase 6 | Already disabled (Task 2) |
| AnswerExplanationScreen | Question text, answer options, "Correct Explanation" body text | Hardcoded, matches the same fake question as `PracticeQuestionScreen` | No | Yes | Real content package | Phase 6 | **Deferred**, same reasoning as `PracticeQuestionScreen` |
| AnswerExplanationScreen | Bookmark action | No-op control | — | — | Real `examId`/`questionId` to bookmark against | Phase 6 | Already disabled (Task 2); `ProgressRepository`/`QuestionState.bookmarked` exist at the repository layer but this screen has no real question identity to attach to |
| MockExamScreen | "Mock Exam" / "coming soon" empty state | Real `EmptyState` component, no fabricated data | Yes — an honest unavailable state | No | n/a | n/a | Already fixed (earlier accessibility session); re-verified in this task |
| ProgressScreen | "Your Progress" header | Hardcoded string | Yes | No | n/a | n/a | None needed |
| ProgressScreen | Weekly activity chart, accuracy/streak stats, weekly goal, subject-mastery rows | Was hardcoded fake numbers presented as the user's real activity | No | Yes | Progress-tracking repository (only an in-memory fake exists today, meant for tests) | Phase 5/6 | **Fixed in this task**: entire body replaced with an honest `EmptyState` ("No progress yet") with a working "Start Practicing" action |
| PracticeSummaryScreen *(not currently reachable)* | "Session Complete!", 78% score, 42m time spent, per-topic breakdown percentages | Hardcoded fake results | No | Yes | Stored practice-attempt data | Phase 6 | **Deferred, unreachable**: not modified — no real navigation currently reaches this screen, so it is out of this task's "reachable screen" scope. Must be revisited before it is ever wired up (Phase 6/8), not left in its current fake-data form. |
| PracticeSummaryScreen *(not currently reachable)* | "Review Mistakes" control | No-op control | — | — | Stored attempt/answer data | Phase 6 | Already disabled (Task 2) |
| MockExamResultsScreen *(not currently reachable)* | "82%" score, PASSED badge, time taken, per-section performance | Hardcoded fake results | No | Yes | Stored mock-exam attempt data | Phase 8 | **Deferred, unreachable**: same reasoning as `PracticeSummaryScreen` |
| MockExamResultsScreen *(not currently reachable)* | "Review Answers" control | No-op control | — | — | Stored attempt/answer data | Phase 8 | Already disabled (Task 2) |
| `ReadinessCard` / `SubscriptionProductCard` widgets | Score/band/product/price values | Not currently instantiated by any screen — both take their values as required constructor parameters from the caller, with no built-in fake data of their own | Yes (components, not screens) | No (dormant) | n/a until a screen uses them | n/a | No action — flagged so a future screen that adopts these components supplies real data from day one, rather than prototype numbers |

## Summary

- **Fixed in this task** (real data or an honest empty/unavailable state,
  no new persistence): `HomeScreen` (date + schedule), `ProfileSettingsScreen`
  (identity + stats), `ProgressScreen` (entire stats body), `ExamOverviewScreen`
  (removed fake topic lock/unlock), `LoginScreen` (removed fake pre-filled
  credentials, fixed branding-name inconsistency).
- **Deferred — reachable but still prototype-only content**: `ExamOverviewScreen`'s
  exam specs and per-topic question counts; `PracticeQuestionScreen` and
  `AnswerExplanationScreen`'s hardcoded question/answer/explanation and
  session chrome. All require Phase 6 content-package and/or
  practice-engine work outside this task's scope (no business logic was
  implemented, per the task's explicit constraints).
- **Deferred — currently unreachable, so out of this criterion's scope**:
  `PracticeSummaryScreen`, `MockExamResultsScreen`. Both still contain
  fabricated results and must not be wired into real navigation until
  they show real attempt data (Phase 6/8).

**Conclusion**: because `ExamOverviewScreen`, `PracticeQuestionScreen`, and
`AnswerExplanationScreen` are reachable today and still depend on
prototype-only content that this task could not honestly resolve without
Phase 6 business logic, the roadmap exit criterion "No final screen
depends on prototype-only content" is **not met** and is left unchecked.
