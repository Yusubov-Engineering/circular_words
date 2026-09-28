/// {@template crash_reporter_api}
/// Reports errors from the field.
///
/// Uncaught errors are reported by the implementation on its own once it is
/// registered; this is for the ones the app catches but still wants to hear
/// about — a failure that was handled, but should not have happened.
///
/// **Never throws**, for the same reason `AnalyticsApi` does not.
/// {@endtemplate}
abstract interface class CrashReporterApi {
  /// Reports [error]. [reason] says what the app was doing at the time;
  /// [fatal] marks an error the app could not recover from.
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// Leaves a breadcrumb: shown alongside the next report, to say what led
  /// up to it.
  Future<void> log(String message);

  /// Turns reporting on or off, persistently.
  Future<void> setCollectionEnabled({required bool enabled});
}
