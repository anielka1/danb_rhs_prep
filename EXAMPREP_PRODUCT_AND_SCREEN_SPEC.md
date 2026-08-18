# ExamPrep Product & Screen Specification

## Purpose

This document is the product source of truth for `danb_rhs_prep`.

The app is a Flutter exam-preparation product for the DANB Radiation Health and Safety (RHS) exam, designed so the same core can later support additional professional exams.

Core promise:

> **Know when you're ready to pass.**

The experience should feel calm, trustworthy, fast, and professional. It should be simpler than large exam-prep competitors and should avoid childish gamification, social feeds, avatars, leaderboards, or unnecessary complexity.

---

# 1. Product principles

- iPhone-first mobile UX; Android should remain fully supported through Flutter.
- Four primary areas only: **Home, Practice, Mock Exam, Progress**.
- No mandatory account creation in V1.
- Core studying must work offline after content is available locally.
- Exam-specific behavior comes from configuration and content, not special-case UI code.
- Every score is based on real performance data. Never show random readiness values.
- Never claim the user passed the real official exam.
- Keep one obvious primary action per screen.
- Avoid unnecessary modal interruptions while studying.
- Support light mode, dark mode, large text, accessible contrast, and large tap targets.

---

# 2. Current repository notes

The existing Flutter project already contains visual prototypes for Splash/Login/Home/Exam Overview/Practice Question/Answer Explanation/Practice Summary/Mock Results/Progress/Profile Settings.

The current implementation contains hardcoded values and placeholder navigation. These screens should be treated as a visual starting point, not as the final data architecture.

Important product corrections for the next implementation phase:

- Replace the current mandatory login-first concept with onboarding-first local usage.
- Replace the existing bottom navigation `Home / Practice / Stats / Profile` with `Home / Practice / Mock Exam / Progress`.
- Move Settings/Profile to a secondary destination rather than a main tab.
- Replace hardcoded dates, questions, statistics, mastery percentages, timers, and topic locks with real state.
- Keep the current warm cream/periwinkle visual direction unless design review intentionally changes it.

---

# 3. Global navigation

```text
APP LAUNCH
|
+-- First use
|   +-- Welcome
|       +-- Exam Date
|           +-- Experience Level
|               +-- Diagnostic Intro
|                   +-- Diagnostic Quiz
|                       +-- Diagnostic Result
|                           +-- Main App
|
+-- Returning user
    +-- Main App
        +-- Home
        +-- Practice
        +-- Mock Exam
        +-- Progress
```

Secondary destinations:

- Settings
- Readiness Detail
- Domain Detail
- Topic Detail
- Incorrect Questions
- Bookmarks
- Weak Areas
- Custom Quiz
- Mock Attempt Detail
- Paywall
- Report Question

---

# 4. Screen-by-screen specification

## 4.1 Splash / App Bootstrap

### Purpose
Prepare local content and user state before deciding what to show.

### UI
- centered brand mark or app name
- subtle loading indicator only if loading is noticeable

### Logic
- load exam config
- load local question bank
- validate content
- load local profile/progress
- refresh subscription entitlement
- decide whether onboarding is complete

### Navigation
- onboarding incomplete -> Welcome
- onboarding complete -> Home
- content failure -> recoverable Content Error state

---

## 4.2 Welcome

### UI
- exam name, e.g. `DANB RHS Exam Prep`
- headline: **Know when you're ready to pass.**
- short supporting text
- primary CTA: **Start Preparing**

### Secondary actions
- none required in V1

### Navigation
- Start Preparing -> Exam Date

---

## 4.3 Exam Date

### Headline
**When is your exam?**

### Options
- choose exact date
- choose approximate date
- **I haven't scheduled it yet**

### Primary CTA
**Continue**

### Data saved
- exam date if known
- date precision: exact / approximate / unscheduled

### Used later by
- Home countdown
- study recommendations
- notifications
- urgency messaging

---

## 4.4 Experience Level

### Headline
**Where are you in your preparation?**

### Options
- Just starting
- Studying already
- Taking the exam again

### Primary CTA
**Continue**

### Data saved
- experience level

---

## 4.5 Diagnostic Intro

### UI
- headline: **Let's see where you stand**
- configured number of questions, normally 10-20
- estimated duration
- short explanation that this gives an initial readiness estimate

### Primary CTA
**Start Diagnostic**

### Rule
Diagnostic should sample major domains and use mixed difficulty.

---

## 4.6 Diagnostic Question

