import 'dart:async';

import 'dependency_container.dart';

/// A protocol that every feature or API package must implement
/// to register its own dependencies into the core DI container.
abstract interface class DependencyModule {
  /// The name of the module or feature being registered (useful for logging/debugging).
  String get name;

  /// Registers the dependencies for this module into the provided [container].
  FutureOr<void> registerDependencies(DependencyContainer container);
}
