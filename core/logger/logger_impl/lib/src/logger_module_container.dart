import 'dart:async';

import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:logger_api/logger_api.dart';

import 'talker_app_logger.dart';

class LoggerModule implements DependencyModule {
  @override
  String get name => 'Logger';

  @override
  FutureOr<void> registerDependencies(DependencyContainer container) {
    container.registerSingleton<LoggerApi>(TalkerAppLogger());
  }
}
