import 'app_route_info.dart';

/// A structured request containing all the necessary payload data to
/// navigate to a specific route in the application.
///
/// By using this request object instead of calling routing methods directly
/// with primitive strings, we guarantee strict type safety and completely
/// decouple our feature modules from the underlying routing package.
final class AppRouteRequest {
  /// Creates a new [AppRouteRequest].
  ///
  /// The [routeInfo] is required to identify the destination. Optional
  /// parameters can be provided to pass data via the URL or in-memory.
  const AppRouteRequest({
    required this.routeInfo,
    this.pathParameters = const {},
    this.queryParameters = const {},
    this.extra,
  });

  /// The strongly-typed route definition (name and path) for the destination.
  ///
  /// This should be a constant provided by the feature module
  /// (e.g., `ProfileRouteInfo.details`).
  final AppRouteInfo routeInfo;

  /// Dynamic parameters injected directly into the URL path.
  ///
  /// Example: For a path defined as `/user/:id`, passing `{'id': '123'}`
  /// will result in the URL `/user/123`.
  final Map<String, String> pathParameters;

  /// Optional parameters appended to the end of the URL query string.
  ///
  /// Example: Passing `{'filter': 'active'}` will result in the URL
  /// appending `?filter=active`.
  final Map<String, dynamic> queryParameters;

  /// An optional, strictly typed object passed in-memory during navigation.
  ///
  /// Use this to pass complex data structures (like Data Transfer Objects
  /// or Models) that cannot or should not be serialized into a web URL string.
  final Object? extra;
}
