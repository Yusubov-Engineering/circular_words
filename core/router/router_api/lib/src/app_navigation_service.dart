import 'app_route_info.dart';
import 'app_route_request.dart';

/// The abstract contract for all application navigation.
///
/// Business logic layers (like ViewModels, BLoCs, or Coordinators) should
/// depend exclusively on this interface rather than a concrete routing package.
abstract interface class AppNavigationService {
  /// Navigates directly to a new route, replacing the current URL.
  void goRoute(AppRouteRequest request);

  /// Pushes a new route on top of the current navigation stack.
  Future<T?> pushRoute<T extends Object?>(AppRouteRequest request);

  /// Replaces the current route on top of the stack with a new one.
  Future<T?> replaceRoute<T>(AppRouteRequest request);

  /// Pops the top-most route off the navigation stack.
  void popRoute<T extends Object?>([T? result]);

  /// Pops routes until the route matching the routeInfo is reached.
  void popUntilRoute(AppRouteInfo routeInfo);

  /// Returns true if there is more than 1 item on the navigation stack.
  bool canPopRoute();

  /// Attempts to pop the current route.
  /// Returns `true` if the route was successfully popped, `false` otherwise.
  bool maybePopRoute<T extends Object?>([T? result]);
}
