import 'package:flutter/widgets.dart';

import 'base/app_color_palette.dart';
import 'base/primitive_colors.dart';

/// The hues a subtree can be tinted with.
///
/// An accent is *where* the player is, not *what* happened: status colours
/// keep meaning success and danger everywhere, while the accent is free to
/// change from one part of the app to the next. Named for the hue rather
/// than for a use, so a feature maps its own concepts onto it.
enum AppAccent {
  brand,
  teal,
  blue,
  indigo,
  fuchsia,
  orange;

  PrimitiveColors get ramp => switch (this) {
    brand => AppColorPalette.brand,
    teal => AppColorPalette.teal,
    blue => AppColorPalette.blue,
    indigo => AppColorPalette.indigo,
    fuchsia => AppColorPalette.fuchsia,
    orange => AppColorPalette.orange,
  };
}

/// Colours for whatever the current [AppAccent] is.
///
/// Built from a ramp rather than listed per accent, so every accent gets the
/// same five roles at the same contrast, and adding a hue is adding a ramp.
/// Read through `context.accentColors`, which honours the nearest
/// `AppAccentScope`.
final class const AppAccentColorTokens({
  /// A filled control or the element that is "on" — the primary button, the
  /// active letter.
  required final Color accentSolid,

  /// Text and icons drawn on [accentSolid].
  required final Color accentOnSolid,

  /// A tinted surface: a badge, a selected card.
  required final Color accentSoft,

  /// The outline of an [accentSoft] surface, and a pressed card's border.
  required final Color accentSoftBorder,

  /// Accent-coloured text and icons on an ordinary background.
  required final Color accentText,
}) {
  factory AppAccentColorTokens.light(AppAccent accent) {
    final ramp = accent.ramp;
    return AppAccentColorTokens(
      accentSolid: ramp.w600,
      accentOnSolid: AppColorPalette.base.white,
      accentSoft: ramp.w50,
      accentSoftBorder: ramp.w200,
      accentText: ramp.w700,
    );
  }

  factory AppAccentColorTokens.dark(AppAccent accent) {
    final ramp = accent.ramp;
    return AppAccentColorTokens(
      // Lighter fill with dark ink: white on a mid ramp fails contrast for the
      // brighter hues (teal, orange) on a near-black ground.
      accentSolid: ramp.w400,
      accentOnSolid: ramp.w950,
      accentSoft: ramp.w950,
      accentSoftBorder: ramp.w800,
      accentText: ramp.w300,
    );
  }

  /// Tokens for [accent] at [brightness].
  factory AppAccentColorTokens.of(AppAccent accent, Brightness brightness) =>
      brightness == Brightness.dark
      ? AppAccentColorTokens.dark(accent)
      : AppAccentColorTokens.light(accent);
}
