import 'package:flutter/widgets.dart';

import 'base_colors.dart';
import 'primitive_colors.dart';

/// The raw colour ramps every semantic token resolves to.
///
/// Only the ramps this template's tokens use are kept. Add your own the
/// same way — a [PrimitiveColors] ramp per hue — and reference them from the
/// token families rather than from widgets.
final class AppColorPalette {
  AppColorPalette._();

  static const base = BaseColors(
    white: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
    transparent: Color(0x00FFFFFF),
  );

  static const grayLight = PrimitiveColors(
    w25: Color(0xFFFDFDFD),
    w50: Color(0xFFFAFAFA),
    w100: Color(0xFFF5F5F5),
    w200: Color(0xFFE9EAEB),
    w300: Color(0xFFD5D7DA),
    w400: Color(0xFFA4A7AE),
    w500: Color(0xFF717680),
    w600: Color(0xFF535862),
    w700: Color(0xFF414651),
    w800: Color(0xFF252B37),
    w900: Color(0xFF181D27),
    w950: Color(0xFF0A0D12),
  );

  static const grayDark = PrimitiveColors(
    w25: Color(0xFFFAFAFA),
    w50: Color(0xFFF7F7F7),
    w100: Color(0xFFF0F0F1),
    w200: Color(0xFFECECED),
    w300: Color(0xFFCECFD2),
    w400: Color(0xFF94979C),
    w500: Color(0xFF85888E),
    w600: Color(0xFF61656C),
    w700: Color(0xFF373A41),
    w800: Color(0xFF22262F),
    w900: Color(0xFF13161B),
    w950: Color(0xFF0C0E12),
  );

  static const brand = PrimitiveColors(
    w25: Color(0xFFFCFAFF),
    w50: Color(0xFFF9F5FF),
    w100: Color(0xFFF4EBFF),
    w200: Color(0xFFE9D7FE),
    w300: Color(0xFFD6BBFB),
    w400: Color(0xFFB692F6),
    w500: Color(0xFF9E77ED),
    w600: Color(0xFF7F56D9),
    w700: Color(0xFF6941C6),
    w800: Color(0xFF53389E),
    w900: Color(0xFF42307D),
    w950: Color(0xFF2C1C5F),
  );

  /// Green ramp — an answer that landed.
  static const success = PrimitiveColors(
    w25: Color(0xFFF6FEF9),
    w50: Color(0xFFECFDF3),
    w100: Color(0xFFDCFAE6),
    w200: Color(0xFFABEFC6),
    w300: Color(0xFF75E0A7),
    w400: Color(0xFF47CD89),
    w500: Color(0xFF17B26A),
    w600: Color(0xFF079455),
    w700: Color(0xFF067647),
    w800: Color(0xFF085D3A),
    w900: Color(0xFF074D31),
    w950: Color(0xFF053321),
  );

  /// Amber ramp — a letter deferred, not lost.
  static const warning = PrimitiveColors(
    w25: Color(0xFFFFFCF5),
    w50: Color(0xFFFFFAEB),
    w100: Color(0xFFFEF0C7),
    w200: Color(0xFFFEDF89),
    w300: Color(0xFFFEC84B),
    w400: Color(0xFFFDB022),
    w500: Color(0xFFF79009),
    w600: Color(0xFFDC6803),
    w700: Color(0xFFB54708),
    w800: Color(0xFF93370D),
    w900: Color(0xFF7A2E0E),
    w950: Color(0xFF4E1D09),
  );

  static const error = PrimitiveColors(
    w25: Color(0xFFFFFBFA),
    w50: Color(0xFFFEF3F2),
    w100: Color(0xFFFEE4E2),
    w200: Color(0xFFFECDCA),
    w300: Color(0xFFFDA29B),
    w400: Color(0xFFF97066),
    w500: Color(0xFFF04438),
    w600: Color(0xFFD92D20),
    w700: Color(0xFFB42318),
    w800: Color(0xFF912018),
    w900: Color(0xFF7A271A),
    w950: Color(0xFF55160C),
  );

  /// Teal ramp — an accent.
  static const teal = PrimitiveColors(
    w25: Color(0xFFF6FEFC),
    w50: Color(0xFFF0FDF9),
    w100: Color(0xFFCCFBEF),
    w200: Color(0xFF99F6E0),
    w300: Color(0xFF5FE9D0),
    w400: Color(0xFF2ED3B7),
    w500: Color(0xFF15B79E),
    w600: Color(0xFF0E9384),
    w700: Color(0xFF107569),
    w800: Color(0xFF125D56),
    w900: Color(0xFF134E48),
    w950: Color(0xFF0A2926),
  );

  /// Blue ramp — an accent.
  static const blue = PrimitiveColors(
    w25: Color(0xFFF5FAFF),
    w50: Color(0xFFEFF8FF),
    w100: Color(0xFFD1E9FF),
    w200: Color(0xFFB2DDFF),
    w300: Color(0xFF84CAFF),
    w400: Color(0xFF53B1FD),
    w500: Color(0xFF2E90FA),
    w600: Color(0xFF1570EF),
    w700: Color(0xFF175CD3),
    w800: Color(0xFF1849A9),
    w900: Color(0xFF194185),
    w950: Color(0xFF102A56),
  );

  /// Indigo ramp — an accent.
  static const indigo = PrimitiveColors(
    w25: Color(0xFFF5F8FF),
    w50: Color(0xFFEEF4FF),
    w100: Color(0xFFE0EAFF),
    w200: Color(0xFFC7D7FE),
    w300: Color(0xFFA4BCFD),
    w400: Color(0xFF8098F9),
    w500: Color(0xFF6172F3),
    w600: Color(0xFF444CE7),
    w700: Color(0xFF3538CD),
    w800: Color(0xFF2D31A6),
    w900: Color(0xFF2D3282),
    w950: Color(0xFF1F235B),
  );

  /// Fuchsia ramp — an accent.
  static const fuchsia = PrimitiveColors(
    w25: Color(0xFFFEFAFF),
    w50: Color(0xFFFDF4FF),
    w100: Color(0xFFFBE8FF),
    w200: Color(0xFFF6D0FE),
    w300: Color(0xFFEEAAFD),
    w400: Color(0xFFE478FA),
    w500: Color(0xFFD444F1),
    w600: Color(0xFFBA24D5),
    w700: Color(0xFF9F1AB1),
    w800: Color(0xFF821890),
    w900: Color(0xFF6F1877),
    w950: Color(0xFF47104C),
  );

  /// Orange ramp — an accent.
  static const orange = PrimitiveColors(
    w25: Color(0xFFFEFAF5),
    w50: Color(0xFFFEF6EE),
    w100: Color(0xFFFDEAD7),
    w200: Color(0xFFF9DBAF),
    w300: Color(0xFFF7B27A),
    w400: Color(0xFFF38744),
    w500: Color(0xFFEF6820),
    w600: Color(0xFFE04F16),
    w700: Color(0xFFB93815),
    w800: Color(0xFF932F19),
    w900: Color(0xFF772917),
    w950: Color(0xFF511C10),
  );
}
