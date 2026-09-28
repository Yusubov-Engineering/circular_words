import 'package:analytics_api/analytics_api.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger_api/logger_api.dart';

import 'firebase_event_rules.dart';
import 'guarded.dart';

/// {@template firebase_analytics_impl}
/// [AnalyticsApi] over Firebase Analytics.
///
/// Events are checked against [FirebaseEventRules] first, so a bad name is a
/// logged warning rather than an event that silently never arrives.
/// {@endtemplate}
final class FirebaseAnalyticsImpl implements AnalyticsApi {
  /// {@macro firebase_analytics_impl}
  FirebaseAnalyticsImpl({
    required this._analytics,
    this._logger,
    this._rules = const FirebaseEventRules(),
  });

  final FirebaseAnalytics _analytics;
  final LoggerApi? _logger;
  final FirebaseEventRules _rules;

  @override
  Future<void> logEvent(
    AnalyticsEvent event,
  ) => guarded(_logger, 'logEvent', () {
    final problem = _rules.rejectEventName(event.name);
    if (problem != null) {
      _logger?.warning('Analytics event "${event.name}" dropped: it $problem.');
      return Future.value();
    }

    final (:parameters, :dropped) = _rules.adaptParameters(event.parameters);
    for (final note in dropped) {
      _logger?.warning('Analytics event "${event.name}": parameter $note.');
    }
    return _analytics.logEvent(
      name: event.name,
      parameters: parameters.isEmpty ? null : parameters,
    );
  });

  @override
  Future<void> logScreenView(String screenName) => guarded(
    _logger,
    'logScreenView',
    () => _analytics.logScreenView(screenName: screenName),
  );

  @override
  Future<void> setUserProperty(String name, String? value) => guarded(
    _logger,
    'setUserProperty',
    () => _analytics.setUserProperty(name: name, value: value),
  );

  @override
  Future<void> setUserId(String? id) =>
      guarded(_logger, 'setUserId', () => _analytics.setUserId(id: id));

  @override
  Future<void> setCollectionEnabled({required bool enabled}) => guarded(
    _logger,
    'setCollectionEnabled',
    () => _analytics.setAnalyticsCollectionEnabled(enabled),
  );
}
