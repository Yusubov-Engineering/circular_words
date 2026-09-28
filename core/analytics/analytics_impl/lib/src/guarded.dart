import 'package:logger_api/logger_api.dart';

/// Runs [body] and swallows anything it throws, logging it to [logger].
///
/// This is the whole of the "never throws" promise in `AnalyticsApi` and
/// `CrashReporterApi`: analytics comments on something that already happened,
/// and must not take its caller down when the network or the SDK fails.
Future<void> guarded(
  LoggerApi? logger,
  String operation,
  Future<void> Function() body,
) async {
  try {
    await body();
  } on Object catch (error, stackTrace) {
    logger?.error('Analytics $operation failed', error, stackTrace);
  }
}
