import 'package:dio/dio.dart';
import 'package:network_api/network_api.dart';

import 'rest_client_base.dart';

/// {@template dio_rest_client}
/// A [NetworkApi] backed by `dio`.
///
/// The client itself understands only the transport. Turning a response into
/// [TSuccess], and a failure into the exception callers see, is delegated to
/// the [NetworkResponseParser] it was built with.
/// {@endtemplate}
final class DioRestClient<TSuccess extends Object>
    extends RestClientBase<TSuccess> {
  /// {@macro dio_rest_client}
  DioRestClient({
    required String baseUrl,
    required this.parser,
    NetworkHeaderProvider? headerProvider,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    // Merge rather than replace, so an injected pre-configured Dio keeps its
    // options.
    _dio.options = _dio.options.copyWith(
      baseUrl: baseUrl,
      headers: {
        ..._dio.options.headers,
        Headers.contentTypeHeader: 'application/json; charset=utf-8',
      },
    );

    if (headerProvider != null) {
      _dio.interceptors.add(_headerProviderInterceptor(headerProvider));
    }
  }

  /// Asks [provider] for its headers as each request goes out, rather than
  /// once at construction, so a header whose value changes at runtime is
  /// never stale. Headers the caller passed for this one request are left
  /// alone.
  static Interceptor _headerProviderInterceptor(
    NetworkHeaderProvider provider,
  ) {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        for (final header in provider.headers.entries) {
          options.headers.putIfAbsent(header.key, () => header.value);
        }

        handler.next(options);
      },
    );
  }

  final Dio _dio;

  /// Turns transport results into the application's own types.
  final NetworkResponseParser<TSuccess> parser;

  /// The underlying client, for callers that need to configure it further.
  Dio get dio => _dio;

  /// Adds [interceptor] to the underlying client.
  void add(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  @override
  Future<TSuccess> send({
    required String path,
    required HttpMethod method,
    Map<String, Object?>? body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: queryParams,
        options: Options(method: method.value, headers: headers),
      );

      return parser.parseSuccess(_rawResponseOf(response));
    } on DioException catch (e, s) {
      Error.throwWithStackTrace(
        parser.parseFailure(
          NetworkFailure(
            kind: _failureKindOf(e.type),
            response: e.response == null ? null : _rawResponseOf(e.response!),
            cause: e,
            stackTrace: s,
          ),
        ),
        s,
      );
    } on Object catch (e, s) {
      Error.throwWithStackTrace(
        parser.parseFailure(
          NetworkFailure(
            kind: NetworkFailureKind.unknown,
            response: null,
            cause: e,
            stackTrace: s,
          ),
        ),
        s,
      );
    }
  }

  RawNetworkResponse _rawResponseOf(Response<dynamic> response) {
    return RawNetworkResponse(
      statusCode: response.statusCode,
      body: response.data,
      headers: response.headers.map.map(
        (name, values) => MapEntry(name, values.join(', ')),
      ),
    );
  }

  /// Note that `dio` wraps socket level failures into a [DioException] with
  /// [DioExceptionType.connectionError], which is why there is no
  /// `SocketException` branch anywhere in this client.
  NetworkFailureKind _failureKindOf(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionError => NetworkFailureKind.connection,
    DioExceptionType.connectionTimeout => NetworkFailureKind.connectionTimeout,
    DioExceptionType.sendTimeout => NetworkFailureKind.sendTimeout,
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => NetworkFailureKind.receiveTimeout,
    DioExceptionType.badResponse => NetworkFailureKind.badResponse,
    DioExceptionType.cancel => NetworkFailureKind.cancelled,
    DioExceptionType.badCertificate ||
    DioExceptionType.unknown => NetworkFailureKind.unknown,
  };
}
