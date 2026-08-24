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

  /// A deliberately conservative reservation for the leading slot plus
  /// trailing actions (each assumed to be a `minInteractive`-wide tap
  /// target, which every current usage is) plus the gaps around them.
  /// Reserving the worst case regardless of which slots are actually
  /// present means this can only switch to the stacked layout *earlier*
  /// than strictly necessary, never later — so the single-row layout
  /// below is never at risk of the title actually needing more than one
  /// line once really measured against it.
  static const double _reservedChromeWidth =
      AppTapTarget.minInteractive * 2 + AppSpacing.md * 2;

  bool _titleNeedsStackedHeader(
      BuildContext context, double totalWidth, TextStyle titleStyle) {
    if (title == null) return false;
    final double availableForTitle = totalWidth - _reservedChromeWidth;
    final TextPainter painter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width > availableForTitle;
  }

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool stacked = _hasHeader &&
                  _titleNeedsStackedHeader(
                      context, constraints.maxWidth, textStyles.h3);

              final Widget header = _Header(
                title: title,
                leading: leading,
                actions: actions,
                centerTitle: centerTitle,
                titleStyle: textStyles.h3,
                stacked: stacked,
              );

              if (!stacked) {
                // Ordinary layout, unchanged from before this file ever
                // had to deal with accessibility text scaling: the
                // header is a fixed-height sibling of `Expanded(body)`
                // because it's already known (measured above) to need
                // only its normal, compact single row.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_hasHeader) ...[
                      const SizedBox(height: AppSpacing.md),
                      header,
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Expanded(child: body),
                  ],
                );
              }

              // Accessibility-sized layout: once a title is long/scaled
              // enough that it no longer fits beside the leading/trailing
              // actions on one line, there's no longer a safe fixed
              // height to give the header — an uncapped, unshrunk,
              // unwrapped-into-a-single-line title can need an
              // arbitrarily tall block on a narrow phone. Rather than
              // impose a height budget (which is what previously forced
              // a shrink-to-fit), the header and body now share one
              // scrolling region: the header's real height, whatever it
              // turns out to be, is simply part of the scrollable
              // content, exactly like everything below it. `body` keeps
              // rendering exactly as it does today — most screens are
              // already their own `SingleChildScrollView`, which safely
              // reports its natural content height when its parent's
              // height is unbounded and stops handling scrolling itself,
              // ceding it to this outer scroll view.
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    header,
                    const SizedBox(height: AppSpacing.md),
                    body,
                  ],
                ),
              );
            },
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
    required this.stacked,
  });

  final String? title;
  final Widget? leading;
  final List<Widget> actions;
  final bool centerTitle;
  final TextStyle titleStyle;

  /// False: today's single-row layout (leading, title, actions side by
  /// side) — only ever used once the title is already known to fit on
  /// one line there. True: the accessibility-sized layout below, used
  /// once it doesn't.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    // No FittedBox, no maxLines/maxHeight cap: by the time this widget
    // is built, the caller has already decided (by measuring) whether
    // the compact single-row layout can fit this title on one line. If
    // it can't, `stacked` is true and this always renders at full,
    // un-shrunk size — reflowing into a second row is what accommodates
    // it, not scaling it down.
    final Widget titleWidget = title == null
        ? const SizedBox.shrink()
        : Text(
            title!,
            style: titleStyle,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
          );

    if (!stacked) {
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

    // Stacked layout: leading and trailing actions share their own row
    // (so they stay reachable and at their normal size, unaffected by
    // text scaling) and the title gets a full-width row entirely to
    // itself below, free to wrap onto as many lines as it genuinely
    // needs at the requested text scale.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leading != null || actions.isNotEmpty)
          Row(
            children: [
              leading ?? const SizedBox.shrink(),
              const Spacer(),
              ...actions,
            ],
          ),
        if (leading != null || actions.isNotEmpty)
          const SizedBox(height: AppSpacing.sm),
        titleWidget,
      ],
    );
  }
}
