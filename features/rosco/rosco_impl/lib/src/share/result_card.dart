import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

import '../domain/letter_slot.dart';
import '../domain/word_entry.dart';
import '../domain/word_set.dart';
import '../result/result_controller.dart';
import '../rosco/widgets/rosco_wheel.dart';

/// The colours a result card is drawn in.
///
/// Resolved from the theme by the caller and passed in, because the card is
/// painted outside any widget tree and so has no `BuildContext` to read them
/// from itself.
final class const ResultCardColors({
  required final Color background,
  required final Color surface,
  required final Color title,
  required final Color muted,
  required final Color accentSolid,
  required final Color accentOnSolid,
  required final Color accentSoft,
  required final Color correct,
  required final Color missed,
  required final Color neutral,
  required final Color onFill,
  required final Color track,
}) {
  factory ResultCardColors.of(BuildContext context) {
    final status = context.statusColors;
    final accent = context.accentColors;

    return ResultCardColors(
      background: accent.accentSoft,
      surface: context.backgroundColors.bgPrimary,
      title: context.textColors.textPrimary,
      muted: context.textColors.textTertiary,
      accentSolid: accent.accentSolid,
      accentOnSolid: accent.accentOnSolid,
      accentSoft: accent.accentSoft,
      correct: status.statusSuccess,
      missed: status.statusDanger,
      neutral: status.statusNeutral,
      onFill: status.statusOnFill,
      track: context.borderColors.borderSecondary,
    );
  }
}

/// Square-ish, the shape every feed and story crops cleanly: 4:5 is the
/// tallest Instagram's feed shows uncropped, and a story letterboxes it.
const resultCardSize = Size(1080, 1350);

/// Paints a shareable picture of [result] and encodes it as PNG.
///
/// The wheel is the round's own painter, so the card shows exactly what the
/// player saw — green where they found the word, red where they did not —
/// with the score in the middle. When the round's letters could not be read
/// back, the wheel is drawn neutral and the score still stands.
Future<Uint8List> renderResultCard({
  required ResultState result,
  required ResultCardColors colors,
  required AppTypography typography,
  required String appName,

  /// A sentence under the wheel — the score in words, in the player's
  /// language.
  required String caption,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  const size = resultCardSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Offset.zero & size);

  canvas.drawRect(Offset.zero & size, Paint()..color = colors.background);

  // A white card inset on the accent, so the image reads as a card on any
  // app's background, dark or light.
  const margin = 64.0;
  final card = RRect.fromRectAndRadius(
    const Rect.fromLTWH(margin, margin, 1080 - margin * 2, 1350 - margin * 2),
    const Radius.circular(56),
  );
  canvas.drawRRect(card, Paint()..color = colors.surface);

  _text(
    canvas,
    appName,
    Offset(size.width / 2, 170),
    typography.textLg.copyWith(
      fontSize: 52,
      fontWeight: FontWeight.w700,
      color: colors.title,
    ),
    TextDirection.ltr,
  );
  _badge(
    canvas,
    result.level.label,
    Offset(size.width / 2, 262),
    colors,
    typography,
  );

  final letters = result.letters;
  final slots = [
    for (var index = 0; index < WordSet.letterCount; index++)
      LetterSlot(
        entry: _placeholderEntry(index, letters),
        status: switch (letters) {
          null => LetterStatus.pending,
          final known =>
            known[index].answered ? LetterStatus.correct : LetterStatus.wrong,
        },
      ),
  ];

  const wheelExtent = 760.0;
  canvas
    ..save()
    ..translate((size.width - wheelExtent) / 2, 340);
  RoscoWheelPainter(
    slots: slots,
    activeIndex: -1,
    previousActive: null,
    move: 1,
    popped: const {},
    pop: 1,
    // A full, calm ring around the score. At zero the wheel reads the letter
    // as out of time and turns the score red — the opposite of the message.
    letterProgress: 1,
    centerLabel: '${result.score.correct}/${result.score.total}',
    correct: colors.correct,
    wrong: colors.missed,
    passed: colors.neutral,
    active: colors.accentSolid,
    onActive: colors.accentOnSolid,
    pending: colors.neutral,
    onFill: colors.onFill,
    pendingLabel: colors.muted,
    centerColor: colors.title,
    track: colors.track,
    typography: typography,
  ).paint(canvas, const Size.square(wheelExtent));
  canvas.restore();

  _text(
    canvas,
    caption,
    Offset(size.width / 2, 1170),
    typography.textLg.copyWith(fontSize: 44, color: colors.muted),
    textDirection,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  picture.dispose();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  return bytes!.buffer.asUint8List();
}

/// The wheel paints each slot's letter, so a slot needs an entry even when
/// the round's words are unknown — the letter is all that is drawn.
WordEntry _placeholderEntry(int index, List<ResultLetter>? letters) =>
    letters?[index].entry ??
    WordEntry(letter: WordSet.alphabet[index], word: '', definition: '');

void _badge(
  Canvas canvas,
  String label,
  Offset center,
  ResultCardColors colors,
  AppTypography typography,
) {
  final painter = _layout(
    label,
    typography.textMd.copyWith(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: colors.accentOnSolid,
    ),
  );
  final pill = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: center,
      width: painter.width + 64,
      height: painter.height + 28,
    ),
    const Radius.circular(999),
  );
  canvas.drawRRect(pill, Paint()..color = colors.accentSolid);
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

void _text(
  Canvas canvas,
  String text,
  Offset center,
  TextStyle style,
  TextDirection direction,
) {
  final painter = _layout(text, style, direction);
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

TextPainter _layout(
  String text,
  TextStyle style, [
  TextDirection direction = TextDirection.ltr,
]) => TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: direction,
  textAlign: TextAlign.center,
)..layout();
