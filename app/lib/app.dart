import 'package:app_localization/app_localization.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// {@template root_app}
/// The root widget. Rename it after your own app.
///
/// It deliberately uses [WidgetsApp] rather than `MaterialApp`: theming comes
/// from `AppThemeScope` and the design-system tokens, not from `ThemeData`.
/// {@endtemplate}
class RootApp({
  required final RouterConfig<Object> routerConfig,
  required final Locale locale,
  required final List<Locale> supportedLocales,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mediaData = MediaQuery.of(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    const basePixelRatio = 3;
    final densityRatio = pixelRatio / basePixelRatio;
    final clampedDensityRatio = densityRatio.clamp(1.0, 1.3);

    // The user's font size setting is **respected, within bounds**.
    //
    // This used to pass the same value as both the minimum and the maximum,
    // which pins the scale and throws the setting away: at Android's largest
    // font size the app rendered exactly as it does at the smallest. That is
    // the single biggest accessibility problem an app can have, and it is
    // invisible to anyone who has never turned the setting up.
    //
    // The floor still normalises for pixel density, so the design holds its
    // proportions across devices. The ceiling is what protects the layout —
    // and the screens are built to give way before they reach it: the wheel
    // yields its space, a long clue scrolls, and rows that reserve height use
    // a minimum rather than a fixed one.
    const maxUserScale = 1.5;

    return MediaQuery(
      data: mediaData.copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: clampedDensityRatio,
          maxScaleFactor: clampedDensityRatio * maxUserScale,
        ),
      ),
      child: WidgetsApp.router(
        color: context.backgroundColors.bgPrimary,
        debugShowCheckedModeBanner: kDebugMode,
        routerConfig: routerConfig,
        supportedLocales: supportedLocales,
        locale: locale,
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
      ),
    );
  }
}
