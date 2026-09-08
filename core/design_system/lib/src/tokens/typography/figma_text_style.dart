import 'package:flutter/widgets.dart';

/// Helper function that accepts exact Figma values and returns a Flutter TextStyle
TextStyle figmaTextStyle({
  required double fontSize,
  required double lineHeight,
  required double letterSpacingPercent,
  FontWeight? fontWeight,
}) {
  return TextStyle(
    fontSize: fontSize,
    height: lineHeight / fontSize,
    letterSpacing: (letterSpacingPercent / 100) * fontSize,
    fontWeight: fontWeight,
  );
}
