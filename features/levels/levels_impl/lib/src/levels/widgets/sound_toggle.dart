import 'dart:async';

import 'package:app_localization/app_localization.dart';
import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:design_system/design_system.dart';
import 'package:feedback_api/feedback_api.dart';
import 'package:flutter/widgets.dart';

/// Turns the game's sound on and off.
///
/// Stateful and local: the preference lives in `GameFeedbackApi`, which reads
/// and writes it, so this holds nothing except the need to repaint. It reads
/// the current value on every build rather than caching one, which keeps it
/// honest if anything else ever changes the setting.
class SoundToggle extends StatefulWidget {
  const SoundToggle({super.key});

  @override
  State<SoundToggle> createState() => _SoundToggleState();
}

class _SoundToggleState extends State<SoundToggle> {
  GameFeedbackApi? _feedback;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final feedback = context.locator<GameFeedbackApi>();
    if (identical(feedback, _feedback)) return;
    _feedback = feedback;

    // Reading the stored preference is what this call is for here; the sounds
    // it also warms are a bonus on the screen before they are needed.
    unawaited(
      feedback.initialize().then((_) {
        if (mounted) setState(() {});
      }),
    );
  }

  Future<void> _toggle() async {
    final feedback = _feedback;
    if (feedback == null) return;

    await feedback.setMuted(muted: !feedback.isMuted);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final muted = _feedback?.isMuted ?? false;
    final l10n = context.localization;
    final label = muted ? l10n.soundOff : l10n.soundOn;

    return AppPressable(
      toggled: !muted,
      semanticsLabel: label,
      onTap: () => unawaited(_toggle()),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.spacingSm),
        child: SizedBox.square(
          dimension: context.sizes.size24,
          // The two glyphs cross-fade, keyed on the state, so the change reads
          // as the speaker switching rather than as a redraw.
          child: AppSwitcher(
            child: CustomPaint(
              key: ValueKey(muted),
              size: Size.square(context.sizes.size24),
              painter: _SpeakerPainter(
                color: muted
                    ? context.foregroundColors.fgDisabled
                    : context.accentColors.accentText,
                muted: muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A speaker, drawn rather than imported: the design system ships no icon set,
/// and one SVG is not a reason to start one.
class _SpeakerPainter extends CustomPainter {
  _SpeakerPainter({required this.color, required this.muted});

  final Color color;
  final bool muted;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 24;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * unit
      ..strokeCap = StrokeCap.round;

    // The cone.
    canvas.drawPath(
      Path()
        ..moveTo(3 * unit, 9 * unit)
        ..lineTo(7 * unit, 9 * unit)
        ..lineTo(12 * unit, 4 * unit)
        ..lineTo(12 * unit, 20 * unit)
        ..lineTo(7 * unit, 15 * unit)
        ..lineTo(3 * unit, 15 * unit)
        ..close(),
      fill,
    );

    if (muted) {
      // A cross, which reads as "off" without any colour at all — the state
      // must not rest on colour alone.
      canvas
        ..drawLine(
          Offset(16 * unit, 9 * unit),
          Offset(21 * unit, 15 * unit),
          stroke,
        )
        ..drawLine(
          Offset(21 * unit, 9 * unit),
          Offset(16 * unit, 15 * unit),
          stroke,
        );
      return;
    }

    // Two arcs of sound leaving it.
    for (final radius in [4.5, 8.0]) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(12 * unit, 12 * unit),
          radius: radius * unit,
        ),
        -0.9,
        1.8,
        false,
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_SpeakerPainter old) =>
      old.color != color || old.muted != muted;
}
