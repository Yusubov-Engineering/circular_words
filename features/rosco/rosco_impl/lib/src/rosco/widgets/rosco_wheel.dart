import 'dart:math';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

import '../../domain/letter_slot.dart';

/// Where a letter sits on the circle.
///
/// Pulled out as a plain function so the geometry is testable without a
/// widget tree: index 0 at the top, then clockwise. Everything the painter
/// draws is positioned by this, so if it is right the wheel is right.
Offset roscoLetterOffset({
  required Offset center,
  required double radius,
  required int index,
  required int count,
}) {
  // -pi/2 puts A at twelve o'clock; without it the circle starts at three.
  final angle = -pi / 2 + (2 * pi * index) / count;

  return Offset(
    center.dx + radius * cos(angle),
    center.dy + radius * sin(angle),
  );
}

/// How big each letter chip can be before neighbours touch.
///
/// Derived from the circumference rather than hard-coded, so the wheel keeps
/// its proportions on a small phone and a tablet alike.
double roscoChipRadius({required double ringRadius, required int count}) {
  final spacing = (2 * pi * ringRadius) / count;
  return spacing * 0.38;
}

/// The circle of 26 letters.
///
/// Draws its own text rather than composing 26 widgets: the letters are
/// rotated around a circle and repaint together every second as the timer
/// sweeps, which is exactly the case a single [CustomPaint] handles best.
///
/// Three things move, each saying something: the highlight glides to the next
/// letter (where the player is now), a letter that has just been decided pops
/// with a ripple in its result colour (what just happened), and the timer
/// ring warms into the danger colour as the letter runs out (what is coming).
class const RoscoWheel({
  required final List<LetterSlot> slots,
  required final int activeIndex,

  /// How much of the current letter's cap is left, 0..1.
  required final double letterProgress,

  /// Drawn in the middle — the seconds left on this letter.
  required final String centerLabel,

  /// What the wheel would say if it could be read aloud.
  required final String semanticsLabel,
  super.key,
}) extends StatefulWidget {
  @override
  State<RoscoWheel> createState() => _RoscoWheelState();
}

class _RoscoWheelState extends State<RoscoWheel> with TickerProviderStateMixin {
  /// Drives the highlight from [_previousActive] to the current letter.
  late final AnimationController _move = AnimationController(
    vsync: this,
    value: 1,
  );

  /// Drives the pop of every letter in [_popped].
  late final AnimationController _pop = AnimationController(
    vsync: this,
    value: 1,
  );

  int? _previousActive;
  Set<int> _popped = const {};

