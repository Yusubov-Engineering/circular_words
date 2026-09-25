import 'package:flutter/widgets.dart';

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

final class const AppTheme({
  required final Brightness brightness,
  required final AppAccentColorTokens accentColorTokens,
  required final AppBackgroundColorTokens backgroundColorTokens,
  required final AppBorderColorTokens borderColorTokens,
  required final AppForegroundColorTokens foregroundColorTokens,
  required final AppStatusColorTokens statusColorTokens,
  required final AppTextColorTokens textColorTokens,
  required final AppRadiusTokens radiusTokens,
  required final AppSizeTokens sizeTokens,
  required final AppSpacingTokens spacingTokens,
  required final AppTypography typography,
  required final AppMotionTokens motionTokens,
}) {
  factory AppTheme.light() {
    return AppTheme(
      brightness: Brightness.light,
      accentColorTokens: .light(AppAccent.brand),
      backgroundColorTokens: .light(),
      borderColorTokens: .light(),
      foregroundColorTokens: .light(),
      statusColorTokens: .light(),
      textColorTokens: .light(),
      radiusTokens: .regular(),
      sizeTokens: .regular(),
      spacingTokens: .regular(),
      typography: .regular(),
      motionTokens: .regular(),
    );
  }

  factory AppTheme.dark() {
    return AppTheme(
      brightness: Brightness.dark,
      accentColorTokens: .dark(AppAccent.brand),
      backgroundColorTokens: .dark(),
      borderColorTokens: .dark(),
      foregroundColorTokens: .dark(),
      statusColorTokens: .dark(),
      textColorTokens: .dark(),
      radiusTokens: .regular(),
      sizeTokens: .regular(),
      spacingTokens: .regular(),
      typography: .regular(),
      motionTokens: .regular(),
    );
  }
}
