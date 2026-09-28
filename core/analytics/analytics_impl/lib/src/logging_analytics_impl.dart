import 'package:analytics_api/analytics_api.dart';
import 'package:logger_api/logger_api.dart';

/// {@template logging_analytics_impl}
/// [AnalyticsApi] that writes each call to the log instead of sending it.
/// {@endtemplate}
final class LoggingAnalyticsImpl implements AnalyticsApi {
  /// {@macro logging_analytics_impl}
  LoggingAnalyticsImpl(LoggerApi logger)
    : _logger = logger.withTag('Analytics');

  final LoggerApi _logger;

  @override
  Future<void> logEvent(AnalyticsEvent event) async =>
      _logger.debug('event $event');

  @override
  Future<void> logScreenView(String screenName) async =>
      _logger.debug('screen $screenName');

  @override
  Future<void> setUserProperty(String name, String? value) async =>
      _logger.debug('user property $name = $value');

  @override
  Future<void> setUserId(String? id) async => _logger.debug('user id $id');

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async =>
      _logger.debug('collection ${enabled ? 'enabled' : 'disabled'}');
}

/// {@template logging_crash_reporter}
/// [CrashReporterApi] that writes each report to the log.
/// {@endtemplate}
final class LoggingCrashReporter implements CrashReporterApi {
  /// {@macro logging_crash_reporter}
  LoggingCrashReporter(LoggerApi logger)
    : _logger = logger.withTag('CrashReporter');

  final LoggerApi _logger;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async => _logger.error(
    '${fatal ? 'fatal' : 'non-fatal'}${reason == null ? '' : ': $reason'}',
    error,
    stackTrace,
  );

  @override
  Future<void> log(String message) async => _logger.debug(message);

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async =>
      _logger.debug('collection ${enabled ? 'enabled' : 'disabled'}');
}
