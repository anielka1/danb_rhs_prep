import 'package:flutter/material.dart';

/// Themed determinate progress bar. Track/fill colors come from
/// `ProgressIndicatorThemeData` (configured once in `AppTheme`), so this
/// widget only needs to own rounding, height, and accessible semantics.
///
/// [value] is deliberately clamped to 0-1 rather than throwing: a progress
/// bar is typically fed a computed fraction (e.g. `answered / total`) where
/// a caller bug or a transient 0/0 state should degrade to a visually
/// sensible empty/full bar, not crash the screen. Contrast this with
/// domain models, which throw on invalid construction because their
/// invariants indicate real data-integrity bugs.
class ProgressBar extends StatelessWidget {
  const ProgressBar(
      {super.key, required this.value, this.height = 8, this.semanticLabel});

  final double value;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0, 1);
    return Semantics(
      label: semanticLabel,
      value: '${(clamped * 100).round()} percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(value: clamped, minHeight: height),
      ),
    );
  }
}
