import 'http_method.dart';

/// {@template network_api}
/// A REST client for making HTTP requests.
///
/// [TSuccess] is the application's own success model. It is produced by the
/// `NetworkResponseParser` the client was built with, so this protocol stays
/// free of any envelope knowledge.
/// {@endtemplate}
abstract interface class NetworkApi<TSuccess extends Object> {
  /// Sends a GET request to the given [path].
  Future<TSuccess> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  });

  /// Sends a POST request to the given [path].
  Future<TSuccess> post(
    String path, {
    required Map<String, Object?> body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  });

  /// Sends a PUT request to the given [path].
  Future<TSuccess> put(
    String path, {
    required Map<String, Object?> body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  });

  /// Sends a DELETE request to the given [path].
  Future<TSuccess> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  });

  /// Sends a PATCH request to the given [path].
  Future<TSuccess> patch(
    String path, {
    required Map<String, Object?> body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  });

  /// Sends a request with an arbitrary [method] to the given [path].
  Future<TSuccess> send({
    required String path,
    required HttpMethod method,
    Map<String, Object?>? body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  });
}
