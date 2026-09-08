import 'package:app_localization/app_localization.dart';
import 'package:storage_api/storage_api.dart';

final class AppLocaleStorageAdapter({
  required final StandardStorageApi _standardStorage,
}) implements LocaleStorageDelegate {
  static const _kLocaleKey = 'locale';

  @override
  Future<AppLocale?> readLocale() async {
    final languageCode = await _standardStorage.readString(key: _kLocaleKey);

    if (languageCode == null) return null;

    return AppLocale.fromLanguageCode(languageCode);
  }

  @override
  Future<void> writeLocale(AppLocale appLocale) {
    return _standardStorage.writeString(
      key: _kLocaleKey,
      value: appLocale.name,
    );
  }
}
