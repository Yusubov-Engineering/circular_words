import 'package:firebase_core/firebase_core.dart';

/// {@template analytics_backend}
/// Where `AnalyticsModule` sends events and errors.
///
/// Chosen per flavor at the composition root, so a development build never
/// pollutes production data and no feature code knows which one is live.
/// {@endtemplate}
sealed class AnalyticsBackend {
  const AnalyticsBackend();
}

/// {@template firebase_analytics_backend}
/// Firebase Analytics for events, Crashlytics for errors.
///
/// Pass the app's generated `DefaultFirebaseOptions.currentPlatform` as
/// [options], or leave it `null` to read the native configuration files
/// (`google-services.json`, `GoogleService-Info.plist`).
/// {@endtemplate}
final class const FirebaseAnalyticsBackend({
  final FirebaseOptions? options,

  /// Whether to route uncaught Flutter and platform errors to Crashlytics.
  final bool captureUncaughtErrors = true,
}) extends AnalyticsBackend;

/// {@template logging_analytics_backend}
/// Writes every event and error to `LoggerApi` instead of sending it.
///
/// For development builds: you can watch events arrive without them counting.
/// Needs `LoggerModule` registered before `AnalyticsModule`.
/// {@endtemplate}
final class LoggingAnalyticsBackend extends AnalyticsBackend {
  /// {@macro logging_analytics_backend}
  const LoggingAnalyticsBackend();
}

/// {@template disabled_analytics_backend}
/// Drops everything. For tests, and for builds that must not collect.
/// {@endtemplate}
final class DisabledAnalyticsBackend extends AnalyticsBackend {
  /// {@macro disabled_analytics_backend}
  const DisabledAnalyticsBackend();
}
