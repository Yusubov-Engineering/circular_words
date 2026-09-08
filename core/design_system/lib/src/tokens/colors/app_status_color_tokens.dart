import 'package:flutter/widgets.dart';

import 'base/app_color_palette.dart';

/// Colours for a thing's *state* rather than its place in the layout.
///
/// Named for the meaning, not the use: a game marks a letter correct with
/// [statusSuccess] and a form marks a saved field with the same token. Keeping
/// the names generic is what stops this family growing one entry per feature.
///
/// Every value is defined in **both** factories below — a token that exists in
/// only one theme is a bug that shows up as an invisible element at night.
final class const AppStatusColorTokens({
  required final Color statusSuccess,
  required final Color statusWarning,
  required final Color statusDanger,
  required final Color statusInfo,
  required final Color statusNeutral,

  /// Text and icons drawn on top of any of the fills above.
  required final Color statusOnFill,
}) {
  factory AppStatusColorTokens.light() {
    return AppStatusColorTokens(
      statusSuccess: AppColorPalette.success.w500,
      statusWarning: AppColorPalette.warning.w500,
      statusDanger: AppColorPalette.error.w500,
      statusInfo: AppColorPalette.brand.w500,
      statusNeutral: AppColorPalette.grayLight.w200,
      statusOnFill: AppColorPalette.base.white,
    );
  }

  factory AppStatusColorTokens.dark() {
    return AppStatusColorTokens(
      // A step brighter than the light theme: these sit on a near-black
      // ground, where the mid ramp reads muddy.
      statusSuccess: AppColorPalette.success.w400,
      statusWarning: AppColorPalette.warning.w400,
      statusDanger: AppColorPalette.error.w400,
      statusInfo: AppColorPalette.brand.w400,
      statusNeutral: AppColorPalette.grayDark.w700,
      statusOnFill: AppColorPalette.grayDark.w950,
    );
  }
}
