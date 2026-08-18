# DANB RHS Prep — Flutter App

A pixel-matched Flutter implementation of the 10 provided screenshots for
the "DANB RHS Prep" / PrepMaster exam study app.

## Screens included
1. **Splash** — `lib/screens/splash_screen.dart`
2. **Login / Sign Up** — `lib/screens/login_screen.dart`
3. **Home (Today's schedule)** — `lib/screens/home_screen.dart`
4. **Exam Info / Overview** — `lib/screens/exam_overview_screen.dart`
5. **Practice Question** — `lib/screens/practice_question_screen.dart`
6. **Answer Review / Explanation** — `lib/screens/answer_explanation_screen.dart`
7. **Practice Session Summary** — `lib/screens/practice_summary_screen.dart`
8. **Mock Exam Results** — `lib/screens/mock_exam_results_screen.dart`
9. **Progress / Stats** — `lib/screens/progress_screen.dart`
10. **Profile & Settings** — `lib/screens/profile_settings_screen.dart`

All screens are wired together with real navigation (`Navigator` routes
defined in `lib/main.dart`), so you can tap through the whole flow:
Splash → Login → Home → Exam Info → Question → Review → (loop) → Summary,
plus the bottom-tab flow to Progress and Profile.

## Design system
Colors, text styles, spacing and corner radii are centralized in
`lib/theme/app_theme.dart`, extracted from the screenshots:
- Background: warm cream (`#FBF8EC`)
- Primary accent: periwinkle blue (`#8CA0E8`)
- Headings/text: deep navy-indigo (`#3B4A8C`)
- Success green / error red for grading states

Shared widgets (buttons, bottom nav, circular icon buttons, the radiation
trefoil icon) live in `lib/widgets/`.

## Running it

```bash
flutter pub get
flutter run
```

Requires a reasonably recent Flutter SDK (3.19+) with Material 3 enabled
(the default). No third-party packages beyond `cupertino_icons` are
required, so `flutter pub get` should be quick and won't need extra
credentials.

## Notes / things you'll likely want to customize
- **Avatars & photos**: the calendar/profile avatars are drawn as simple
  icon placeholders (`Icons.person`). Drop real images into
  `assets/images/`, wire them up in `pubspec.yaml`, and swap the
  `CircleAvatar`/`Icon` widgets for `AssetImage`/`NetworkImage`.
- **Fonts**: text styles reference `'SF Pro Display'` to match the
  screenshots' look; since that font isn't bundled, Flutter will fall
  back to the platform default. If you want an exact font match, add a
  font family (e.g. via `google_fonts` or a bundled `.ttf`) and update
  `AppTextStyles.fontFamily` in `lib/theme/app_theme.dart`.
- **Data**: all content (questions, scores, schedule items, profile
  stats) is currently hard-coded to match the screenshots exactly. Swap
  in real state management (Provider/Riverpod/Bloc) and an API/DB layer
  when you're ready to make it dynamic.
- **Radiation icon**: drawn with a custom `CustomPainter`
  (`lib/widgets/radiation_icon.dart`) rather than an image asset, so it
  scales cleanly at any size.
