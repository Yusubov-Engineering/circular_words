import 'dart:async';

import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:network_api/network_api.dart';

import 'core/app_dio_logger_interceptor.dart';
import 'core/dio_rest_client.dart';

/// {@template network_module}
/// Registers the [NetworkApi] for the application's own success model.
///
/// The module is deliberately agnostic about that model: [responseParser] is
/// what teaches the client how to read the backend's envelope, so a different
/// backend contract is a different parser and no change in here. The same
/// holds for [headerProviderBuilder]: what belongs on every request — the
/// selected language, an auth token — is the host application's knowledge,
/// not this module's.
/// {@endtemplate}
final class NetworkModule<TSuccess extends Object>({
  required final String baseUrl,
  required final NetworkResponseParser<TSuccess> responseParser,
  final NetworkHeaderProvider Function(DependencyLocator locator)?
  headerProviderBuilder,
  final bool enableLogging = false,
}) implements DependencyModule {
  @override
  String get name => 'Network';

  @override
  FutureOr<void> registerDependencies(DependencyContainer container) {
    container.registerLazySingleton<NetworkApi<TSuccess>>((locator) {
      final client = DioRestClient<TSuccess>(
        baseUrl: baseUrl,
        parser: responseParser,
        headerProvider: headerProviderBuilder?.call(locator),
      );

      if (enableLogging) {
        client.add(AppDioLoggerInterceptor(loggerApi: locator.get()));
      }

      return client;
    });
  }
}
