import 'package:flutter/widgets.dart';

import '../ext/app_theme_ext.dart';

/// {@template app_pressable}
/// Anything the player can tap.
///
/// Owns the three things every control needs and each used to write by hand:
/// button semantics, a hit-testable area, and press feedback — a quick
/// shrink while the finger is down and a slightly springy settle on release.
/// Build a control's *look* as [child]; how it responds is decided here, once.
///
/// With [semanticsLabel] set, the child's own semantics are replaced by it, so
/// a control reads as one sentence rather than as loose fragments. Leave it
/// `null` when the child's text already says everything.
/// {@endtemplate}
class const AppPressable({
  required final Widget child,
  final VoidCallback? onTap,
  final bool enabled = true,
  final String? semanticsLabel,

  /// Set for a control with an on/off state, such as a microphone.
  final bool? toggled,

  /// Overrides the theme's press scale — a large control reads better with
  /// less shrink than a small one.
  final double? pressedScale,
  super.key,
}) extends StatefulWidget {
  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  bool get _active => widget.enabled && widget.onTap != null;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  void didUpdateWidget(AppPressable old) {
    super.didUpdateWidget(old);
    // A control disabled mid-press would otherwise stay shrunk until touched.
    if (!_active) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final scale = _pressed ? widget.pressedScale ?? motion.pressedScale : 1.0;

    return Semantics(
      button: true,
      enabled: _active,
      toggled: widget.toggled,
      label: widget.semanticsLabel,
      excludeSemantics: widget.semanticsLabel != null,
      // Stated here, not left to the gesture detector below: excluding the
      // child's semantics excludes the detector's tap action with it, and a
      // screen reader would then announce a button it cannot press.
      onTap: _active ? widget.onTap : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _active ? (_) => _setPressed(true) : null,
        onTapUp: _active ? (_) => _setPressed(false) : null,
        onTapCancel: _active ? () => _setPressed(false) : null,
        onTap: _active ? widget.onTap : null,
        child: AnimatedScale(
          scale: scale,
          // Down fast so the press feels attached to the finger; back up a
          // touch slower with a little overshoot so the release has life.
          duration: _pressed ? motion.instant : motion.fast,
          curve: _pressed ? motion.standard : motion.emphasized,
          child: widget.child,
        ),
      ),
    );
  }
}
