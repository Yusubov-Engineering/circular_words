import 'dart:async';

import 'package:analytics_api/analytics_api.dart';
import 'package:flutter/widgets.dart';

/// Turns a route into the screen name analytics records, or `null` to skip it.
typedef ScreenNameExtractor = String? Function(RouteSettings settings);

String? _routeName(RouteSettings settings) => settings.name;

/// {@template analytics_route_observer}
/// Records a screen view whenever the visible page changes.
///
/// Pass it to the router's `observers`. Only page routes count — a dialog or
/// a bottom sheet is not a new screen — and a route with no name is skipped,
/// since an unnamed screen view cannot be told apart from any other.
///
/// Name routes for analytics with `screenName`; the default is the route's
/// own name. Map anything carrying user data in its path (an id, a search
/// term) to a fixed name there.
/// {@endtemplate}
class AnalyticsRouteObserver extends NavigatorObserver {
  /// {@macro analytics_route_observer}
  AnalyticsRouteObserver({
    required this._analytics,
    this._screenName = _routeName,
  });

  final AnalyticsApi _analytics;
  final ScreenNameExtractor _screenName;

  void _record(Route<dynamic>? route) {
    if (route is! PageRoute<dynamic>) return;
    final name = _screenName(route.settings);
    if (name == null || name.isEmpty) return;
    unawaited(_analytics.logScreenView(name));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _record(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _record(newRoute);

  // Popping back shows the previous screen again, and that is a view too.
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _record(previousRoute);
}
