import 'package:network_api/network_api.dart';

import 'app_network_exception.dart';
import 'app_response.dart';

/// {@template app_response_parser}
/// Interprets this application's backend envelope.
///
/// This is the single place that knows the shape the API answers with:
///
/// ```json
/// { "success": true, "error": null, "data": { "message": "...", ... } }
/// ```
///
/// It is registered once with `NetworkModule`, which keeps `network_api` and
/// `network_impl` free of any envelope knowledge.
/// {@endtemplate}
final class AppResponseParser() implements NetworkResponseParser<AppResponse> {
  @override
  AppResponse parseSuccess(RawNetworkResponse response) {
    final body = response.body;

    if (body is! Map<String, dynamic>) {
      return AppResponse(statusCode: response.statusCode, data: body);
    }

    final payload = body['data'];

    if (payload is Map<String, dynamic>) {
      // Copy before lifting `message` out, so the caller's decoded body is
      // never mutated in place.
      final data = Map<String, dynamic>.of(payload);
      final message = data.remove('message');

      return AppResponse(
        statusCode: response.statusCode,
        data: data,
        message: message is String ? message : null,
      );
    }

    // An envelope that explicitly carries a null `data` means a null payload;
    // a body with no `data` key at all is itself the payload.
    return AppResponse(
      statusCode: response.statusCode,
      data: body.containsKey('data') ? payload : body,
      message: _messageOf(body),
    );
  }

  @override
  Object parseFailure(NetworkFailure failure) => switch (failure.kind) {
    NetworkFailureKind.connection => AppNoInternetException(
      cause: failure.cause,
    ),
    NetworkFailureKind.connectionTimeout ||
    NetworkFailureKind.sendTimeout ||
    NetworkFailureKind.receiveTimeout => AppTimeoutException(
      cause: failure.cause,
    ),
    NetworkFailureKind.cancelled => AppRequestCancelledException(
      cause: failure.cause,
    ),
    NetworkFailureKind.badResponse => _requestException(failure),
    NetworkFailureKind.unknown => AppUnknownNetworkException(
      cause: failure.cause,
    ),
  };

  /// Reads the error envelope defensively — a body that is missing `success`,
  /// or whose `data` is not an object, must still produce an exception rather
  /// than a `TypeError` raised from inside the client's catch block.
  AppRequestException _requestException(NetworkFailure failure) {
    final response = failure.response;
    final body = response?.body;

    if (body is! Map<String, dynamic>) {
      return AppRequestException(
        message: 'Request failed',
        statusCode: response?.statusCode,
        cause: failure.cause,
      );
    }

    final payload = body['data'];
    final data = payload is Map<String, dynamic>
        ? Map<String, dynamic>.of(payload)
        : const <String, dynamic>{};
    final error = body['error'];

    return AppRequestException(
      message: _messageOf(data) ?? _messageOf(body) ?? 'Request failed',
      statusCode: response?.statusCode,
      error: error is String ? error : null,
      data: data,
      cause: failure.cause,
    );
  }

  String? _messageOf(Map<String, dynamic> source) {
    final message = source['message'];

    return message is String ? message : null;
  }
}
