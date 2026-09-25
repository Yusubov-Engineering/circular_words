import 'package:flutter/widgets.dart';

import '../ext/app_theme_ext.dart';

/// {@template app_entrance}
/// Fades [child] in while it rises into place — once, when first built.
///
/// Give consecutive items increasing [index]es and they arrive one after
/// another. The delay is part of the animation itself rather than a timer,
/// so nothing is left pending if the widget goes away early.
/// {@endtemplate}
class const AppEntrance({
  required final Widget child,
  final int index = 0,
  super.key,
}) extends StatefulWidget {
  @override
  State<AppEntrance> createState() => _AppEntranceState();
}

class _AppEntranceState extends State<AppEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Animation<double> _progress;
  double _offset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Motion comes from an inherited widget, so this is the earliest point it
    // can be read — and the entrance only ever plays once.
    if (_controller != null) return;

    final motion = context.motion;
    final delay = motion.stagger * widget.index;
    final total = motion.slow + delay;
    final start = total == Duration.zero
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;

    _offset = motion.enterOffset;
    final controller = AnimationController(vsync: this, duration: total);
    _controller = controller;
    _progress = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1, curve: motion.standard),
    );
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) => Opacity(
        opacity: _progress.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _progress.value) * _offset),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
