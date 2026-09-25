import 'dart:math';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

import '../mic_controller.dart';

/// The size of the button's touch target and its circle.
///
/// Deliberately larger than the design system's control sizes: this is the
/// one control a player uses under time pressure, with their eyes on the
/// wheel rather than on their thumb.
const _diameter = 72.0;

/// {@template mic_button}
/// Turns the microphone on and off, and shows what it is doing.
///
/// The pulse is not decoration. A recogniser gives no other sign that it is
/// listening, and a player who cannot tell whether the microphone is open
/// will stop speaking to check — which, on Android, is exactly what closes
/// the session.
/// {@endtemplate}
class const MicButton({
  required final MicStatus status,
  required final VoidCallback onTap,

  /// Read aloud in place of the glyph, which carries no text of its own.
  required final String semanticsLabel,
  super.key,
}) extends StatefulWidget {
  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Whether the platform asked for less motion. Read in
  /// [didChangeDependencies], since it comes from an inherited widget.
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = context.motion.isReduced;
    _syncPulse();
  }

  @override
  void didUpdateWidget(MicButton old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) _syncPulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// The pulse runs only while listening — an animation ticking behind an idle
  /// button is a frame's work per frame for nothing.
  ///
  /// Under reduced motion it does not loop at all: the ring is drawn still,
  /// half-way out, which says "listening" just as plainly.
  void _syncPulse() {
    final listening = widget.status == MicStatus.listening;
    if (listening && _reduced) {
      _pulse
        ..stop()
        ..value = 0.35;
    } else if (listening) {
      _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    final motion = context.motion;

    final (fill, glyph) = switch (widget.status) {
      MicStatus.listening => (accent.accentSolid, accent.accentOnSolid),
      MicStatus.idle => (
        context.backgroundColors.bgSecondary,
        context.foregroundColors.fgSecondary,
      ),
      MicStatus.unavailable => (
        context.backgroundColors.bgDisabled,
        context.foregroundColors.fgDisabled,
      ),
    };

    return AppPressable(
      toggled: widget.status == MicStatus.listening,
      enabled: widget.status != MicStatus.unavailable,
      semanticsLabel: widget.semanticsLabel,
      onTap: widget.onTap,
      child: SizedBox.square(
        dimension: _diameter,
        // The colours ease between states, so switching the microphone on
        // reads as it lighting up rather than as a different button.
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: fill),
          duration: motion.fast,
          curve: motion.standard,
          builder: (context, animatedFill, _) => TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: glyph),
            duration: motion.fast,
            curve: motion.standard,
            builder: (context, animatedGlyph, _) => AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                painter: _MicPainter(
                  fill: animatedFill ?? fill,
                  glyph: animatedGlyph ?? glyph,
                  // Held at zero when idle, so the painter draws no ring.
                  pulse: _pulse.value,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MicPainter extends CustomPainter {
  _MicPainter({required this.fill, required this.glyph, required this.pulse});

  final Color fill;
  final Color glyph;

  /// Where the expanding ring is in its cycle, 0..1. Zero draws no ring.
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    if (pulse > 0) {
      // One ring, growing outward and fading as it goes, like a sound leaving
      // the microphone.
      canvas.drawCircle(
        center,
        radius * (0.82 + 0.18 * pulse),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = fill.withValues(alpha: (1 - pulse) * 0.5),
      );
    }

    canvas.drawCircle(center, radius * 0.8, Paint()..color = fill);
    _paintMic(canvas, center, radius * 0.8);
  }

  /// The microphone glyph: a capsule, the arc that cradles it, and a stand.
  void _paintMic(Canvas canvas, Offset center, double radius) {
    final stroke = radius * 0.11;
    final paint = Paint()
      ..color = glyph
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final capsuleWidth = radius * 0.42;
    final capsuleHeight = radius * 0.78;
    final capsuleTop = center.dy - radius * 0.62;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center.dx - capsuleWidth / 2,
          capsuleTop,
          capsuleWidth,
          capsuleHeight,
        ),
        Radius.circular(capsuleWidth / 2),
      ),
      Paint()..color = glyph,
    );

    final cradle = radius * 0.62;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: cradle),
      0.15 * pi,
      0.7 * pi,
      false,
      paint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy + cradle),
      Offset(center.dx, center.dy + radius * 0.86),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MicPainter old) =>
      old.fill != fill || old.glyph != glyph || old.pulse != pulse;
}
