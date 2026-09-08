import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_theme.dart';
import 'app_theme_mode.dart';
import 'app_theme_scope.dart';
import 'theme_storage_delegate.dart';

/// {@template app_theme_scope_wrapper}
/// A class which handles all theme processes
///
/// initialize() method should be used as app starter in order to use
/// [AppTheme] in the app

/// {@endtemplate}
class const AppThemeScopeWrapper({
  required final Widget child,
  required final ThemeStorageDelegate storageDelegate,
  super.key,
}) extends StatefulWidget {
  @override
  State<AppThemeScopeWrapper> createState() => AppThemeScopeWrapperState();

  /// In order to use methods of [AppThemeScopeWrapper] this function
  /// should be called first. Theme change process will handled by
  /// [AppThemeScopeWrapper] automatically.
  static AppThemeScopeWrapperState? of(BuildContext context) {
    return context.findRootAncestorStateOfType<AppThemeScopeWrapperState>();
  }
}

class AppThemeScopeWrapperState extends State<AppThemeScopeWrapper> {
  AppThemeMode? _themeMode;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTheme());
  }

  // Separate async method to load preferences
  Future<void> _loadTheme() async {
    try {
      final savedMode = await widget.storageDelegate.readThemeMode();

      if (mounted) {
        setState(() {
          _themeMode = savedMode ?? AppThemeMode.system;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _themeMode = AppThemeMode.system;
        });
      }
    }
  }

  Future<void> changeTo(AppThemeMode themeMode) async {
    if (_themeMode == themeMode) return;

    try {
      // 2. Pass the enum directly to the delegate!
      await widget.storageDelegate.writeThemeMode(themeMode);

      setState(() {
        _themeMode = themeMode;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Prevent UI from building (and potentially flashing the wrong theme)
    // for the few milliseconds it takes to load the preferences.
    if (_themeMode == null) {
      return const SizedBox.shrink();
    }

    final brightness = MediaQuery.platformBrightnessOf(context);

    final appTheme = switch (_themeMode) {
      .light => AppTheme.light(),
      .dark => AppTheme.dark(),
      .system =>
        brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      _ => AppTheme.light(),
    };

    return AppThemeScope(
      appTheme: appTheme,
      appThemeMode: _themeMode!,
      child: widget.child,
    );
  }
}
