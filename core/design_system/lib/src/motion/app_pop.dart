import 'dart:math';

import 'package:flutter/widgets.dart';

import '../ext/app_theme_ext.dart';

/// {@template app_pop}
/// Gives [child] a brief swell whenever [trigger] changes.
///
/// For a value that just moved in the player's favour — a score, a counter —
/// so the change is noticed without anything having to flash. The first build
/// never pops: only a *change* is news.
/// {@endtemplate}
class const AppPop({
  required final Object? trigger,
  required final Widget child,

  /// How much larger the child grows at the top of the swell.
  final double amount = 0.18,
  super.key,
}) extends StatefulWidget {
  @override
  State<AppPop> createState() => _AppPopState();
}

class _AppPopState extends State<AppPop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didUpdateWidget(AppPop old) {
    super.didUpdateWidget(old);
    if (old.trigger == widget.trigger) return;

    final motion = context.motion;
    if (motion.isReduced) return;
    _controller
      ..duration = motion.medium
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        // Up and back down in one smooth arc, ending exactly at rest.
        scale: 1 + widget.amount * sin(pi * _controller.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}
