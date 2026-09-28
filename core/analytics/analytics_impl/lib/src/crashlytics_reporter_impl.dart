import 'package:analytics_api/analytics_api.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logger_api/logger_api.dart';

import 'guarded.dart';

/// {@template crashlytics_reporter_impl}
/// [CrashReporterApi] over Firebase Crashlytics.
/// {@endtemplate}
final class CrashlyticsReporterImpl implements CrashReporterApi {
  /// {@macro crashlytics_reporter_impl}
  CrashlyticsReporterImpl({required this._crashlytics, this._logger});

  final FirebaseCrashlytics _crashlytics;
  final LoggerApi? _logger;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) => guarded(
    _logger,
    'recordError',
    () => _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    ),
  );

  @override
  Future<void> log(String message) =>
      guarded(_logger, 'log', () => _crashlytics.log(message));

  @override
  Future<void> setCollectionEnabled({required bool enabled}) => guarded(
    _logger,
    'setCollectionEnabled',
    () => _crashlytics.setCrashlyticsCollectionEnabled(enabled),
  );
}
