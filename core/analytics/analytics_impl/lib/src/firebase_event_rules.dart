/// {@template firebase_event_rules}
/// Firebase's rules for event and parameter names and values, applied before
/// anything is sent.
///
/// Firebase rejects a bad event *silently*, or asserts in debug builds —
/// either way the event is lost where no one sees it. Applying the rules here
/// turns a mistake into a logged warning instead, and adapts what can be
/// adapted: a `bool`, which Firebase does not accept, is sent as `'true'` or
/// `'false'`; an over-long string is cut to the limit.
/// {@endtemplate}
final class FirebaseEventRules {
  /// {@macro firebase_event_rules}
  const FirebaseEventRules();

  static const maxNameLength = 40;
  static const maxStringLength = 100;
  static const maxParameters = 25;

  static final _name = RegExp(r'^[A-Za-z][A-Za-z0-9_]*$');
  static const _reservedPrefixes = ['firebase_', 'google_', 'ga_'];

  /// Names Firebase logs itself and refuses from an app.
  static const reservedEventNames = {
    'ad_activeview',
    'ad_click',
    'ad_exposure',
    'ad_query',
    'ad_reward',
    'adunit_exposure',
    'app_background',
    'app_clear_data',
    'app_exception',
    'app_remove',
    'app_store_refund',
    'app_store_subscription_cancel',
    'app_store_subscription_convert',
    'app_store_subscription_renew',
    'app_uninstall',
    'app_update',
    'app_upgrade',
    'dynamic_link_app_open',
    'dynamic_link_app_update',
    'dynamic_link_first_open',
    'error',
    'first_open',
    'first_visit',
    'in_app_purchase',
    'notification_dismiss',
    'notification_foreground',
    'notification_open',
    'notification_receive',
    'os_update',
    'session_start',
    'session_start_with_rollout',
    'user_engagement',
  };

  /// Why [name] cannot be sent as an event name, or `null` if it can.
  String? rejectEventName(String name) {
    final problem = _rejectName(name);
    if (problem != null) return problem;
    if (reservedEventNames.contains(name)) return 'is reserved by Firebase';
    return null;
  }

  /// [parameters] as Firebase will accept them, with a note for each one
  /// that had to be dropped.
  ({Map<String, Object> parameters, List<String> dropped}) adaptParameters(
    Map<String, Object> parameters,
  ) {
    final adapted = <String, Object>{};
    final dropped = <String>[];

    for (final MapEntry(:key, :value) in parameters.entries) {
      final problem = _rejectName(key);
      if (problem != null) {
        dropped.add('$key $problem');
        continue;
      }
      if (adapted.length == maxParameters) {
        dropped.add('$key is over the limit of $maxParameters parameters');
        continue;
      }
      switch (value) {
        case num():
          adapted[key] = value;
        case bool():
          adapted[key] = value.toString();
        case String():
          adapted[key] = value.length <= maxStringLength
              ? value
              : value.substring(0, maxStringLength);
        default:
          dropped.add('$key has a ${value.runtimeType} value');
      }
    }
    return (parameters: adapted, dropped: dropped);
  }

  String? _rejectName(String name) {
    if (name.isEmpty) return 'is empty';
    if (name.length > maxNameLength) {
      return 'is longer than $maxNameLength characters';
    }
    if (!_name.hasMatch(name)) {
      return 'must be letters, digits and underscores, starting with a letter';
    }
    for (final prefix in _reservedPrefixes) {
      if (name.startsWith(prefix)) return 'uses the reserved prefix $prefix';
    }
    return null;
  }
}
