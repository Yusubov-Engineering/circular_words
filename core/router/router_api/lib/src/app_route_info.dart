/// The standard contract for all route definitions in the application.
base class AppRouteInfo {
  const AppRouteInfo({required this.name, required this.path});

  /// The unique string identifier for named routing.
  final String name;

  /// The URI path segment.
  final String path;
}
