import 'dependency_locator.dart';

abstract class DependencyContainer extends DependencyLocator {
  /// Passes the locator to the factory so dependencies can be resolved during instantiation.
  void registerFactory<T extends Object>(
    T Function(DependencyLocator locator) factoryFunc,
  );

  void registerSingleton<T extends Object>(T instance);

  /// Passes the locator to the lazy singleton factory.
  void registerLazySingleton<T extends Object>(
    T Function(DependencyLocator locator) factoryFunc,
  );

  Future<void> dispose();
}
