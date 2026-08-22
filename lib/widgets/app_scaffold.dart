import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Consistent application shell used by every content screen: themed
/// background, safe-area handling, token-based horizontal padding, an
/// optional header (back/close action, title, trailing actions), and
/// passthrough slots for bottom navigation and a floating action button.
///
/// This widget owns only shell layout — it never embeds business-specific
/// content, routing, or navigation decisions; screens still decide what
/// their `body` contains and where `leading`/`actions` navigate.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.leading,
    this.actions = const [],
    this.centerTitle = false,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.padding,
    this.resizeToAvoidBottomInset = true,
  });

  /// Main screen content. Receives the remaining vertical space below the
  /// header (if any) — screens that need to scroll should make this a
  /// `SingleChildScrollView`/`ListView`/`Column` with its own `Expanded`,
  /// exactly as they already do.
  final Widget body;

  /// Optional header title, shown as a single-line heading.
  final String? title;

  /// Optional leading header widget (typically a back/close
  /// `CircleIconButton`). Reserves a 44pt-wide slot even when null but a
  /// title is present, so a centered title stays visually centered.
  final Widget? leading;

  /// Optional trailing header widgets (e.g. a bookmark toggle).
  final List<Widget> actions;

  /// Whether [title] is centered (matching a screen that has symmetric
  /// leading/trailing content) or left-aligned (the default, matching most
  /// screens' existing back-button-then-title layout).
  final bool centerTitle;

  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Outer body padding. Defaults to the standard horizontal screen
  /// padding token used by every screen; pass an explicit value only when
  /// a screen genuinely needs different spacing.
  final EdgeInsetsGeometry? padding;

  final bool resizeToAvoidBottomInset;

  bool get _hasHeader => title != null || leading != null || actions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasHeader) ...[
                // Matches the 12px top gap every header-style screen used
                // before this component existed.
                const SizedBox(height: AppSpacing.md),
                _Header(
                  title: title,
                  leading: leading,
                  actions: actions,
                  centerTitle: centerTitle,
                  titleStyle: textStyles.h3,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Expanded(child: body),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.leading,
    required this.actions,
    required this.centerTitle,
    required this.titleStyle,
  });

  final String? title;
  final Widget? leading;
  final List<Widget> actions;
  final bool centerTitle;
  final TextStyle titleStyle;

  @override
  Widget build(BuildContext context) {
    final Widget titleWidget = title == null
        ? const SizedBox.shrink()
        : Text(
            title!,
            style: titleStyle,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            overflow: TextOverflow.ellipsis,
          );

    return Row(
      children: [
        leading ??
            const SizedBox(
              width: AppTapTarget.minInteractive,
              height: AppTapTarget.minInteractive,
            ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: titleWidget),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.md),
          ...actions,
        ] else if (centerTitle && leading != null)
          const SizedBox(
            width: AppTapTarget.minInteractive,
            height: AppTapTarget.minInteractive,
          ),
      ],
    );
  }
}
