import 'package:analytics_api/analytics_api.dart';
import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:logger_api/logger_api.dart';

final class RecordingLogger implements LoggerApi {
  final lines = <String>[];

  @override
  void info(String message) => lines.add('info $message');

  @override
  void debug(String message) => lines.add('debug $message');

  @override
  void warning(String message) => lines.add('warning $message');

  @override
  void error(String message, [Object? exception, StackTrace? stackTrace]) =>
      lines.add('error $message: $exception');

  @override
  LoggerApi withTag(String tag) => this;

  @override
  Object get rawInstance => this;
}

final class RecordingAnalytics implements AnalyticsApi {
  final screens = <String>[];

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> logScreenView(String screenName) async =>
      screens.add(screenName);

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {}
}

/// Just enough of a container to see what a module registers.
final class MapContainer implements DependencyContainer {
  final _factories = <Type, Object Function(DependencyLocator)>{};
  final _instances = <Type, Object>{};

  @override
  void registerFactory<T extends Object>(
    T Function(DependencyLocator locator) factoryFunc,
  ) => _factories[T] = factoryFunc;

  @override
  void registerLazySingleton<T extends Object>(
    T Function(DependencyLocator locator) factoryFunc,
  ) => _factories[T] = factoryFunc;

  @override
  void registerSingleton<T extends Object>(T instance) =>
      _instances[T] = instance;

  @override
  T get<T extends Object>() => (_instances[T] ??= _factories[T]!(this)) as T;

  @override
  T getWithName<T extends Object>(String name) => get<T>();

  @override
  T call<T extends Object>() => get<T>();

  @override
  Future<void> dispose() async {}
}
