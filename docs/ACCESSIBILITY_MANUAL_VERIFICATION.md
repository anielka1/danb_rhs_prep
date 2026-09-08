# Manual VoiceOver Verification Checklist

Automated semantics tests (see `test/screens/`, `test/widgets/`) check the
*structure* of the semantics tree — labels, values, states, traversal
order. They do not replace actually swiping through the app with VoiceOver
on a device or simulator, which is the only way to confirm what a real
user actually *hears* and *experiences*. This checklist has not yet been
executed with VoiceOver itself; use it to run that pass.

For each item: turn VoiceOver on (Settings → Accessibility → VoiceOver, or
Accessibility Shortcut), then swipe/explore and note what's announced.

## Launch and Home
- [ ] Splash screen: is anything announced, or is it silent for the ~2s launch delay?
- [ ] Home loads with focus somewhere sensible (not stuck on an off-screen element).
- [ ] "Today" header, date, and week strip are announced in a sensible order.
- [ ] Each day in the week strip announces day + date + selected state.
- [ ] Task cards announce title, time, and description without duplicate announcements.
- [ ] The Mock Exam Session card is announced as one control, not fragmented.
- [ ] The Settings gear icon announces "Settings" with a hint that it's a button.

## All four navigation tabs
- [ ] Swiping through the tab bar announces "Home", "Practice", "Mock Exam", "Progress" in that order.
- [ ] The active tab is announced as selected; others are not.
- [ ] Switching tabs and swiping again does *not* surface the other three tabs' content (confirms inactive IndexedStack children stay excluded with real VoiceOver, not just in the automated test).
- [ ] Progress tab: the weekly activity chart announces an overall summary (including the most active day) rather than silent/unlabeled bars.
- [ ] Progress tab: domain progress rows announce name + percent as one item.

## Settings open and close
- [ ] Opening Settings from Home moves VoiceOver focus into the new screen (not stuck on the now-hidden Home content).
- [ ] The back button is announced clearly and is the first or near-first focusable item.
- [ ] Closing Settings returns focus somewhere reasonable on Home (not lost/reset to the top of the screen unexpectedly).

## Answer-option states
- [ ] An unselected option announces "Option A: <text>, not selected".
- [ ] Selecting it announces "...selected".
- [ ] After submitting, correct/incorrect options announce "...correct answer" / "...incorrect, your answer" and the decorative check/cancel icon is *not* announced separately.
- [ ] The bookmark button on the review screen announces "Bookmark question" as a button when not bookmarked, and "Remove bookmark" once tapped (PREP-460: a real toggle now, not disabled) — confirm VoiceOver announces the *label* change, not just an icon-color difference.

## Progress/chart reading
- [ ] The weekly activity chart on Progress reads as one summary, not seven unlabeled decorative bars.
- [ ] The readiness ring (wherever shown) announces "Readiness score, N percent" (or "not enough data yet").

## Dialogs
- [ ] Opening a dialog (e.g. via `AppDialog`) announces the title first, then the message, before the actions.
- [ ] Destructive and cancel actions are distinguishable by their announced label.

## Appearance selector (new in this task)
- [ ] Settings → Appearance: selecting System/Light/Dark is announced with the segment's name and its selected state.
- [ ] The disabled Push Notifications / Sound Effects switches, and the disabled Forgot Password / Google / Apple / Review Answers / Review Mistakes / Home FAB controls, are all announced as unavailable (not silently skipped, not announced as active buttons) — this checks the *live* VoiceOver experience of the `enabled: false` state the automated tests only check structurally. ("Edit Profile" / "Change Password" removed outright by PREP-459 — this app is accountless in V1 with no plan to add sign-in, so there's nothing left here to verify. Previous/Next and the bookmark control are real, enabled controls now — PREP-460 — so they belong in the *working*-control checks above, not here.)

## Light and dark mode
- [ ] Repeat the Home/tab-bar pass in dark mode — VoiceOver behavior should be identical (this is a rendering/contrast check, not a semantics check, but worth confirming nothing visually breaks while VoiceOver is on).
- [ ] **Remaining from this task:** only Home has actually been visually inspected via simulator screenshot (light + dark, small/large/iPad). Practice, Mock Exam, Progress, Settings, and every pushed screen (Exam Info, a practice question, answer review, mock results, practice summary) have not been visually inspected in either theme — only exercised through automated widget tests. There is no simulator UI-automation tool available in this environment to tap through and screenshot those routes; doing so requires a human (or a tool with tap-injection) driving the simulator.

## Large accessibility text
- [ ] With VoiceOver *and* the largest Dynamic Type size both on, repeat the Home and tab-bar pass — confirm every element is still announced and reachable even where labels visually wrap.
- [ ] **Remaining from this task:** the largest-accessibility-size visual pass was only performed live (via `xcrun simctl ui ... content_size accessibility-extra-extra-extra-large` + screenshot) for Home, in an earlier session. Every other screen has only been checked by the automated 4.0x `dynamic_type_test.dart` suite, not by an actual screenshot at the real iOS AX5 category. Given AX5 was already found to scale further than a naive reading of "3.0x" once for Home, a live screenshot pass across the other screens (not just automated 4.0x) would add real confidence beyond what's here.

## Reduce Motion (live verification — not yet performed)
- [ ] Enable Reduce Motion on-device (Settings → Accessibility → Motion → Reduce Motion) and confirm the Home day-strip selection and the Login segmented-toggle highlight both jump to their final state instantly, with no visible slide/fade.
- [ ] Confirm the loading spinner (`LoadingState`) still animates — Reduce Motion should not remove genuine in-progress feedback.
- [ ] **Remaining from this task:** there is no `simctl` command to toggle Reduce Motion, and no UI-automation tool to open Settings and flip it by hand in this environment, so this has only ever been verified by automated tests (`test/screens/reduce_motion_test.dart`, which force `MediaQuery.disableAnimations` directly rather than the real OS setting) — never live, on-device or in-simulator, with the actual system preference.

## Screen transitions
- [ ] Pushing a new screen (e.g. Practice → Exam Info → a question) announces the new screen meaningfully, not silently.
- [ ] Popping back returns focus to a sensible place on the previous screen.

---

**Status: not yet executed.** This checklist was authored, and Home was
manually inspected via simulator screenshots (layout, contrast, Dynamic
Type at the real largest accessibility category, light/dark) across
small/large iPhone and iPad. VoiceOver itself has never been operated —
there is no accessibility-driver tool available in this environment, only
screenshot capture and `xcrun simctl` settings toggles (appearance,
content size). Reduce Motion has likewise never been toggled live. The
roadmap's "VoiceOver verification" item stays unchecked until someone
actually runs this checklist with VoiceOver on a device or simulator they
can interact with directly.
