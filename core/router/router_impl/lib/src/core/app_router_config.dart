import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:router_api/router_api.dart';

import 'app_route_mapper.dart';

/// The central protocol for the routing configuration setup classes
abstract interface class AppRouterConfig<T extends RouterConfig<Object>> {
  late final T config;
}

/// The central configuration class that initializes the underlying `GoRouter`.
///
/// This class aggregates routes from all injected [AppModuleRouter]s, maps them
/// using the [AppRouteMapper], and provides the singleton router instance to the app.
final class AppGoRouterConfig extends AppRouterConfig<GoRouter> {
  /// Bootstraps the application router.
  ///
  /// Requires a list of [routerModules] to pull routes from, and a mapper to
  /// convert them into `go_router` objects.
  ///
  /// Pass a [refreshListenable] — such as the auth state notifier — to have the
  /// [guards] re-evaluated every time it notifies, so state changes relocate
  /// the app without any call site navigating.
  ///
  /// [defaultPresentationMode] is how every route that does not pick its own
  /// presentation mode is shown — the one place to set an app-wide transition.
  AppGoRouterConfig({
    required List<AppModuleRouter> routerModules,
    required AppRouteInfo initialLocation,
    List<NavigatorObserver>? observers,
    bool debugLogDiagnostics = false,
    List<AppRouteGuard>? guards,
    GlobalKey<NavigatorState>? navigatorKey,
    Listenable? refreshListenable,
    AppRoutePresentationMode defaultPresentationMode =
        const NativePresentationMode(),
  }) {
    // 1. Use the provided key, or create a new one if none was provided
    final rootNavigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();

    // 2. Gather all routes from registered feature modules
    final allAppRoutes = routerModules
        .expand((module) => module.routes)
        .toList();

    // 3. Initialize mapper for mapping from domain to go_router
    final mapper = GoRouterMapper(
      rootNavigatorKey,
      defaultPresentationMode: defaultPresentationMode,
    );

    // 4. Map domain routes to GoRouter routes
    final goRoutes = allAppRoutes.map(mapper.map).toList();

    // 5. Initialize GoRouter with the mapped routes
    config = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation.path,
      routes: goRoutes,
      observers: observers,
      debugLogDiagnostics: debugLogDiagnostics,
      refreshListenable: refreshListenable,
      redirect: (context, state) async {
        if (guards == null || guards.isEmpty) return null;

        final rawArgs = AppRouteArguments(
          matchedPath: state.fullPath ?? state.uri.path,
          routeName: state.name,
          pathParameters: state.pathParameters,
          queryParameters: state.uri.queryParameters,
          extra: state.extra,
        );

        for (final guard in guards) {
          final redirectRequest = await guard.redirect(context, rawArgs);

          if (redirectRequest != null) {
            if (!context.mounted) return null;

            final targetLocation = context.namedLocation(
              redirectRequest.routeInfo.name,
              pathParameters: redirectRequest.pathParameters,
              queryParameters: redirectRequest.queryParameters,
            );

            if (state.uri.path == targetLocation) continue;

            return targetLocation;
          }
        }

        return null;
      },
    );
  }
}
