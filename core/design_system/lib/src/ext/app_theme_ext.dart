import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../theme/app_theme_mode.dart';
import '../theme/app_theme_scope.dart';
import '../theme/app_theme_scope_wrapper.dart';
import '../tokens/colors/app_background_color_tokens.dart';
import '../tokens/colors/app_border_color_tokens.dart';
import '../tokens/colors/app_foreground_color_tokens.dart';
import '../tokens/colors/app_status_color_tokens.dart';
import '../tokens/colors/app_text_color_tokens.dart';
import '../tokens/radius/app_radius_tokens.dart';
import '../tokens/size/app_size_tokens.dart';
import '../tokens/spacing/app_spacing_tokens.dart';
import '../tokens/typography/app_typography.dart';

extension AppThemeExt on BuildContext {
  AppTheme get appTheme => AppThemeScope.of(this).appTheme;

  /// The theme mode currently selected, as opposed to the resolved theme.
  AppThemeMode get themeMode => AppThemeScope.of(this).appThemeMode;

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

  void changeToLightTheme() =>
      AppThemeScopeWrapper.of(this)?.changeTo(AppThemeMode.light);

  void changeToDarkTheme() =>
      AppThemeScopeWrapper.of(this)?.changeTo(AppThemeMode.dark);

  void changeToSystemTheme() =>
      AppThemeScopeWrapper.of(this)?.changeTo(AppThemeMode.system);
}
