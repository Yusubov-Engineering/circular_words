/// {@template raw_network_response}
/// A transport level view of a response.
///
/// Carries no knowledge of any application envelope — interpreting [body] is
/// the job of a `NetworkResponseParser`.
/// {@endtemplate}
final class RawNetworkResponse({
  /// The HTTP status code, when the transport reported one.
  required final int? statusCode,

  /// The already decoded response body, typically a `Map`, a `List`, a
  /// `String` or `null`.
  required final Object? body,

  /// The response headers, joined into a single value per name.
  required final Map<String, String> headers,
}) {
  @override
  String toString() =>
      'RawNetworkResponse(statusCode: $statusCode, body: $body)';
}
