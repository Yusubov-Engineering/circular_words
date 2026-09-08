import 'package:flutter/widgets.dart';

import 'base/app_color_palette.dart';

/// Outline colours.
final class const AppBorderColorTokens({
  required final Color borderPrimary,
  required final Color borderSecondary,
  required final Color borderBrand,
  required final Color borderDisabled,
  required final Color borderDisabledSubtle,
  required final Color borderError,
}) {
  factory AppBorderColorTokens.light() {
    return AppBorderColorTokens(
      borderPrimary: AppColorPalette.grayLight.w300,
      borderSecondary: AppColorPalette.grayLight.w200,
      borderBrand: AppColorPalette.brand.w500,
      borderDisabled: AppColorPalette.grayLight.w300,
      borderDisabledSubtle: AppColorPalette.grayLight.w200,
      borderError: AppColorPalette.error.w500,
    );
  }

  factory AppBorderColorTokens.dark() {
    return AppBorderColorTokens(
      borderPrimary: AppColorPalette.grayDark.w700,
      borderSecondary: AppColorPalette.grayDark.w800,
      borderBrand: AppColorPalette.brand.w400,
      borderDisabled: AppColorPalette.grayDark.w700,
      borderDisabledSubtle: AppColorPalette.grayDark.w800,
      borderError: AppColorPalette.error.w400,
    );
  }
}
