import 'package:flutter/widgets.dart';

import 'base/app_color_palette.dart';

/// Surface colours.
///
/// A deliberately small set: add the ones your product needs, following the
/// same `light()`/`dark()` pairing so every new token is defined in both.
final class const AppBackgroundColorTokens({
  required final Color bgPrimary,
  required final Color bgSecondary,
  required final Color bgTertiary,
  required final Color bgBrand,
  required final Color bgDisabled,
  required final Color bgOverlay,
  required final Color bgError,
}) {
  factory AppBackgroundColorTokens.light() {
    return AppBackgroundColorTokens(
      bgPrimary: AppColorPalette.base.white,
      bgSecondary: AppColorPalette.grayLight.w50,
      bgTertiary: AppColorPalette.grayLight.w100,
      bgBrand: AppColorPalette.brand.w600,
      bgDisabled: AppColorPalette.grayLight.w100,
      bgOverlay: AppColorPalette.grayLight.w950,
      bgError: AppColorPalette.error.w50,
    );
  }

  factory AppBackgroundColorTokens.dark() {
    return AppBackgroundColorTokens(
      bgPrimary: AppColorPalette.grayDark.w950,
      bgSecondary: AppColorPalette.grayDark.w900,
      bgTertiary: AppColorPalette.grayDark.w800,
      bgBrand: AppColorPalette.brand.w500,
      bgDisabled: AppColorPalette.grayDark.w800,
      bgOverlay: AppColorPalette.grayDark.w800,
      bgError: AppColorPalette.error.w500,
    );
  }
}
