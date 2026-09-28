import 'package:flutter/widgets.dart';

import 'dependency_locator.dart';

/// An InheritedWidget to provide the DependencyLocator down the widget tree.
class const DependencyScope({
  required final DependencyLocator locator,
  required super.child,
  super.key,
}) extends InheritedWidget {
  static DependencyLocator of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<DependencyScope>();
    assert(result != null, 'No DependencyScope found in context');
    return result!.locator;
  }

  @override
  bool updateShouldNotify(DependencyScope oldWidget) {
    return locator != oldWidget.locator;
  }
}
