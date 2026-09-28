import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:router_api/router_api.dart';

extension AppRouteNameExt on BuildContext {
  /// Safely checks if the currently active route matches the given [AppRouteInfo]'s name.
  bool isRouteActive(AppRouteInfo routeInfo) {
    try {
      // 1. Get the current active route name from go_router state/delegates
      final currentName =
          GoRouter.of(this).state.name ??
          GoRouter.of(this).routerDelegate.currentConfiguration.last.route.name;

      // 2. Compare against the strongly-typed route info name
      return currentName == routeInfo.name;
    } catch (_) {
      // Fallback path check if the name isn't exposed on the current frame
      return GoRouter.of(
        this,
      ).routerDelegate.currentConfiguration.uri.path.contains(routeInfo.path);
    }
  }
}
