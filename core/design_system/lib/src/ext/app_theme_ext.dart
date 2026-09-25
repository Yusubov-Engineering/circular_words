import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_accent_scope.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_mode.dart';
import '../theme/app_theme_scope.dart';
import '../theme/app_theme_scope_wrapper.dart';
import '../tokens/colors/app_accent_color_tokens.dart';
import '../tokens/colors/app_background_color_tokens.dart';
import '../tokens/colors/app_border_color_tokens.dart';
import '../tokens/colors/app_foreground_color_tokens.dart';
import '../tokens/colors/app_status_color_tokens.dart';
import '../tokens/colors/app_text_color_tokens.dart';
import '../tokens/motion/app_motion_tokens.dart';
import '../tokens/radius/app_radius_tokens.dart';
import '../tokens/size/app_size_tokens.dart';
import '../tokens/spacing/app_spacing_tokens.dart';
import '../tokens/typography/app_typography.dart';

extension AppThemeExt on BuildContext {
  AppTheme get appTheme => AppThemeScope.of(this).appTheme;

  /// The theme mode currently selected, as opposed to the resolved theme.
  AppThemeMode get themeMode => AppThemeScope.of(this).appThemeMode;

  /// The accent for this part of the tree: the nearest `AppAccentScope`'s,
  /// else the theme's brand accent.
  AppAccentColorTokens get accentColors {
    final accent = AppAccentScope.maybeOf(this);
    return accent == null
        ? appTheme.accentColorTokens
        : AppAccentColorTokens.of(accent, appTheme.brightness);
  }

  AppBackgroundColorTokens get backgroundColors =>
      appTheme.backgroundColorTokens;

  AppBorderColorTokens get borderColors => appTheme.borderColorTokens;

  AppForegroundColorTokens get foregroundColors =>
      appTheme.foregroundColorTokens;

  AppStatusColorTokens get statusColors => appTheme.statusColorTokens;

  AppTextColorTokens get textColors => appTheme.textColorTokens;

  AppRadiusTokens get radii => appTheme.radiusTokens;

  AppSizeTokens get sizes => appTheme.sizeTokens;

  AppSpacingTokens get spacing => appTheme.spacingTokens;

  AppTypography get typography => appTheme.typography;

  /// The motion tokens — reduced ones when the platform asks for less motion,
  /// so every animation built from them honours the setting for free.
  AppMotionTokens get motion =>
      MediaQuery.maybeDisableAnimationsOf(this) ?? false
      ? AppMotionTokens.reduced()
      : appTheme.motionTokens;

  void changeToLightTheme() =>
      AppThemeScopeWrapper.of(this)?.changeTo(AppThemeMode.light);

  void changeToDarkTheme() =>
      AppThemeScopeWrapper.of(this)?.changeTo(AppThemeMode.dark);

  void changeToSystemTheme() =>
      AppThemeScopeWrapper.of(this)?.changeTo(AppThemeMode.system);
}
