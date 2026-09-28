import 'package:network_api/network_api.dart';

/// {@template rest_client_base}
/// Maps every verb onto [send], so a concrete client only has to implement the
/// single transport method.
/// {@endtemplate}
abstract class RestClientBase<TSuccess extends Object>
    implements NetworkApi<TSuccess> {
  @override
  Future<TSuccess> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) => send(
    path: path,
    method: HttpMethod.delete,
    headers: headers,
    queryParams: queryParams,
  );

  @override
  Future<TSuccess> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) => send(
    path: path,
    method: HttpMethod.get,
    headers: headers,
    queryParams: queryParams,
  );

  @override
  Future<TSuccess> patch(
    String path, {
    required Map<String, Object?> body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) => send(
    path: path,
    method: HttpMethod.patch,
    body: body,
    headers: headers,
    queryParams: queryParams,
  );

  @override
  Future<TSuccess> post(
    String path, {
    required Map<String, Object?> body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) => send(
    path: path,
    method: HttpMethod.post,
    body: body,
    headers: headers,
    queryParams: queryParams,
  );

  @override
  Future<TSuccess> put(
    String path, {
    required Map<String, Object?> body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) => send(
    path: path,
    method: HttpMethod.put,
    body: body,
    headers: headers,
    queryParams: queryParams,
  );
}
