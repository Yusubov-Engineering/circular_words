import 'dart:developer' as developer;

import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:dependency_injection_impl/dependency_injection_impl.dart';

class CompositionRoot {
  static Future<DependencyContainer> initialize({
    required List<DependencyModule> modules,
    void Function(String message, DependencyLocator locator)? onLog,
    bool enableLogging = false,
  }) async {
    final DependencyContainer globalContainer = GetItContainer();
    final rootTask = developer.TimelineTask()
      ..start('CompositionRoot.initialize');
    final totalTimer = enableLogging ? (Stopwatch()..start()) : null;

    for (final module in modules) {
      final moduleTask = developer.TimelineTask(parent: rootTask)
        ..start('Init: ${module.name}');
      final moduleTimer = enableLogging ? (Stopwatch()..start()) : null;

      await module.registerDependencies(globalContainer);
      moduleTask.finish();
      moduleTimer?.stop();

      if (enableLogging && moduleTimer != null) {
        // Calculate double-precision milliseconds
        final preciseMs = (moduleTimer.elapsedMicroseconds / 1000.0)
            .toStringAsFixed(2);

        onLog?.call(
          '[CompositionRoot]: "${module.name}" initialized in $preciseMs ms',
          globalContainer,
        );
      }
    }

    totalTimer?.stop();

    if (enableLogging && totalTimer != null) {
      final totalPreciseMs = (totalTimer.elapsedMicroseconds / 1000.0)
          .toStringAsFixed(2);
      onLog?.call(
        '[CompositionRoot]: Total (${modules.length} modules) initialization finished in $totalPreciseMs ms',
        globalContainer,
      );
    }

    rootTask.finish();
    return globalContainer;
  }
}
