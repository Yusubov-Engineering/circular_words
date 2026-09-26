// Renders the app icon and splash images from `AppLogoPainter`.
//
//     cd core/design_system && flutter test tool/render_brand_assets.dart
//
// Then, from `app/`:
//
//     dart run flutter_launcher_icons
//     dart run flutter_native_splash:create
//
// Run through `flutter test` because that is where a headless renderer is:
// the painter draws exactly what the app draws, so the launcher icon, the
// splash and the in-app intro cannot drift apart. It lives in `tool/`, not
// `test/`, so `melos test` never runs it — it writes files.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _out = Directory('../../app/assets/brand');

Future<void> _render(
  String name,
  int pixels,
  void Function(Canvas canvas, Size size) paint,
) => _renderRect(name, pixels, pixels, paint);

Future<void> _renderRect(
  String name,
  int width,
  int height,
  void Function(Canvas canvas, Size size) paint,
) async {
  final size = Size(width.toDouble(), height.toDouble());
  final pixels = width;
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder, Offset.zero & size), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('${_out.path}/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $name ($pixels px)');
}

/// Loads the Roboto that ships with Flutter, so text renders as text rather
/// than the test renderer's placeholder boxes. Apache-licensed, which is
/// what makes it fit for a store graphic.
Future<void> _loadRoboto() async {
  final fonts =
      '${Platform.environment['FLUTTER_ROOT']}'
      '/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final weight in ['Bold', 'Medium', 'Black']) {
    final bytes = File('$fonts/Roboto-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void _text(
  Canvas canvas,
  String text,
  Offset topLeft, {
  required double size,
  required FontWeight weight,
  required Color color,
}) {
  TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
    ..layout()
    ..paint(canvas, topLeft);
}

/// Play's 1024 x 500 feature graphic: the mark beside the name, on the
/// brand ground, with the level accents glowing behind.
void _paintFeatureGraphic(Canvas canvas, Size size) {
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF160C33), appLogoGround, Color(0xFF53389E)],
        stops: [0, 0.55, 1],
      ).createShader(rect),
  );
  for (final (center, radius, color) in [
    (const Offset(120, 60), 320.0, const Color(0xFF2ED3B7)),
    (const Offset(980, 80), 300.0, const Color(0xFFE478FA)),
    (const Offset(900, 520), 340.0, const Color(0xFFF38744)),
    (const Offset(260, 520), 300.0, const Color(0xFF53B1FD)),
  ]) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  canvas
    ..save()
    ..translate(60, 70);
  AppLogoPainter().paint(canvas, const Size.square(360));
  canvas.restore();

  _text(
    canvas,
    'Circular Words',
    const Offset(450, 168),
    size: 76,
    weight: FontWeight.w900,
    color: const Color(0xFFFFFFFF),
  );
  _text(
    canvas,
    'Say the word. Beat the circle.',
    const Offset(454, 262),
    size: 34,
    weight: FontWeight.w500,
    color: const Color(0xFFD6CCF5),
  );
}

void main() {
  testWidgets('render brand assets', (tester) async {
    await tester.runAsync(() async {
      _out.createSync(recursive: true);
      await _loadRoboto();

      // Play Store icon: 512 px, full bleed and opaque; Play rounds it.
      await _render(
        'play_icon_512.png',
        512,
        AppLogoPainter(withGround: true, markScale: 0.82).paint,
      );

      // Play Store feature graphic, shown above the listing.
      await _renderRect(
        'play_feature_graphic.png',
        1024,
        500,
        _paintFeatureGraphic,
      );

      // iOS app icon: full bleed and opaque. The platform rounds it.
      await _render(
        'icon.png',
        1024,
        AppLogoPainter(withGround: true, markScale: 0.82).paint,
      );

      // Android adaptive icon, in two layers. The launcher masks the
      // foreground to its middle ~61%, so the mark sits well inside that.
      await _render(
        'icon_foreground.png',
        1024,
        AppLogoPainter(markScale: 0.56).paint,
      );
      await _render('icon_background.png', 1024, (canvas, size) {
        final rect = Offset.zero & size;
        canvas.drawRect(
          rect,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF53389E), appLogoGround],
            ).createShader(rect),
        );
      });

      // Splash: the mark alone on transparent; the ground is the splash
      // colour. flutter_native_splash treats the image as 4x, so 768 px shows
      // at 192 pt — the size the in-app intro takes over at.
      await _render('splash.png', 768, AppLogoPainter().paint);

      // Android 12+ draws its own splash icon, 1152 px shown in a 768 px
      // circle; the mark has to fit that circle.
      await _render(
        'splash_android12.png',
        1152,
        AppLogoPainter(markScale: 0.64).paint,
      );
    });
  });
}
