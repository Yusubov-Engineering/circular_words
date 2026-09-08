import 'package:flutter/widgets.dart';

import 'app_theme.dart';
import 'app_theme_mode.dart';

/// {@template app_theme_scope}
/// InheritedWidget provides [AppTheme] for app
/// {@endtemplate}
class const AppThemeScope({
  required super.child,
  required final AppTheme appTheme,
  required final AppThemeMode appThemeMode,
  super.key,
}) extends InheritedWidget {
  static AppThemeScope of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(result != null, 'No AppThemeScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) => true;
}
