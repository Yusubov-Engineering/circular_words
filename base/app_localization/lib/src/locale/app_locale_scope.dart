import 'package:flutter/widgets.dart';

import 'app_locale.dart';

/// {@template app_locale_scope}
/// InheritedWidget provides the active [AppLocale] for app
/// {@endtemplate}
class const AppLocaleScope({
  required super.child,
  required final AppLocale appLocale,
  super.key,
}) extends InheritedWidget {
  static AppLocaleScope of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(result != null, 'No AppLocaleScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppLocaleScope oldWidget) =>
      appLocale != oldWidget.appLocale;
}
