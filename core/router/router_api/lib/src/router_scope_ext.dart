import 'package:flutter/widgets.dart';

import 'app_navigation_service.dart';
import 'router_scope.dart';

extension NavigationContextExtension on BuildContext {
  AppNavigationService get navigation => RouterScope.of(this);
}
