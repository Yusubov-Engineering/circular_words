import 'package:flutter/widgets.dart';

import 'app_navigation_service.dart';

class const RouterScope({
  required final AppNavigationService navigationService,
  required super.child,
  super.key,
}) extends InheritedWidget {
  static AppNavigationService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RouterScope>();
    assert(scope != null, 'No RouterScope found in context');
    return scope!.navigationService;
  }

  @override
  bool updateShouldNotify(RouterScope oldWidget) =>
      navigationService != oldWidget.navigationService;
}
