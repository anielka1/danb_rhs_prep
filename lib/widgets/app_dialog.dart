import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Visual/semantic style for one [AppDialogAction].
enum AppDialogActionStyle {
  /// A regular, non-destructive choice.
  normal,

  /// A destructive choice (e.g. "Delete", "Sign Out"), styled with the
  /// platform's destructive treatment.
  destructive,

  /// The platform's "safe"/default dismissal choice (e.g. "Cancel").
  cancel,
}

/// One typed dialog action. [value] is what `AppDialog.show` resolves to
/// when this action is chosen.
class AppDialogAction<T> {
  const AppDialogAction(
      {required this.label,
      required this.value,
      this.style = AppDialogActionStyle.normal});

  final String label;
  final T value;
  final AppDialogActionStyle style;
}

/// Adaptive alert dialog: Cupertino presentation/actions on iOS and macOS,
/// Material presentation/actions everywhere else, using
/// `Theme.of(context).platform` rather than `dart:io` so it stays testable
/// and works consistently under widget tests regardless of host OS.
///
/// This is a helper, not a blanket dialog replacement — migrate an
/// existing dialog to it only where the resulting behavior is equivalent.
class AppDialog {
  AppDialog._();

  /// Shows the adaptive dialog and returns the selected action's typed
  /// [AppDialogAction.value], or `null` if the dialog was dismissed via
  /// the barrier (only possible when [barrierDismissible] is true).
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    required List<AppDialogAction<T>> actions,
    bool barrierDismissible = true,
  }) {
    final bool cupertino = _isCupertino(Theme.of(context).platform);
    return cupertino
        ? _showCupertino<T>(
            context: context,
            title: title,
            message: message,
            actions: actions,
            barrierDismissible: barrierDismissible)
        : _showMaterial<T>(
            context: context,
            title: title,
            message: message,
            actions: actions,
            barrierDismissible: barrierDismissible);
  }

  static bool _isCupertino(TargetPlatform platform) {
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  static Future<T?> _showMaterial<T>({
    required BuildContext context,
    required String title,
    String? message,
    required List<AppDialogAction<T>> actions,
    required bool barrierDismissible,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        final ColorScheme colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          scrollable: true,
          title: Text(title),
          content: message == null ? null : Text(message),
          actions: [
            for (final action in actions)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(action.value),
                style: action.style == AppDialogActionStyle.destructive
                    ? TextButton.styleFrom(foregroundColor: colors.error)
                    : null,
                child: Text(action.label),
              ),
          ],
        );
      },
    );
  }

  static Future<T?> _showCupertino<T>({
    required BuildContext context,
    required String title,
    String? message,
    required List<AppDialogAction<T>> actions,
    required bool barrierDismissible,
  }) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: message == null ? null : Text(message),
          actions: [
            for (final action in actions)
              CupertinoDialogAction(
                isDestructiveAction:
                    action.style == AppDialogActionStyle.destructive,
                isDefaultAction: action.style == AppDialogActionStyle.cancel,
                onPressed: () => Navigator.of(dialogContext).pop(action.value),
                child: Text(action.label),
              ),
          ],
        );
      },
    );
  }
}
