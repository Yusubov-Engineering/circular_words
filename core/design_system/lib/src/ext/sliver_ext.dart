import 'package:flutter/widgets.dart';

extension SliverExt on Widget {
  /// Boxes a regular (non-sliver) widget so it can sit in a `slivers` list.
  Widget get slivered => SliverToBoxAdapter(child: this);

  /// Adds padding around a widget that is already sliver-compatible (e.g.
  /// a [SliverList] or a [SliverMainAxisGroup]).
  ///
  /// Unlike wrapping with [slivered] first, this does not box the child in a
  /// [SliverToBoxAdapter] — doing so would force a shrink-wrapping viewport
  /// to lay out (and therefore build) every item up front just to measure
  /// its height, defeating lazy building. Use this on already-sliver content
  /// to keep it lazy.
  Widget paddedSliver(EdgeInsets insets) =>
      SliverPadding(padding: insets, sliver: this);
}
