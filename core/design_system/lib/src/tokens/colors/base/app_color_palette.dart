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
}
