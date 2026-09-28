import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:get_it/get_it.dart';

class GetItContainer implements DependencyContainer {
  GetItContainer({GetIt? getIt}) : _getIt = getIt ?? GetIt.instance;
  final GetIt _getIt;

  @override
  T get<T extends Object>() {
    return _getIt.get<T>();
  }

  @override
  T getWithName<T extends Object>(String name) {
    return _getIt.get<T>(instanceName: name);
  }

  @override
  void registerFactory<T extends Object>(
    T Function(DependencyLocator locator) factoryFunc,
  ) {
    // We pass 'this' as the locator to the factory function
    _getIt.registerFactory<T>(() => factoryFunc(this));
  }

  @override
  void registerSingleton<T extends Object>(T instance) {
    _getIt.registerSingleton<T>(instance);
  }

  @override
  void registerLazySingleton<T extends Object>(
    T Function(DependencyLocator locator) factoryFunc,
  ) {
    // We pass 'this' as the locator to the factory function
    _getIt.registerLazySingleton<T>(() => factoryFunc(this));
  }

  @override
  T call<T extends Object>() => _getIt.get<T>();

  @override
  Future<void> dispose() async {
    await _getIt.popScope();
  }
}
