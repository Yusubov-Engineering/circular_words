import 'package:flutter/widgets.dart';

import '../app_localization.dart';

extension AppLocalizationsExt on BuildContext {
  AppLocalizations get localization => AppLocalizations.of(this)!;

  /// The language currently selected in the app.
  AppLocale get appLocale => AppLocaleScope.of(this).appLocale;

  /// Switches the app to [appLocale] and persists the choice.
  void changeAppLocale(AppLocale appLocale) =>
      AppLocaleScopeWrapper.of(this)?.changeTo(appLocale);
}
