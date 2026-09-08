import 'app_locale.dart';

/// An interface defined by the localization module.
/// The host application must implement this to persist the language.
abstract interface class LocaleStorageDelegate {
  Future<AppLocale?> readLocale();
  Future<void> writeLocale(AppLocale appLocale);
}