### UI
- progress bar
- `Question X of Y`
- question text
- answer options A/B/C/D
- optional bookmark hidden during diagnostic
- primary CTA: **Submit Answer** / **Next** depending on interaction model

### Behavior
- record each answer
- do not show full explanations during diagnostic
- preserve progress if app briefly backgrounds

### Final navigation
- final answer -> Diagnostic Result

---

## 4.7 Diagnostic Result

### Primary content
- large **READINESS SCORE**
- score 0-100%
- readiness label
- domain breakdown
- strongest area
- weakest area
- evidence-confidence note if sample is still small

### Primary CTA
**Start My Study Plan**

### Disclaimer
`Readiness Score is an estimate based on practice performance and does not guarantee passing the official exam.`

### Navigation
- CTA -> Home

---

# 5. Main tabs

The persistent main navigation contains exactly:

1. Home
2. Practice
3. Mock Exam
4. Progress

Settings/Profile is accessed from an icon on Home or Progress.

---

# 6. Home

## Purpose
Immediately answer: **What should I study today?**

## Required content
- exam countdown or `Exam date not scheduled`
- current Readiness Score
- readiness label
- daily goal progress
- streak
- total questions answered
- weakest area
- recommended practice session

## Primary CTA
**Start 10-Minute Practice** or contextual equivalent

## Secondary interactions
- Readiness card -> Readiness Detail
- Weakest Area -> Domain/Topic Detail
- Settings icon -> Settings

## Empty states
If there is not enough evidence:

`Complete more questions to make your readiness estimate more reliable.`

## Important change from current prototype
The current calendar/task-list Home UI may inspire visual styling, but the final Home should center on readiness and today's recommended study action rather than a fake scheduled-day agenda.

---

# 7. Practice Hub

## Sections

### Quick Practice
- 5 Questions
- 10 Questions
- 20 Questions

### Focus
- Weak Areas
- Incorrect Questions
- Bookmarked Questions
- Unseen Questions

### Browse
- Practice by Topic
- Custom Quiz

## Gating
Free users can complete practice up to configured limits. Premium-only actions should present the Paywall only when the user attempts the gated feature.

---

# 8. Practice by Topic

## UI
- domain list
- topic list under each domain
- mastery %
- questions seen / available

## Action
**Practice This Topic**

## Empty state
If a topic has no approved questions, do not offer a start button.

---

# 9. Weak Areas

## UI
Rank weak domains/topics by recent evidence.

For each row show:
- topic/domain name
- mastery or recent accuracy
- short reason, e.g. `3 recent mistakes`

## Primary CTA
**Practice Weak Areas**

## Empty state
`Answer more questions to identify your weak areas.`

---

# 10. Incorrect Questions

## UI
- list of previously missed questions or related topics
- retry action
- bookmark state

## Primary CTA
**Practice Incorrect Questions**

## Mastery rule
A question leaves the active incorrect-priority pool after demonstrated repeated mastery, not simply because the user opens it.

---

# 11. Bookmarks

## UI
- bookmarked approved questions
- topic/domain metadata
- remove bookmark

## CTA
**Practice Bookmarks**

## Empty state
`Bookmark questions while studying to find them here.`

---

# 12. Unseen Questions

Questions with no prior view/attempt history.

## CTA
**Practice Unseen Questions**

---

# 13. Custom Quiz Setup

## Controls
- question count
- domains
- topics
- optional difficulty
- unseen only
- incorrect only
- bookmarked only

## Validation
Prevent impossible filter combinations and counts above available questions.

## Primary CTA
**Start Quiz**

---

# 14. Practice Question

## Required UI
- close/back control
- progress indicator
- question number
- optional session timer, only when useful
- question text
- answer choices A/B/C/D
- bookmark action
- Report Problem action
- primary CTA: **Submit Answer**

## Interaction
- one selected answer
- submitting records the attempt
- after submit, feedback expands on the same screen where practical

## Do not
- hardcode question text
- hardcode answer choices
- hardcode question count
- hardcode timer values

---

# 15. Answer Feedback

Prefer inline expansion within Practice Question instead of a separate route.

## Correct state
- **Correct**
- correct answer highlighted

## Incorrect state
- **Incorrect**
- selected wrong answer identified
- correct answer highlighted

## Explanation
- why the correct answer is correct
- optional major distractor explanations
- source/reference

## Actions
- Bookmark
- Report Problem
- **Next Question**

---

# 16. Practice Result

## UI
- session complete headline
- correct / total
- accuracy %
- time spent
- strongest area
- weakest area
- readiness change if meaningful

