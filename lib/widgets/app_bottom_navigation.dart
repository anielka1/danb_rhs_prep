import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The four primary tabs, in their fixed display order. This is the only
/// application-facing representation of "which tab is selected" — screens
/// and the main shell pass this typed enum around, never a raw index or
/// label, so a tab and its position can never drift out of sync.
enum AppTab { home, practice, mockExam, progress }

class _TabSpec {
  final AppTab tab;
  final IconData icon;
  final String label;
  const _TabSpec(this.tab, this.icon, this.label);
}

const List<_TabSpec> _tabs = [
  _TabSpec(AppTab.home, Icons.home_rounded, 'Home'),
  _TabSpec(AppTab.practice, Icons.menu_book_rounded, 'Practice'),
  _TabSpec(AppTab.mockExam, Icons.assignment_rounded, 'Mock Exam'),
  _TabSpec(AppTab.progress, Icons.bar_chart_rounded, 'Progress'),
];

// A small gap between adjacent tap targets, not a generous margin — the
// previous, more generous padding was what made "Practice"/"Progress"
// look like they didn't fit under flutter test's synthetic fallback
// font. Real platform typography needs far less room.
const double _itemHorizontalPadding = AppSpacing.xs;

/// Resolves the exact [TextStyle] a nav label renders with, the same way
/// `Text` itself resolves its effective style internally — merging this
/// widget's own overrides onto `DefaultTextStyle.of(context).style` —
/// so this single function is the only place that decision is made.
/// [_NavItem] calls it to render, and the fit measurement below calls it
/// to measure; because both go through the exact same function, the
/// resolved font family/fallback, size, weight, letter spacing, and
/// height can never drift apart between the two.
///
/// No `fontFamily` is set anywhere in this file: whatever the ambient
/// theme/platform typography actually resolves to for this app (this
/// project doesn't override `ThemeData.fontFamily`, so it's whatever
/// Flutter's platform-appropriate default provides) is what both
/// measurement and rendering use — never a hardcoded assumption.
TextStyle _resolveLabelStyle(BuildContext context, {required bool selected}) {
  final Color color = selected
      ? context.colors.onSurface
      : context.semanticColors.mutedForeground;
  return DefaultTextStyle.of(context).style.merge(TextStyle(
        fontSize: 11,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: color,
      ));
}

/// Bottom tab bar shown by the main app shell for all four primary tabs.
/// Settings is intentionally not a tab — it's reached via a toolbar icon.
///
/// At every text scale this bar is first measured (via [LayoutBuilder] +
/// [TextPainter], configured with the exact same resolved style,
/// [TextScaler], [TextDirection], and locale the rendered label uses —
/// see [_resolveLabelStyle] and [_requiredItemWidth]) against the actual
/// four-equal-column width. Whenever every label's widest single *word*
/// fits that column — true at every normal reading scale on every phone
/// this app targets — the bar renders as a plain `Row` of four
/// equal-width columns, each label wrapping onto a second line on its
/// own (no manual line-splitting) if it has more than one word and
/// doesn't fit on one line; the bar's height simply grows to fit
/// whichever item needs the most lines.
///
/// Only once a label's widest single word *still* doesn't fit — only
/// possible at extreme accessibility text scales — does the bar fall
/// back to a horizontally scrollable row where every item keeps its
/// full, natural, un-shrunk size, and the selected tab is kept
/// automatically scrolled into view.
class AppBottomNavigation extends StatefulWidget {
  final AppTab current;
  final ValueChanged<AppTab>? onTap;

