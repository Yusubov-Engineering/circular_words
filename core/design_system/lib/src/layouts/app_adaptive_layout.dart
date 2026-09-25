import 'package:flutter/widgets.dart';

/// {@template app_adaptive_layout}
/// Builds [portrait] or [landscape] depending on the shape of the space it is
/// given.
///
/// Decided by its own constraints rather than by the device's orientation, so
/// a screen in split view, in a resizable window or on a tablet gets the
/// arrangement that fits the room it actually has. "Landscape" means clearly
/// wider than tall; a near-square area keeps the portrait arrangement, which
/// degrades more gracefully.
/// {@endtemplate}
class const AppAdaptiveLayout({
  required final WidgetBuilder portrait,
  required final WidgetBuilder landscape,
  super.key,
}) extends StatelessWidget {
  /// How much wider than tall an area must be to count as landscape.
  static const landscapeRatio = 1.2;

  /// Whether an area of [size] should be laid out as landscape.
  static bool isLandscape(Size size) =>
      size.height.isFinite && size.width > size.height * landscapeRatio;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        isLandscape(Size(constraints.maxWidth, constraints.maxHeight))
        ? landscape(context)
        : portrait(context),
  );
}

/// {@template app_fill_scroll}
/// Gives [child] at least the full height available, and scrolls when it
/// needs more.
///
/// For content laid out to fill a screen — a `Column` using
/// `MainAxisAlignment.spaceBetween` or `center` — that must still fit when
/// the room shrinks: a phone on its side, the keyboard open, a large font.
/// Lay the child out with alignment rather than `Spacer`/`Expanded`, which
/// have no height to share inside a scroll view.
/// {@endtemplate}
class const AppFillScroll({required final Widget child, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: child,
      ),
    ),
  );
}