## Actions
- **Practice Weak Areas**
- Start Another Session
- Back Home

---

# 17. Mock Exam Intro

## UI
- exam question count
- duration
- timed status
- back-navigation rule
- practice passing threshold
- blueprint note
- disclaimer

## Primary CTA
**Start Mock Exam**

## Subscription
If mock exams are premium-only, gate here.

---

# 18. Mock Exam Question

## UI
- timer if configured
- question number
- question text
- answers
- Flag Question
- Previous if allowed
- Next

## Rules
- no correctness feedback during the exam
- no explanation during the exam
- save answers and flags locally as the user proceeds
- preserve in-progress state across brief backgrounding

---

# 19. Mock Exam Navigator

## UI
Question numbers with distinct states:
- current
- answered
- unanswered
- flagged

## Rule
Jumping between questions only works if allowed by `ExamConfig`.

---

# 20. Finish Mock Exam Confirmation

## UI
- answered count
- unanswered count
- flagged count

## Actions
- Return to Exam
- **Finish Mock Exam**

---

# 21. Mock Exam Result

## UI
- `Mock Exam Result`
- percent correct
- estimated result relative to practice threshold
- domain breakdown
- time used
- strongest domain
- weakest domain
- comparison with previous attempts

## Allowed wording
- Above the practice passing threshold
- Below the practice passing threshold
- Estimated readiness
- Practice result

## Forbidden wording
- `You passed the exam`

## Actions
- Review Incorrect Answers
- Practice Weak Areas
- Back Home

---

# 22. Progress

## Required UI
- current Readiness Score
- readiness trend/history
- recent accuracy
- total answered
- unique questions answered
- streak
- domain mastery
- topic mastery
- mock exam history

## Navigation
- Readiness -> Readiness Detail
- Domain -> Domain Detail
- Mock attempt -> Mock Attempt Detail

## Important change from current prototype
The existing weekly activity chart and stat styling may remain, but values must be calculated from persisted attempts rather than hardcoded constants.

---

# 23. Readiness Detail

## UI
- score
- label
- evidence confidence
- recent accuracy component
- domain mastery component
- mock performance component
- repeated mastery component
- coverage component
- weakest area
- recommended next action
- disclaimer

## Goal
Make the score understandable rather than mysterious.

---

# 24. Domain Detail

## UI
- domain name
- mastery
- recent accuracy
- total attempts
- topics
- topic mastery

## Primary CTA
**Practice This Domain**

---

# 25. Topic Detail

## UI
- topic name
- mastery
- recent accuracy
- seen/unseen counts
- last practiced date

## Primary CTA
**Practice This Topic**

---

# 26. Mock History / Attempt Detail

## History row
- date
- score
- duration
- threshold status

## Attempt detail
- score
- domain breakdown
- incorrect question review where content is still available

---

# 27. Paywall

## Headline
**Pass With Confidence**

## Benefits
- Full question bank
- Unlimited practice
- Mock exams
- Personalized weak-area practice
- Detailed explanations
- Readiness history
- Advanced progress

## Products
- Weekly
- Monthly
- 3 Months

Actual localized price and billing period must come from the store integration. Do not hardcode prices into UI.

## Required secondary actions
- Restore Purchases
- Manage Subscription where supported
- Terms
- Privacy

## UX rules
- no fake countdowns
- no fake discounts
- no dark patterns
- cancellation should remain easy through platform subscription management

---

# 28. Settings

## Study
- Exam Date
- Daily Goal
- Notifications

## Subscription
- Current Plan
- Upgrade
- Restore Purchases
- Manage Subscription

## Content
- Exam Version
- Content Version
- Last Updated

## Support
- Report a Problem
- Contact Support

## Legal
- Privacy Policy
- Terms of Use
- Exam Disclaimer

## App
- App Version

---

# 29. Report Question

## Report categories
- Incorrect answer
- Incorrect explanation
- Outdated information
- Typo
- Question unclear
- Other

## Automatically attach
- exam ID
- question ID
- question version
- content version
- app version

## User input
- category
- optional note

---

# 30. Subscription behavior

## Free default
- onboarding
- diagnostic
- initial readiness
- Home
- limited daily practice
- basic progress
- Settings

## Premium candidates
- full question bank
- unlimited practice
- Mock Exams
- Weak Areas
- Incorrect-only training
- advanced Custom Quiz
- advanced Progress
- readiness history

Feature gates must be centralized rather than duplicated inside individual screens.

---

# 31. Offline behavior

