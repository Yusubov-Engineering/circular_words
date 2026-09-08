import 'package:router_api/router_api.dart';

import '../levels/levels_screen.dart';
import 'levels_route_info.dart';

/// {@template levels_module_router}
/// This module's slice of the navigation graph.
/// {@endtemplate}
final class LevelsModuleRouter({
  final List<AppModuleRouter> nestedRouters = const [],
}) implements AppModuleRouter {
  @override
  List<AppModuleRoute> get routes => [
    AppPageRoute(
      routeInfo: LevelsRouteInfo.root,
      argsParser: RouteNoArgs.fromRaw,
      routeBuilder: (context, _) => const LevelsScreen(),
    ),
    for (final router in nestedRouters) ...router.routes,
  ];
}
