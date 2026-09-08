import 'package:flutter/widgets.dart';

/// {@template app_locale}
/// The languages the app ships translations for.
/// {@endtemplate}
enum AppLocale {
  /// English — the template ARB every other language is translated from.
  en,

  /// Arabic. Right-to-left; `GlobalWidgetsLocalizations` flips the app for
  /// it, so nothing in the widget tree may hardcode a text direction.
  ar,

  /// Azerbaijani.
  az,

  /// Spanish.
  es,

  /// Russian.
  ru,

  /// Turkish.
  tr,

  /// Chinese (Simplified).
  zh;

  /// The [Locale] this language maps to.
  Locale get locale => Locale(name);

  /// The value sent to the backend, e.g. in the `Accept-Language` header.
  String get languageTag => name;

  /// The next language in [values], wrapping around at the end. Lets a
  /// language switcher cycle without naming each language, so adding one
  /// here needs no change at the call site.
  AppLocale get next => values[(index + 1) % values.length];

  /// The language whose code is [languageCode], or `null` when it is not
  /// one of the supported languages.
  static AppLocale? fromLanguageCode(String languageCode) {
    for (final appLocale in values) {
      if (appLocale.name == languageCode) return appLocale;
    }

    return null;
  }
}
