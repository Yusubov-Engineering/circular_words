import 'package:router_api/router_api.dart';

import '../result/result_screen.dart';
import '../rosco/rosco_screen.dart';
import 'rosco_args.dart';
import 'rosco_result_args.dart';
import 'rosco_route_info.dart';

/// {@template rosco_module_router}
/// This module's slice of the navigation graph.
/// {@endtemplate}
final class RoscoModuleRouter({
  final List<AppModuleRouter> nestedRouters = const [],
}) implements AppModuleRouter {
  @override
  List<AppModuleRoute> get routes => [
    AppPageRoute<RoscoArgs>(
      routeInfo: RoscoRouteInfo.game,
      argsParser: RoscoArgs.fromRaw,
      routeBuilder: (context, args) => RoscoScreen(level: args.level),
      subRoutes: [
        // Nested, so the result of a round is addressable as part of that
        // round rather than as a screen floating on its own.
        AppPageRoute<RoscoResultArgs>(
          routeInfo: RoscoRouteInfo.result,
          argsParser: RoscoResultArgs.fromRaw,
          routeBuilder: (context, args) => ResultScreen(args: args),
        ),
      ],
    ),
    for (final router in nestedRouters) ...router.routes,
  ];
}
