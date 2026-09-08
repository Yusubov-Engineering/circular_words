import 'app_theme_mode.dart';

/// An interface defined by the design system.
/// The host application must implement this to persist the theme.
abstract interface class ThemeStorageDelegate {
  Future<AppThemeMode?> readThemeMode();
  Future<void> writeThemeMode(AppThemeMode themeMode);
}
