import 'dart:math';

import 'package:flutter/widgets.dart';

import '../tokens/colors/app_accent_color_tokens.dart';
import '../tokens/colors/base/app_color_palette.dart';

/// The ground the logo sits on in the icon and the splash: the deepest step
/// of the brand ramp, which every accent reads well against.
const appLogoGround = Color(0xFF2C1C5F);

/// {@template app_logo}
/// The Circular Words mark: the game's wheel in miniature.
///
/// Twenty-six dots in a ring, graded through the six level accents from cool
/// to warm, with the active letter picked out in white at the top — the
/// circle a round is played on. Three voice bars sit in the middle, because
/// the game is played by speaking.
///
/// Drawn rather than imported, and the single source of the brand: the app
/// icons and splash images are rendered from [AppLogoPainter] by
/// `tool/render_brand_assets.dart`, so the launcher, the splash and the app
/// can never disagree about what the logo is.
/// {@endtemplate}
class const AppLogo({
  final double size = 96,

  /// Where the white "active letter" sits around the ring, 0..1 clockwise
  /// from the top. Animating it sends the highlight round the wheel.
  final double highlight = 0,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: AppLogoPainter(highlight: highlight)),
  );
}

/// Paints the mark into the largest centred square of its canvas.
class AppLogoPainter extends CustomPainter {
  AppLogoPainter({
    this.highlight = 0,
    this.markScale = 1,
    this.withGround = false,
  });

  /// See [AppLogo.highlight].
  final double highlight;

  /// How much of the canvas the mark fills. Below 1 for icon shapes that a
  /// platform masks — an Android adaptive icon keeps only its middle.
  final double markScale;

  /// Whether to fill the canvas with the brand ground first, as an iOS app
  /// icon must: the platform rounds the corners, and a transparent icon
  /// becomes a black one.
  final bool withGround;

  static const _dots = 26;

  /// The level accents, cool to warm — the order the picker lists them in.
  static final _hues = [
    for (final accent in const [
      AppAccent.teal,
      AppAccent.blue,
      AppAccent.indigo,
      AppAccent.brand,
      AppAccent.fuchsia,
      AppAccent.orange,
    ])
      accent.ramp.w400,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final extent = size.shortestSide;
    final center = size.center(Offset.zero);

    if (withGround) {
      final rect = Offset.zero & size;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColorPalette.brand.w800, appLogoGround],
          ).createShader(rect),
      );
    }

    final mark = extent * markScale;
    final ringRadius = mark * 0.38;
    final dotRadius = mark * 0.042;
    final activeRadius = mark * 0.072;
    final lit = (highlight % 1) * _dots;

    for (var index = 0; index < _dots; index++) {
      final angle = -pi / 2 + 2 * pi * index / _dots;
      final offset = center + Offset(cos(angle), sin(angle)) * ringRadius;

      // How close the travelling highlight is to this dot, 0..1 — so it
      // glides between dots rather than jumping.
      final distance = (index - lit).abs();
      final wrapped = min(distance, _dots - distance);
      final glow = (1 - wrapped).clamp(0.0, 1.0);

      final hue = _hueAt(index / (_dots - 1));
      canvas.drawCircle(
        offset,
        dotRadius + (activeRadius - dotRadius) * glow,
        Paint()..color = Color.lerp(hue, const Color(0xFFFFFFFF), glow)!,
      );
    }

    _paintVoice(canvas, center, mark);
  }

  /// Three rounded bars, like a level meter — a voice, in the middle.
  void _paintVoice(Canvas canvas, Offset center, double mark) {
    final width = mark * 0.065;
    final gap = mark * 0.105;
    final paint = Paint()..color = const Color(0xFFFFFFFF);

    for (final (step, height) in [(-1, 0.15), (0, 0.29), (1, 0.19)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center + Offset(step * gap, 0),
            width: width,
            height: mark * height,
          ),
          Radius.circular(width / 2),
        ),
        paint,
      );
    }
  }

  /// The ring's colour at [t] (0..1), blended through the level hues.
  static Color _hueAt(double t) {
    final scaled = t * (_hues.length - 1);
    final low = scaled.floor().clamp(0, _hues.length - 1);
    final high = min(low + 1, _hues.length - 1);
    return Color.lerp(_hues[low], _hues[high], scaled - low)!;
  }

  @override
  bool shouldRepaint(AppLogoPainter old) =>
      old.highlight != highlight ||
      old.markScale != markScale ||
      old.withGround != withGround;
}
