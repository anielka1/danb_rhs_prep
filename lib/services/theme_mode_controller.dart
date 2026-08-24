import 'package:flutter/material.dart';

/// App-wide theme mode selection (System/Light/Dark).
///
/// A plain [ValueNotifier], not a state-management package — the
/// smallest thing that satisfies "single source of truth, held above
/// `MaterialApp`, whole app updates immediately on change." Held in
/// `DanbRhsPrepApp`'s State (see `main.dart`) and handed down to
/// `ProfileSettingsScreen`, so the selected mode lives at the
/// application level rather than inside the settings screen, and
/// naturally survives navigating away from and back to Settings — the
/// controller is never recreated by navigation, only the screens that
/// read it are.
///
/// Session-only for now: there is no production (non-fake)
/// `UserSettingsRepository` implementation yet — the only concrete
/// implementation, `InMemoryUserSettingsRepository`, is explicitly
/// documented as being for tests/previews. `UserProfile.themePreference`
/// exists on that model, but reusing it here would mean fabricating a
/// complete, fake onboarding profile (experience level, exam date,
/// daily goal, etc. — none of which exist yet) just to store one enum,
/// which trades one honesty problem for another. Real persistence
/// belongs with the onboarding/profile work, where a genuine
/// `UserProfile` is first created; until then, the selection resets to
/// [ThemeMode.system] on the next app launch.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController([super.value = ThemeMode.system]);
}
