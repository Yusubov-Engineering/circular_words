import 'package:levels_api/levels_api.dart';
import 'package:router_api/router_api.dart';

import '../router/levels_route_info.dart';

/// Turns this module's private addresses into requests other modules can use.
final class LevelsLauncherImpl implements LevelsLauncher {
  const LevelsLauncherImpl();

  @override
  AppRouteRequest root() =>
      const AppRouteRequest(routeInfo: LevelsRouteInfo.root);
}
