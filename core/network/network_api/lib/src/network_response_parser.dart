import 'network_failure.dart';
import 'raw_network_response.dart';

/// {@template network_response_parser}
/// Translates transport level results into the application's own success and
/// error types.
///
/// The network module knows nothing about response envelopes. A parser is
/// registered once at composition time and the client applies it internally to
/// every request, which keeps the shape of the backend contract out of
/// `network_api` and `network_impl`.
/// {@endtemplate}
abstract interface class NetworkResponseParser<TSuccess extends Object> {
  /// Maps a successful response to the application's success model.
  TSuccess parseSuccess(RawNetworkResponse response);

  /// Maps a [failure] to the application's exception type.
  ///
  /// The returned object is thrown by the client, so it should be an
  /// [Exception] or an [Error].
  Object parseFailure(NetworkFailure failure);
}
