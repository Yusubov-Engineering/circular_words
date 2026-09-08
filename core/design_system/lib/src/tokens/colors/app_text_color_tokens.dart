import 'package:flutter/widgets.dart';

import 'base/app_color_palette.dart';

/// Text colours.
final class const AppTextColorTokens({
  required final Color textPrimary,
  required final Color textSecondary,
  required final Color textTertiary,
  required final Color textPlaceHolder,
  required final Color textDisabled,
  required final Color textBrand,
  required final Color textError,
}) {
  factory AppTextColorTokens.light() {
    return AppTextColorTokens(
      textPrimary: AppColorPalette.grayLight.w900,
      textSecondary: AppColorPalette.grayLight.w700,
      textTertiary: AppColorPalette.grayLight.w600,
      textPlaceHolder: AppColorPalette.grayLight.w500,
      textDisabled: AppColorPalette.grayLight.w500,
      textBrand: AppColorPalette.brand.w900,
      textError: AppColorPalette.error.w600,
    );
  }

  factory AppTextColorTokens.dark() {
    return AppTextColorTokens(
      textPrimary: AppColorPalette.grayDark.w50,
      textSecondary: AppColorPalette.grayDark.w300,
      textTertiary: AppColorPalette.grayDark.w400,
      textPlaceHolder: AppColorPalette.grayDark.w400,
      textDisabled: AppColorPalette.grayDark.w500,
      textBrand: AppColorPalette.grayDark.w50,
      textError: AppColorPalette.error.w400,
    );
  }
}
