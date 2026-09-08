/// {@template app_network_exception}
/// Every failure the network layer can surface to the application.
///
/// The hierarchy is `sealed` so callers can switch over it exhaustively:
///
/// ```dart
/// try {
///   await api.get('/profile');
/// } on AppNetworkException catch (e) {
///   final text = switch (e) {
///     AppRequestException(:final message) => message ?? e.message,
///     AppNoInternetException() => l10n.noInternet,
///     AppTimeoutException() => l10n.tryAgain,
///     AppRequestCancelledException() => null,
///     AppUnknownNetworkException() => l10n.somethingWentWrong,
///   };
/// }
/// ```
/// {@endtemplate}
sealed class AppNetworkException implements Exception {
  /// {@macro app_network_exception}
  const AppNetworkException({required this.message, this.cause});

  /// A description of what went wrong, safe to log.
  final String message;

  /// The underlying transport error, when there was one.
  final Object? cause;

  @override
  String toString() => cause == null ? message : '$message (cause: $cause)';
}

/// {@template app_request_exception}
/// The server answered with an error envelope.
/// {@endtemplate}
final class AppRequestException extends AppNetworkException {
  /// {@macro app_request_exception}
  const AppRequestException({
    required super.message,
    this.statusCode,
    this.error,
    this.data = const {},
    super.cause,
  });

  /// The HTTP status code the error arrived with.
  final int? statusCode;

  /// The machine readable error code the envelope carried.
  final String? error;

  /// The error payload, empty when the envelope carried none.
  final Map<String, dynamic> data;

  @override
  String toString() =>
      'AppRequestException(statusCode: $statusCode, error: $error, '
      'message: $message, data: $data)';
}

/// {@template app_no_internet_exception}
/// The host could not be reached at all.
/// {@endtemplate}
final class AppNoInternetException extends AppNetworkException {
  /// {@macro app_no_internet_exception}
  const AppNoInternetException({
    super.message = 'No internet connection',
    super.cause,
  });
}

/// {@template app_timeout_exception}
/// The request did not complete in time.
/// {@endtemplate}
final class AppTimeoutException extends AppNetworkException {
  /// {@macro app_timeout_exception}
  const AppTimeoutException({super.message = 'Request timed out', super.cause});
}

/// {@template app_request_cancelled_exception}
/// The request was cancelled before it completed.
/// {@endtemplate}
final class AppRequestCancelledException extends AppNetworkException {
  /// {@macro app_request_cancelled_exception}
  const AppRequestCancelledException({
    super.message = 'Request was cancelled',
    super.cause,
  });
}

/// {@template app_unknown_network_exception}
/// Anything the layer could not classify.
/// {@endtemplate}
final class AppUnknownNetworkException extends AppNetworkException {
  /// {@macro app_unknown_network_exception}
  const AppUnknownNetworkException({
    super.message = 'Something went wrong',
    super.cause,
  });
}
