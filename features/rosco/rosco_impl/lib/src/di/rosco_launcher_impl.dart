import 'package:rosco_api/rosco_api.dart';
import 'package:router_api/router_api.dart';

import '../router/rosco_route_info.dart';

/// Turns this module's private addresses into requests other modules can use.
final class RoscoLauncherImpl implements RoscoLauncher {
  const RoscoLauncherImpl();

  @override
  AppRouteRequest game({required CefrLevel level}) => AppRouteRequest(
    routeInfo: RoscoRouteInfo.game,
    pathParameters: {'level': level.id},
  );
}