Must work offline:
- Home with cached/local data
- Practice
- explanations
- bookmarks
- incorrect questions
- weak-area practice
- mock exams
- Progress
- Readiness Score
- local Settings

May require internet:
- purchase/restore subscription
- content download/update
- remote report submission
- optional analytics

---

# 32. Readiness Score interpretation

Default configurable thresholds:

- 0-39: Starting
- 40-59: Developing
- 60-74: Getting Close
- 75-84: Exam Ready
- 85-100: Strongly Prepared

Always show an estimate disclaimer.

---

# 33. Example question content

These examples are for development/testing only. They must remain `draft` until professionally reviewed.

```json
[
  {
    "id": "rhs-dev-001",
    "examId": "danb-rhs",
    "domainId": "radiation-physics",
    "topicId": "xray-properties",
    "questionText": "Which statement best describes the purpose of filtration in an x-ray beam?",
    "answers": [
      {"id": "a", "text": "To remove lower-energy photons that add dose without improving the image"},
      {"id": "b", "text": "To increase geometric magnification"},
      {"id": "c", "text": "To increase patient motion"},
      {"id": "d", "text": "To eliminate the need for collimation"}
    ],
    "correctAnswerId": "a",
    "explanation": "Filtration removes lower-energy photons that are more likely to be absorbed by the patient without contributing useful image information.",
    "references": [],
    "difficulty": 2,
    "status": "draft",
    "version": 1,
    "sourceVersion": "development-sample",
    "tags": ["sample", "physics"]
  },
  {
    "id": "rhs-dev-002",
    "examId": "danb-rhs",
    "domainId": "radiation-safety",
    "topicId": "operator-protection",
    "questionText": "Which general radiation-protection principle reduces occupational exposure by increasing separation from the radiation source?",
    "answers": [
      {"id": "a", "text": "Time"},
      {"id": "b", "text": "Distance"},
      {"id": "c", "text": "Processing"},
      {"id": "d", "text": "Magnification"}
    ],
    "correctAnswerId": "b",
    "explanation": "Increasing distance from a radiation source is one of the core ways to reduce occupational exposure.",
    "references": [],
    "difficulty": 1,
    "status": "draft",
    "version": 1,
    "sourceVersion": "development-sample",
    "tags": ["sample", "safety"]
  },
  {
    "id": "rhs-dev-003",
    "examId": "danb-rhs",
    "domainId": "imaging",
    "topicId": "image-quality",
    "questionText": "If a dental radiographic image shows motion blur, which factor should be evaluated first?",
    "answers": [
      {"id": "a", "text": "Patient or receptor movement during exposure"},
      {"id": "b", "text": "The color of the operatory walls"},
      {"id": "c", "text": "The patient's appointment time"},
      {"id": "d", "text": "The brand name of the receptor"}
    ],
    "correctAnswerId": "a",
    "explanation": "Motion blur is commonly associated with movement of the patient, receptor, or equipment during exposure.",
    "references": [],
    "difficulty": 2,
    "status": "draft",
    "version": 1,
    "sourceVersion": "development-sample",
    "tags": ["sample", "image-quality"]
  }
]
```

These are illustrative development questions, not a validated DANB question bank and not official exam items.

---

# 34. Empty/error states

Every major screen must support appropriate states.

Examples:

- no exam date -> `Set Exam Date`
- no weak areas -> `Answer more questions to identify your weak areas.`
- no incorrect questions -> `No incorrect questions to review.`
- no bookmarks -> `Bookmark questions while studying to find them here.`
- low readiness evidence -> explain low confidence
- Store unavailable -> allow free study and show non-blocking error
- mock cannot be generated -> do not silently violate blueprint; show clear error

---

# 35. Definition of done for a screen

A screen is only complete when:

- it uses real app data rather than hardcoded display values
- its primary CTA works
- navigation works
- loading/empty/error states are handled where relevant
- data changes persist when required
- it behaves correctly without internet where applicable
- premium gates are respected
- large text does not break layout
- screen-reader semantics are present
- light/dark themes remain readable
- no exam-specific business rule is embedded directly in a generic reusable widget

---

# 36. Product loop

```text
ASSESS
  -> PRACTICE
  -> RECORD PERFORMANCE
  -> IDENTIFY WEAKNESS
  -> ADAPT NEXT SESSION
  -> MOCK EXAM
  -> UPDATE READINESS
  -> RECOMMEND WHAT TO DO NEXT
  -> PRACTICE
```

Every major product decision should strengthen this loop.
