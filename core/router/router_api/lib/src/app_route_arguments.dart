import 'app_route_info.dart';

/// A structured container for all arguments passed during navigation.
///
/// This replaces the need to pass raw maps or untyped objects directly
/// through the routing system, ensuring type safety and consistency.
final class AppRouteArguments {
  /// Creates a new [AppRouteArguments] instance.
  const AppRouteArguments({
    required this.matchedPath,
    this.routeName,
    this.pathParameters = const {},
    this.queryParameters = const {},
    this.extra,
  });

  final String matchedPath;

  final String? routeName;

  /// Parameters extracted from the URL path (e.g., `/user/:id` -> `{'id': '123'}`).
  final Map<String, String> pathParameters;

  /// Parameters extracted from the URL query string (e.g., `?sort=asc` -> `{'sort': 'asc'}`).
  final Map<String, String> queryParameters;

  /// An optional, strictly typed object passed outside the URL.
  /// Useful for passing complex DTOs or state that shouldn't be serialized in the web URL.
  final Object? extra;

  /// Helper to strictly check if the current route matches a specific AppRouteInfo
  bool matchesInfo(AppRouteInfo info) {
    // Check by name if we have it, otherwise fallback to the path template
    if (routeName != null) return routeName == info.name;
    return matchedPath == info.path;
  }

  bool matchesList(List<AppRouteInfo> info) {
    for (final item in info) {
      if (matchesInfo(item)) {
        return true;
      }
    }

    return false;
  }
}
