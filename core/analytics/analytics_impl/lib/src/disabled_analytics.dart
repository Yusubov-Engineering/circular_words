import 'package:analytics_api/analytics_api.dart';

/// {@template disabled_analytics}
/// [AnalyticsApi] that drops everything.
/// {@endtemplate}
final class DisabledAnalytics implements AnalyticsApi {
  /// {@macro disabled_analytics}
  const DisabledAnalytics();

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {}
}

/// {@template disabled_crash_reporter}
/// [CrashReporterApi] that drops everything.
/// {@endtemplate}
final class DisabledCrashReporter implements CrashReporterApi {
  /// {@macro disabled_crash_reporter}
  const DisabledCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {}
}
