import 'analytics_event.dart';

/// {@template analytics_api}
/// Records what users do, for product analytics.
///
/// **Never throws.** Every method completes normally whatever happens to the
/// event: analytics comments on something that already happened, and a
/// network failure or a missing configuration must never take the caller
/// down with it. Callers may therefore fire and forget with `unawaited`.
/// {@endtemplate}
abstract interface class AnalyticsApi {
  /// Records [event].
  Future<void> logEvent(AnalyticsEvent event);

  /// Records that the screen called [screenName] is now showing.
  ///
  /// Usually called for you by the implementation's navigator observer.
  Future<void> logScreenView(String screenName);

  /// Attaches a property to everything this user does from now on, such as
  /// their chosen language. A `null` [value] clears it.
  Future<void> setUserProperty(String name, String? value);

  /// Ties events to a user id of the app's own, or clears it with `null`.
  ///
  /// Leave it unset for anonymous apps: the service's own install id already
  /// tells users apart.
  Future<void> setUserId(String? id);

  /// Turns collection on or off, persistently — the switch a consent setting
  /// or an opt-out toggle drives.
  Future<void> setCollectionEnabled({required bool enabled});
}
