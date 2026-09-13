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
/// `DanbRhsPrepApp` persists changes through BootstrapLocalStore and restores
/// the saved preference during bootstrap. This notifier owns only the live value.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController([super.value = ThemeMode.system]);
}
