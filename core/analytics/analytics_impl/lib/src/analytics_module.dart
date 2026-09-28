import 'dart:async';

import 'package:analytics_api/analytics_api.dart';
import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger_api/logger_api.dart';

import 'analytics_backend.dart';
import 'crashlytics_reporter_impl.dart';
import 'disabled_analytics.dart';
import 'firebase_analytics_impl.dart';
import 'logging_analytics_impl.dart';

/// {@template analytics_module}
/// Registers [AnalyticsApi] and [CrashReporterApi] for the chosen [backend].
///
/// Register it **after `LoggerModule`**: every backend but the disabled one
/// resolves `LoggerApi`. For Firebase, registration initialises Firebase —
/// which is why this module is async — and, unless told otherwise, routes
/// uncaught errors to Crashlytics.
///
/// If Firebase cannot start (a missing or wrong configuration file), the app
/// still starts: both contracts are registered as disabled and the failure is
/// logged. Analytics is never a reason for an app not to open.
/// {@endtemplate}
final class const AnalyticsModule({required final AnalyticsBackend backend})
    implements DependencyModule {
  @override
  String get name => 'Analytics';

  @override
  Future<void> registerDependencies(DependencyContainer container) async {
    switch (backend) {
      case FirebaseAnalyticsBackend(
        :final options,
        :final captureUncaughtErrors,
      ):
        await _registerFirebase(
          container,
          options: options,
          captureUncaughtErrors: captureUncaughtErrors,
        );
      case LoggingAnalyticsBackend():
        container
          ..registerLazySingleton<AnalyticsApi>(
            (locator) => LoggingAnalyticsImpl(locator.get<LoggerApi>()),
          )
          ..registerLazySingleton<CrashReporterApi>(
            (locator) => LoggingCrashReporter(locator.get<LoggerApi>()),
          );
      case DisabledAnalyticsBackend():
        _registerDisabled(container);
    }
  }

  Future<void> _registerFirebase(
    DependencyContainer container, {
    required FirebaseOptions? options,
    required bool captureUncaughtErrors,
  }) async {
    final logger = container.get<LoggerApi>().withTag('Analytics');

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
    } on Object catch (error, stackTrace) {
      logger.error(
        'Firebase could not start; analytics and crash reports are off',
        error,
        stackTrace,
      );
      _registerDisabled(container);
      return;
    }

    final crashlytics = FirebaseCrashlytics.instance;
    container
      ..registerSingleton<AnalyticsApi>(
        FirebaseAnalyticsImpl(
          analytics: FirebaseAnalytics.instance,
          logger: logger,
        ),
      )
      ..registerSingleton<CrashReporterApi>(
        CrashlyticsReporterImpl(crashlytics: crashlytics, logger: logger),
      );

    if (captureUncaughtErrors) _captureUncaughtErrors(crashlytics);
  }

  /// Sends uncaught errors to Crashlytics, keeping whatever handler the app
  /// already had in front of it.
  void _captureUncaughtErrors(FirebaseCrashlytics crashlytics) {
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutter?.call(details);
      unawaited(crashlytics.recordFlutterFatalError(details));
    };

    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(crashlytics.recordError(error, stackTrace, fatal: true));
      return previousPlatform?.call(error, stackTrace) ?? true;
    };
  }

  void _registerDisabled(DependencyContainer container) {
    container
      ..registerSingleton<AnalyticsApi>(const DisabledAnalytics())
      ..registerSingleton<CrashReporterApi>(const DisabledCrashReporter());
  }
}
