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
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final status = context.statusColors;

    // A `CustomPaint` contributes nothing to the semantics tree, so to a
    // screen reader this — the entire subject of the screen — is a blank
    // rectangle. The label carries the letter, the clock and the score, which
    // is everything the picture is showing.
    return Semantics(
      label: semanticsLabel,
      readOnly: true,
      child: AspectRatio(
        aspectRatio: 1,
        // The arc sweeps smoothly between ticks instead of jumping once a
        // second, which is the difference between a clock and a stutter.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: letterProgress, end: letterProgress),
          duration: const Duration(milliseconds: 320),
          builder: (context, progress, _) => CustomPaint(
            painter: _RoscoWheelPainter(
              slots: slots,
              activeIndex: activeIndex,
              letterProgress: progress,
              centerLabel: centerLabel,
              correct: status.statusSuccess,
              wrong: status.statusDanger,
              passed: status.statusWarning,
              active: status.statusInfo,
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
    );
  }
}

class _RoscoWheelPainter extends CustomPainter {
  _RoscoWheelPainter({
    required this.slots,
    required this.activeIndex,
    required this.letterProgress,
    required this.centerLabel,
    required this.correct,
    required this.wrong,
    required this.passed,
    required this.active,
    required this.pending,
    required this.onFill,
    required this.pendingLabel,
    required this.centerColor,
    required this.track,
    required this.typography,
  });

  final List<LetterSlot> slots;
  final int activeIndex;
  final double letterProgress;
  final String centerLabel;
  final Color correct;
  final Color wrong;
  final Color passed;
  final Color active;
  final Color pending;
  final Color onFill;
  final Color pendingLabel;
  final Color centerColor;
  final Color track;
  final AppTypography typography;

  /// The active chip is drawn this much larger, so the eye finds it without
  /// relying on colour alone.
  static const _activeScale = 1.45;

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
    _paintCenter(canvas, center);
  }

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
        // Running out of time is the one moment the ring should alarm.
        ..color = letterProgress <= 0.3 ? wrong : active,
    );
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
      final radius = isActive ? chipRadius * _activeScale : chipRadius;

      canvas.drawCircle(offset, radius, Paint()..color = _fillFor(slot.status));

      _paintText(
        canvas,
        offset,
        slot.letter,
        // A pending chip is a quiet outline, so the resolved ones carry the
        // colour and the eye reads progress at a glance.
        slot.status == LetterStatus.pending ? pendingLabel : onFill,
        radius * 0.95,
        bold: isActive,
      );
    }
  }

  void _paintCenter(Canvas canvas, Offset center) {
    _paintText(canvas, center, centerLabel, centerColor, 44, bold: true);
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
  bool shouldRepaint(_RoscoWheelPainter old) =>
      old.activeIndex != activeIndex ||
      old.letterProgress != letterProgress ||
      old.centerLabel != centerLabel ||
      old.correct != correct ||
      !_sameStatuses(old.slots);

  bool _sameStatuses(List<LetterSlot> other) {
    if (other.length != slots.length) return false;
    for (var index = 0; index < slots.length; index++) {
      if (other[index].status != slots[index].status) return false;
    }
    return true;
  }
}
