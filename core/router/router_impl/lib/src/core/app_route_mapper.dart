import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:router_api/router_api.dart';

import 'go_router_stateful_shell.dart';

abstract interface class AppRouteMapper<T> {
  T map(AppModuleRoute route);
}

/// Converts our domain-specific [AppModuleRoute]s into `go_router` specific [RouteBase]s.
final class GoRouterMapper implements AppRouteMapper<RouteBase> {
  GoRouterMapper(
    this.rootNavigatorKey, {
    this.defaultPresentationMode = const NativePresentationMode(),
  });

  final GlobalKey<NavigatorState> rootNavigatorKey;

  /// Used by every route that does not choose a presentation mode itself.
  final AppRoutePresentationMode defaultPresentationMode;

  /// Maps an [AppModuleRoute] to a `go_router` compatible [RouteBase].
  ///
  /// Throws an [UnsupportedError] if a new subclass of [AppModuleRoute] is added
  /// but not handled here.
  @override
  RouteBase map(AppModuleRoute route) {
    if (route is AppPageRoute) {
      return GoRoute(
        parentNavigatorKey: route.useRootNavigator ? rootNavigatorKey : null,
        name: route.routeInfo.name,
        path: route.routeInfo.path,
        pageBuilder: (context, state) {
          final childWidget = _buildWrappedWidget(context, state, route);
          final routeName = state.name ?? route.routeInfo.name;

          return switch (route.presentationMode ?? defaultPresentationMode) {
            NativePresentationMode() => _buildNativePage(
              context,
              state.pageKey,
              routeName,
              childWidget,
            ),
            NoTransitionPresentationMode() => NoTransitionPage(
              key: state.pageKey,
              name: routeName,
              child: childWidget,
            ),
            CustomPresentationMode(
              :final transitionsBuilder,
              :final transitionDuration,
              :final reverseTransitionDuration,
            ) =>
              CustomTransitionPage(
                key: state.pageKey,
                name: routeName,
                child: childWidget,
                transitionsBuilder: transitionsBuilder,
                transitionDuration: transitionDuration,
                reverseTransitionDuration: reverseTransitionDuration,
              ),
          };
        },
        routes: route.subRoutes.map(map).toList(),
      );
    }

    if (route is AppShellRoute) {
      return ShellRoute(
        builder: (context, state, child) => route.shellBuilder(context, child),
        routes: route.subRoutes.map(map).toList(),
      );
    }

    if (route is AppStatefulShellRoute) {
      return StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final appStatefulShell = GoRouterStatefulShell(navigationShell);
          return route.shellBuilder(context, appStatefulShell, navigationShell);
        },
        branches: route.branches
            .map(
              (branch) =>
                  StatefulShellBranch(routes: branch.routes.map(map).toList()),
            )
            .toList(),
      );
    }

    throw UnsupportedError('Unknown AppRoute type: ${route.runtimeType}');
  }

  /// Private helper that creates the Widget and handles the Auto-Wrapping
  Widget _buildWrappedWidget<T>(
    BuildContext context,
    GoRouterState state,
    AppPageRoute<T> route,
  ) {
    // 1. Gather raw arguments from go_router
    final rawArgs = AppRouteArguments(
      matchedPath: state.matchedLocation,
      routeName: state.name,
      pathParameters: state.pathParameters,
      queryParameters: state.uri.queryParameters,
      extra: state.extra,
    );

    // ✨ 2. Delegate everything else directly to AppPageRoute!
    // It already knows its type [T], parses the args, evaluates predicates,
    // and handles web-refresh fallbacks internally.
    final pageWidget = route.buildWidget(context, rawArgs);
    var wrappedPage = pageWidget;

    if (pageWidget is AppRouteWrapper) {
      wrappedPage = (pageWidget as AppRouteWrapper).wrappedRoute(context);
    }

    return wrappedPage;
  }

  // ✨ Helper to maintain adaptive native transitions (Android vs iOS) while injecting the name
  Page<dynamic> _buildNativePage(
    BuildContext context,
    LocalKey key,
    String name,
    Widget child,
  ) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return CupertinoPage(key: key, name: name, child: child);
    } else if (platform == TargetPlatform.android) {
      return MaterialPage(key: key, name: name, child: child);
    }

    return NoTransitionPage(key: key, name: name, child: child);
  }
}
