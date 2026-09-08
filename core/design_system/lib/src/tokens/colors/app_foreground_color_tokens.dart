import 'package:flutter/widgets.dart';

import 'base/app_color_palette.dart';

/// Icon and other non-text foreground colours.
final class const AppForegroundColorTokens({
  required final Color fgPrimary,
  required final Color fgSecondary,
  required final Color fgTertiary,
  required final Color fgWhite,
  required final Color fgBrand,
  required final Color fgDisabled,
  required final Color fgError,
}) {
  factory AppForegroundColorTokens.light() {
    return AppForegroundColorTokens(
      fgPrimary: AppColorPalette.grayLight.w900,
      fgSecondary: AppColorPalette.grayLight.w700,
      fgTertiary: AppColorPalette.grayLight.w600,
      fgWhite: AppColorPalette.base.white,
      fgBrand: AppColorPalette.brand.w600,
      fgDisabled: AppColorPalette.grayLight.w400,
      fgError: AppColorPalette.error.w600,
    );
  }

  factory AppForegroundColorTokens.dark() {
    return AppForegroundColorTokens(
      fgPrimary: AppColorPalette.base.white,
      fgSecondary: AppColorPalette.grayDark.w300,
      fgTertiary: AppColorPalette.grayDark.w400,
      fgWhite: AppColorPalette.base.white,
      fgBrand: AppColorPalette.brand.w500,
      fgDisabled: AppColorPalette.grayDark.w500,
      fgError: AppColorPalette.error.w500,
    );
  }
}