  @override
  void didUpdateWidget(RoscoWheel old) {
    super.didUpdateWidget(old);
    final motion = context.motion;

    if (old.activeIndex != widget.activeIndex) {
      _previousActive = old.activeIndex;
      _move
        ..duration = motion.medium
        ..forward(from: 0);
    }

    // A letter that has just been decided — right or wrong. A pass is not a
    // decision, and a pending letter becoming active is the highlight's job.
    final decided = <int>{
      for (var index = 0; index < widget.slots.length; index++)
        if (index < old.slots.length &&
            old.slots[index].status != widget.slots[index].status &&
            (widget.slots[index].status == LetterStatus.correct ||
                widget.slots[index].status == LetterStatus.wrong))
          index,
    };
    if (decided.isNotEmpty) {
      _popped = decided;
      _pop
        ..duration = motion.slow
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _move.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = context.statusColors;
    final accent = context.accentColors;
    final motion = context.motion;
    final moveCurve = CurvedAnimation(parent: _move, curve: motion.emphasized);

    // A `CustomPaint` contributes nothing to the semantics tree, so to a
    // screen reader this — the entire subject of the screen — is a blank
    // rectangle. The label carries the letter, the clock and the score, which
    // is everything the picture is showing.
    return Semantics(
      label: widget.semanticsLabel,
      readOnly: true,
      child: AspectRatio(
        aspectRatio: 1,
        // The arc sweeps smoothly between ticks instead of jumping once a
        // second, which is the difference between a clock and a stutter.
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: widget.letterProgress),
          duration: motion.medium,
          builder: (context, progress, _) => AnimatedBuilder(
            animation: Listenable.merge([_move, _pop]),
            builder: (context, _) => CustomPaint(
              painter: RoscoWheelPainter(
                slots: widget.slots,
                activeIndex: widget.activeIndex,
                previousActive: _previousActive,
                move: moveCurve.value,
                popped: _popped,
                pop: _pop.value,
                letterProgress: progress,
                centerLabel: widget.centerLabel,
                correct: status.statusSuccess,
                wrong: status.statusDanger,
                passed: status.statusWarning,
                active: accent.accentSolid,
                onActive: accent.accentOnSolid,
                pending: status.statusNeutral,
                onFill: status.statusOnFill,
                pendingLabel: context.textColors.textTertiary,
                centerColor: context.textColors.textPrimary,
                track: context.borderColors.borderSecondary,
                typography: context.typography,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoscoWheelPainter extends CustomPainter {
  RoscoWheelPainter({
    required this.slots,
    required this.activeIndex,
    required this.previousActive,
    required this.move,
    required this.popped,
    required this.pop,
    required this.letterProgress,
    required this.centerLabel,
    required this.correct,
    required this.wrong,
    required this.passed,
    required this.active,
    required this.onActive,
    required this.pending,
    required this.onFill,
    required this.pendingLabel,
    required this.centerColor,
    required this.track,
    required this.typography,
  });

  final List<LetterSlot> slots;
  final int activeIndex;
  final int? previousActive;

  /// How far the highlight has travelled from [previousActive], 0..1. May
  /// overshoot 1 slightly — the curve is springy.
  final double move;
  final Set<int> popped;

  /// Where the pop of [popped] is in its arc, 0..1. At 1 it draws nothing.
  final double pop;
  final double letterProgress;
  final String centerLabel;
  final Color correct;
  final Color wrong;
  final Color passed;
  final Color active;
  final Color onActive;
  final Color pending;
  final Color onFill;
  final Color pendingLabel;
  final Color centerColor;
  final Color track;
  final AppTypography typography;

  /// The active chip is drawn this much larger, so the eye finds it without
  /// relying on colour alone.
  static const _activeScale = 1.45;

  /// How much a decided letter swells at the top of its pop.
  static const _popScale = 0.3;

  /// Where the ring starts warming toward danger, and where it gets there.
  static const _warnFrom = 0.45;
  static const _warnTo = 0.2;

  @override
  void paint(Canvas canvas, Size size) {
    if (slots.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final chipAllowance = roscoChipRadius(
      ringRadius: size.width / 2,
      count: slots.length,
    );
    final ringRadius = size.width / 2 - chipAllowance * _activeScale;
    final chipRadius = roscoChipRadius(
      ringRadius: ringRadius,
      count: slots.length,
    );

    _paintTimer(canvas, center, ringRadius - chipRadius * 1.9);
    _paintChips(canvas, center, ringRadius, chipRadius);
    _paintCenter(canvas, center, size.shortestSide);
  }

  /// How urgent the letter's clock is, 0 (calm) .. 1 (nearly out).
  double get _urgency =>
      ((_warnFrom - letterProgress) / (_warnFrom - _warnTo)).clamp(0.0, 1.0);

  /// The countdown, as a ring inside the letters.
  void _paintTimer(Canvas canvas, Offset center, double radius) {
    if (radius <= 0) return;

    final stroke = radius * 0.06;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    if (letterProgress <= 0) return;

    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * letterProgress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        // Running out of time is the one moment the ring should alarm — and
        // it warms into it rather than flipping, so the change is felt
        // coming instead of startling.
        ..color = Color.lerp(active, wrong, _urgency)!,
    );
  }

  /// How large chip [index] is drawn, relative to an ordinary chip.
  double _scaleFor(int index) {
    var scale = 1.0;
    if (index == activeIndex) {
      scale = 1 + (_activeScale - 1) * move;
    } else if (index == previousActive && move < 1) {
      scale = _activeScale - (_activeScale - 1) * move;
    }
    if (popped.contains(index)) scale += _popScale * sin(pi * pop);
    return scale;
  }

  void _paintChips(
    Canvas canvas,
    Offset center,
    double ringRadius,
    double chipRadius,
  ) {
    for (var index = 0; index < slots.length; index++) {
      final slot = slots[index];
      final isActive = index == activeIndex;
      final offset = roscoLetterOffset(
        center: center,
        radius: ringRadius,
        index: index,
        count: slots.length,
      );
      final radius = chipRadius * _scaleFor(index);
      final fill = _fillFor(slot.status);

      if (popped.contains(index) && pop < 1) {
        // A ripple leaving the letter, fading as it grows — the result
        // spreading out from where it happened.
        canvas.drawCircle(
          offset,
          radius * (1 + 0.9 * pop),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = chipRadius * 0.18 * (1 - pop)
            ..color = fill.withValues(alpha: 0.6 * (1 - pop)),
        );
      }

      canvas.drawCircle(offset, radius, Paint()..color = fill);

      _paintText(
        canvas,
        offset,
        slot.letter,
        // A pending chip is a quiet outline, so the resolved ones carry the
        // colour and the eye reads progress at a glance.
        switch (slot.status) {
          LetterStatus.pending => pendingLabel,
          LetterStatus.active => onActive,
          _ => onFill,
        },
        radius * 0.95,
        bold: isActive,
      );
    }
  }

  /// The countdown in the middle, sized to the wheel rather than fixed: a
  /// fixed size crowds the ring on a small wheel — a phone on its side — and
  /// looks lost in a large one.
  void _paintCenter(Canvas canvas, Offset center, double extent) {
    _paintText(
      canvas,
      center,
      centerLabel,
      Color.lerp(centerColor, wrong, _urgency)!,
      (extent * 0.14).clamp(16.0, 56.0),
      bold: true,
    );
  }

  Color _fillFor(LetterStatus status) => switch (status) {
    LetterStatus.correct => correct,
    LetterStatus.wrong => wrong,
    LetterStatus.passed => passed,
    LetterStatus.active => active,
    LetterStatus.pending => pending,
  };

  void _paintText(
    Canvas canvas,
    Offset center,
    String text,
    Color color,
    double size, {
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: typography.textMd.copyWith(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(RoscoWheelPainter old) =>
      old.activeIndex != activeIndex ||
      old.move != move ||
      old.pop != pop ||
      old.letterProgress != letterProgress ||
      old.centerLabel != centerLabel ||
      old.correct != correct ||
      old.active != active ||
      !_sameStatuses(old.slots);

  bool _sameStatuses(List<LetterSlot> other) {
    if (other.length != slots.length) return false;
    for (var index = 0; index < slots.length; index++) {
      if (other[index].status != slots[index].status) return false;
    }
    return true;
  }
}
