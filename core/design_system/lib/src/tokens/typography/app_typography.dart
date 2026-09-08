import 'package:flutter/widgets.dart';

import 'figma_text_style.dart';

/// The type scale.
///
/// `figmaTextStyle` converts Figma's line-height and letter-spacing values
/// into Flutter's, so a token can be copied straight off a design.
final class const AppTypography({
  required final TextStyle displayMd,
  required final TextStyle displaySm,
  required final TextStyle textLg,
  required final TextStyle textMd,
  required final TextStyle textSm,
  required final TextStyle textXs,
}) {
  factory regular() {
    return AppTypography(
      displayMd: figmaTextStyle(
        fontSize: 36,
        lineHeight: 44,
        letterSpacingPercent: -2,
      ),
      displaySm: figmaTextStyle(
        fontSize: 30,
        lineHeight: 38,
        letterSpacingPercent: 0,
      ),
      textLg: figmaTextStyle(
        fontSize: 18,
        lineHeight: 28,
        letterSpacingPercent: 0,
      ),
      textMd: figmaTextStyle(
        fontSize: 16,
        lineHeight: 24,
        letterSpacingPercent: 0,
      ),
      textSm: figmaTextStyle(
        fontSize: 14,
        lineHeight: 20,
        letterSpacingPercent: 0,
      ),
      textXs: figmaTextStyle(
        fontSize: 12,
        lineHeight: 18,
        letterSpacingPercent: 0,
      ),
    );
  }
}
