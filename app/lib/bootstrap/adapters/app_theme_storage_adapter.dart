import 'package:design_system/design_system.dart';
import 'package:storage_api/storage_api.dart';

final class AppThemeStorageAdapter({
  required final StandardStorageApi _standardStorage,
}) implements ThemeStorageDelegate {
  static const _kThemeModeKey = 'themeMode';

  @override
  Future<AppThemeMode?> readThemeMode() async {
    final themeName = await _standardStorage.readString(key: _kThemeModeKey);

    if (themeName == null) return null;

    return AppThemeMode.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => AppThemeMode.system,
    );
  }

  @override
  Future<void> writeThemeMode(AppThemeMode themeMode) {
    return _standardStorage.writeString(
      key: _kThemeModeKey,
      value: themeMode.name,
    );
  }
}
