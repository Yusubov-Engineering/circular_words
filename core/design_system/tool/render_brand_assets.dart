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
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _out = Directory('../../app/assets/brand');

Future<void> _render(
  String name,
  int pixels,
  void Function(Canvas canvas, Size size) paint,
) async {
  final size = Size.square(pixels.toDouble());
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder, Offset.zero & size), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(pixels, pixels);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('${_out.path}/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $name ($pixels px)');
}

void main() {
  testWidgets('render brand assets', (tester) async {
    await tester.runAsync(() async {
      _out.createSync(recursive: true);

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
