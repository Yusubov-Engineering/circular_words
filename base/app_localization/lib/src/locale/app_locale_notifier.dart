import 'package:flutter/foundation.dart';

import 'app_locale.dart';

/// {@template app_locale_notifier}
/// The single source of truth for the language the app runs in.
///
/// It lives in the dependency container rather than in the widget tree, so
/// that code without a `BuildContext` — a network interceptor, for instance —
/// can read the selected language at any time.
/// {@endtemplate}
abstract interface class AppLocaleNotifier implements Listenable {
  /// The language currently selected.
  AppLocale get locale;

  /// Switches the app to [appLocale] and persists the choice.
  Future<void> changeTo(AppLocale appLocale);
}
