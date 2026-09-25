import 'package:flutter/widgets.dart';

import '../ext/app_theme_ext.dart';
import '../ext/font_weight_ext.dart';
import 'app_pressable.dart';
import 'app_text.dart';

/// How loudly an [AppButton] asks to be pressed.
enum AppButtonVariant {
  /// The one action a screen is for. Filled with the accent.
  primary,

  /// An action beside the primary one. A tinted surface, never competing.
  secondary,

  /// A choice rather than an action — accent text and nothing else.
  quiet,
}

/// {@template app_button}
/// The app's button, in three volumes.
///
/// Colours come from `context.accentColors`, so a button inside an
/// `AppAccentScope` takes that scope's hue with no argument. Changes of
/// state — enabled, variant, accent — animate rather than snap.
/// {@endtemplate}
class const AppButton({
  required final String title,
  final VoidCallback? onTap,
  final bool enabled = true,
  final AppButtonVariant variant = AppButtonVariant.primary,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    final disabled = !enabled || onTap == null;

    final (fill, border, ink) = switch (variant) {
      _ when disabled && variant != AppButtonVariant.quiet => (
        context.backgroundColors.bgDisabled,
        context.borderColors.borderDisabledSubtle,
        context.foregroundColors.fgDisabled,
      ),
      _ when disabled => (
        context.backgroundColors.bgPrimary.withValues(alpha: 0),
        context.backgroundColors.bgPrimary.withValues(alpha: 0),
        context.textColors.textDisabled,
      ),
      AppButtonVariant.primary => (
        accent.accentSolid,
        accent.accentSolid,
        accent.accentOnSolid,
      ),
      AppButtonVariant.secondary => (
        accent.accentSoft,
        accent.accentSoftBorder,
        accent.accentText,
      ),
      AppButtonVariant.quiet => (
        context.backgroundColors.bgPrimary.withValues(alpha: 0),
        context.backgroundColors.bgPrimary.withValues(alpha: 0),
        accent.accentText,
      ),
    };

    final motion = context.motion;
    final vertical = variant == AppButtonVariant.quiet
        ? context.spacing.spacingSm
        : context.spacing.spacingLg;

    return AppPressable(
      onTap: onTap,
      enabled: enabled,
      semanticsLabel: title,
      child: AnimatedContainer(
        duration: motion.fast,
        curve: motion.standard,
        constraints: const BoxConstraints(minWidth: double.infinity),
        padding: EdgeInsets.symmetric(
          vertical: vertical,
          horizontal: context.spacing.spacingLg,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(context.radii.radiusXl),
          border: Border.all(color: border),
        ),
        child: AnimatedDefaultTextStyle(
          duration: motion.fast,
          curve: motion.standard,
          style: context.typography.textMd.semiBold.copyWith(color: ink),
          child: AppText(title: title, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
