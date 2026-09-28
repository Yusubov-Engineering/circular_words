import 'package:go_router/go_router.dart';
import 'package:router_api/router_api.dart';

/// The concrete GoRouter implementation of our navigation service.
final class GoRouterNavigationService implements AppNavigationService {
  GoRouterNavigationService(this._router);

  final GoRouter _router;

  @override
  void goRoute(AppRouteRequest request) => _router.goNamed(
    request.routeInfo.name,
    pathParameters: request.pathParameters,
    queryParameters: request.queryParameters,
    extra: request.extra,
  );

  @override
  Future<T?> pushRoute<T extends Object?>(AppRouteRequest request) =>
      _router.pushNamed<T>(
        request.routeInfo.name,
        pathParameters: request.pathParameters,
        queryParameters: request.queryParameters,
        extra: request.extra,
      );

  @override
  Future<T?> replaceRoute<T>(AppRouteRequest request) => _router.replaceNamed(
    request.routeInfo.name,
    pathParameters: request.pathParameters,
    queryParameters: request.queryParameters,
    extra: request.extra,
  );

  @override
  void popRoute<T extends Object?>([T? result]) {
    if (_router.canPop()) {
      _router.pop(result);
    }
  }

  @override
  void popUntilRoute(AppRouteInfo routeInfo) {
    final navigator = _router.routerDelegate.navigatorKey.currentState;
    if (navigator == null) return;

    navigator.popUntil((route) {
      final settingName = route.settings.name;
      if (settingName == null) return false;
      return settingName == routeInfo.path ||
          settingName == routeInfo.name ||
          settingName.endsWith(routeInfo.path) ||
          settingName.contains(routeInfo.name);
    });
  }

  @override
  bool canPopRoute() => _router.canPop();

  @override
  bool maybePopRoute<T extends Object?>([T? result]) {
    if (_router.canPop()) {
      _router.pop<T>(result);
      return true;
    }

    return false;
  }
}
