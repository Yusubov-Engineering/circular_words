import 'raw_network_response.dart';

/// {@template network_failure_kind}
/// Why a request failed, described purely in transport terms.
/// {@endtemplate}
enum NetworkFailureKind {
  /// The host could not be reached — DNS failure, no route, offline.
  connection,

  /// Establishing the connection timed out.
  connectionTimeout,

  /// Sending the request body timed out.
  sendTimeout,

  /// Receiving the response timed out.
  receiveTimeout,

  /// The server answered with a non success status code.
  ///
  /// [NetworkFailure.response] is non-null for this kind.
  badResponse,

  /// The request was cancelled before it completed.
  cancelled,

  /// Anything else, including a bad certificate.
  unknown,
}

/// {@template network_failure}
/// A failed request, described without any application semantics.
///
/// A `NetworkResponseParser` turns this into the application's own exception
/// type.
/// {@endtemplate}
final class NetworkFailure({
  /// {@macro network_failure_kind}
  required final NetworkFailureKind kind,

  /// The response the server sent, when it sent one.
  required final RawNetworkResponse? response,

  /// The underlying error raised by the transport.
  final Object? cause,

  /// The stack trace the [cause] was raised with.
  final StackTrace? stackTrace,
}) {
  @override
  String toString() =>
      'NetworkFailure(kind: $kind, response: $response, cause: $cause)';
}
