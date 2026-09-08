import 'dart:async';

import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:levels_api/levels_api.dart';

import 'levels_api_impl.dart';

/// {@template levels_module}
/// Registers this feature's public facade.
/// {@endtemplate}
final class LevelsModule implements DependencyModule {
  @override
  String get name => 'Levels';

  @override
  FutureOr<void> registerDependencies(DependencyContainer container) {
    container.registerLazySingleton<LevelsApi>((_) => const LevelsApiImpl());
  }
}