  const AppBottomNavigation({super.key, required this.current, this.onTap});

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation> {
  final Map<AppTab, GlobalKey> _itemKeys = {
    for (final t in _tabs) t.tab: GlobalKey(debugLabel: t.label),
  };
  final ScrollController _scrollController = ScrollController();

  // Set during build (see `build` below) and read afterwards by
  // `_revealSelected`, which always runs one frame later — by the time
  // it runs, `build` has already run for the same widget state, so this
  // is never stale. Not part of State that itself needs a `setState`;
  // it's simply remembered from one build for the callback scheduled by
  // that same build.
  bool _isScrollable = false;

  @override
  void initState() {
    super.initState();
    // Covers "initial construction" (this) and "state restoration"
    // (state restoration reconstructs this State the same way a normal
    // first build does, with `widget.current` already holding the
    // restored value).
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void didUpdateWidget(covariant AppBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Runs on *every* rebuild, not only when `current` actually changes:
    // that covers both "a programmatic tab change" and "rebuilding the
    // parent" as separate triggers, exactly as required. This is safe
    // and cheap to call unconditionally because `Scrollable.ensureVisible`
    // is itself a no-op whenever the target is already fully on screen —
    // it never resets a scroll position that doesn't need to change.
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _revealSelected() {
    // The state (or the whole tree) may have been disposed between this
    // callback being scheduled and the frame actually completing —
    // checking `mounted` first, before touching `context` or `widget`,
    // is what keeps this safe to schedule unconditionally.
    if (!mounted || !_isScrollable) return;
    final BuildContext? itemContext = _itemKeys[widget.current]?.currentContext;
    if (itemContext == null) return;
    Scrollable.ensureVisible(
      itemContext,
      duration:
          context.reducedMotionDuration(const Duration(milliseconds: 200)),
      curve: Curves.easeInOut,
    );
  }

  /// The width this label needs to render without ever mid-word-breaking:
  /// its own full width if it's a single word, or its widest individual
  /// word if it has more than one — since wrapping onto more lines only
  /// ever costs height, never width, once every word individually fits.
  ///
  /// Measured against *both* the selected and unselected resolved
  /// styles (normally the bolder, selected one is the wider of the two,
  /// but this doesn't assume that) and every label in the bar, not just
  /// whichever tab happens to be selected right now — so this decision
  /// is stable across tab selection, never flipping between the fixed
  /// and scrollable layouts merely because a different tab became
  /// selected.
  double _requiredItemWidth(BuildContext context, String label) {
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final TextDirection textDirection = Directionality.of(context);
    final Locale? locale = Localizations.maybeLocaleOf(context);
    final List<TextStyle> candidateStyles = [
      _resolveLabelStyle(context, selected: true),
      _resolveLabelStyle(context, selected: false),
    ];

    double widestWord = 0;
    for (final String word in label.split(' ')) {
      for (final TextStyle style in candidateStyles) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: textDirection,
          textScaler: textScaler,
          locale: locale,
        )..layout();
        if (painter.width > widestWord) widestWord = painter.width;
      }
    }
    final double textWidth =
        widestWord > AppIconSize.standard ? widestWord : AppIconSize.standard;
    return textWidth + _itemHorizontalPadding * 2;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.outlineVariant)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double columnWidth = constraints.maxWidth / _tabs.length;
            _isScrollable = _tabs
                .any((t) => _requiredItemWidth(context, t.label) > columnWidth);

            final List<Widget> items = _tabs
                .map((t) => _NavItem(
                      key: _itemKeys[t.tab],
                      icon: t.icon,
                      label: t.label,
                      selected: widget.current == t.tab,
                      onTap: () => widget.onTap?.call(t.tab),
                    ))
                .toList();

            if (!_isScrollable) {
              // Each item shares the row equally — the bar's classic
              // four-equal-column design. Height is whatever the
              // tallest item needs (a wrapped two-word label, or a
              // single-line one), not a fixed value.
              return Row(
                children: items.map((item) => Expanded(child: item)).toList(),
              );
            }

            // mainAxisSize.min is required here: a Row's default
            // mainAxisSize (max) demands to be as wide as its incoming
            // constraints allow, but a horizontal SingleChildScrollView
            // gives its child unbounded width — "as wide as possible"
            // is meaningless (and asserts) there. min lets the Row size
            // itself to its items' real combined width instead, which is
            // exactly what needs to scroll.
            return SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(mainAxisSize: MainAxisSize.min, children: items),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? context.colors.onSurface
        : context.semanticColors.mutedForeground;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.smallIcon),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppTapTarget.minInteractive,
            minHeight: AppTapTarget.minInteractive,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: _itemHorizontalPadding, vertical: AppSpacing.xs),
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: AppIconSize.standard),
                  const SizedBox(height: AppSpacing.xs),
                  // No maxLines, no overflow, no FittedBox: the layout
                  // above (four equal columns vs. a horizontally
                  // scrollable row) is only chosen once every label's
                  // widest word is already known to fit at its true,
                  // unscaled size — a multi-word label simply wraps
                  // naturally onto a second line here, and a single-word
                  // label always fits on its one line.
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: _resolveLabelStyle(context, selected: selected),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
