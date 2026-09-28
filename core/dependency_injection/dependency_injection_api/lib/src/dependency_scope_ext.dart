import 'package:flutter/widgets.dart';

import 'dependency_locator.dart';
import 'dependency_scope.dart';

extension DependencyScopeExt on BuildContext {
  DependencyLocator get locator => DependencyScope.of(this);
}
