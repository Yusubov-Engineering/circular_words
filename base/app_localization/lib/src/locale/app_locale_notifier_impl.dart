import 'package:flutter/foundation.dart';

import 'app_locale.dart';
import 'app_locale_notifier.dart';
import 'locale_storage_delegate.dart';

/// {@macro app_locale_notifier}
final class AppLocaleNotifierImpl({
  required final LocaleStorageDelegate _storageDelegate,
  final AppLocale _fallbackLocale = AppLocale.en,
}) extends ChangeNotifier implements AppLocaleNotifier {
  AppLocale? _locale;

  @override
  AppLocale get locale => _locale ?? _fallbackLocale;

  /// Loads the persisted language, falling back to the device language and
  /// then to [_fallbackLocale]. Must be awaited before the app is built, so
  /// the first frame is already in the right language.
  Future<void> restore() async {
    AppLocale? savedLocale;

    try {
      savedLocale = await _storageDelegate.readLocale();
    } catch (_) {}

    _emit(savedLocale ?? _deviceLocale ?? _fallbackLocale);
  }

  @override
  Future<void> changeTo(AppLocale appLocale) async {
    if (locale == appLocale) return;

    // A language the app cannot remember is still a language the user asked
    // for, so a failed write must not keep the app in the old one.
    try {
      await _storageDelegate.writeLocale(appLocale);
    } catch (_) {}

    _emit(appLocale);
  }

  /// The first device language the app has translations for, if any.
  AppLocale? get _deviceLocale {
    for (final locale in PlatformDispatcher.instance.locales) {
      final appLocale = AppLocale.fromLanguageCode(locale.languageCode);

      if (appLocale != null) return appLocale;
    }

    return null;
  }

  void _emit(AppLocale next) {
    if (_locale == next) return;

    _locale = next;
    notifyListeners();
  }
}
