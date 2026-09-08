import 'package:router_api/router_api.dart';

/// The addresses this module owns.
///
/// Deliberately **not** exported from `rosco_impl.dart`: other modules
/// navigate here through `RoscoLauncher`, never by naming a path.
final class RoscoRouteInfo {
  const RoscoRouteInfo._();

  /// A round at a level, e.g. `/rosco/b1`.
  static const game = AppRouteInfo(path: '/rosco/:level', name: 'rosco-game');

  /// Nested under [game], so the full path is `/rosco/:level/result`.
  static const result = AppRouteInfo(path: 'result', name: 'rosco-result');
}
