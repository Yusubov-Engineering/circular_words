import 'package:analytics_api/analytics_api.dart';

/// Keeps every event, so a test can say what a controller reported.
final class RecordingAnalytics implements AnalyticsApi {
  final events = <AnalyticsEvent>[];

  List<String> get names => [for (final event in events) event.name];

  /// The one event called [name]; fails the test if there is not exactly one.
  AnalyticsEvent single(String name) =>
      events.where((event) => event.name == name).single;

  @override
  Future<void> logEvent(AnalyticsEvent event) async => events.add(event);

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {}
}
