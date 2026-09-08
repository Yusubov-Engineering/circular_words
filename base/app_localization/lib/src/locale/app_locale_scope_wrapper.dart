import 'package:flutter/widgets.dart';

import 'app_locale.dart';
import 'app_locale_notifier.dart';
import 'app_locale_scope.dart';

/// {@template app_locale_scope_wrapper}
/// A class which publishes the selected language to the widget tree
///
/// It should wrap the app in order to use [AppLocale] in the app. The language
/// itself is owned by the [AppLocaleNotifier] in the dependency container;
/// this widget only mirrors it and rebuilds when it changes.
/// {@endtemplate}
class const AppLocaleScopeWrapper({
  required final Widget child,
  required final AppLocaleNotifier localeNotifier,
  super.key,
}) extends StatefulWidget {
  @override
  State<AppLocaleScopeWrapper> createState() => AppLocaleScopeWrapperState();

  /// In order to use methods of [AppLocaleScopeWrapper] this function
  /// should be called first. Language change process will be handled by
  /// [AppLocaleScopeWrapper] automatically.
  static AppLocaleScopeWrapperState? of(BuildContext context) {
    return context.findRootAncestorStateOfType<AppLocaleScopeWrapperState>();
  }
}

class AppLocaleScopeWrapperState extends State<AppLocaleScopeWrapper> {
  late AppLocale _appLocale;

  @override
  void initState() {
    super.initState();
    _appLocale = widget.localeNotifier.locale;
    widget.localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void didUpdateWidget(covariant AppLocaleScopeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.localeNotifier == widget.localeNotifier) return;

    oldWidget.localeNotifier.removeListener(_onLocaleChanged);
    widget.localeNotifier.addListener(_onLocaleChanged);
    _onLocaleChanged();
  }

  @override
  void dispose() {
    widget.localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  Future<void> changeTo(AppLocale appLocale) {
    return widget.localeNotifier.changeTo(appLocale);
  }

  void _onLocaleChanged() {
    setState(() {
      _appLocale = widget.localeNotifier.locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(appLocale: _appLocale, child: widget.child);
  }
}
