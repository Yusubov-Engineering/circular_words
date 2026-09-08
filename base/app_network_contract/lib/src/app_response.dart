/// {@template app_response}
/// A successful response, with the backend envelope already unwrapped.
///
/// [data] holds the payload the envelope carried — a `Map<String, dynamic>` for
/// object responses and a `List` for collection responses — so callers decode
/// their own model from it.
/// {@endtemplate}
final class AppResponse({
  /// The HTTP status code the response arrived with.
  required final int? statusCode,

  /// The unwrapped payload.
  required final Object? data,

  /// The human readable message the envelope carried, when there was one.
  final String? message,
}) {
  /// [data] as an object payload, or `null` when it was not one.
  Map<String, dynamic>? get dataAsMap {
    final payload = data;
    return payload is Map<String, dynamic> ? payload : null;
  }

  /// [data] as a collection payload, or `null` when it was not one.
  List<dynamic>? get dataAsList {
    final payload = data;
    return payload is List ? payload : null;
  }

  @override
  String toString() =>
      'AppResponse(statusCode: $statusCode, message: $message, data: $data)';
}
