import 'package:router_api/router_api.dart';

/// The addresses this module owns.
///
/// Deliberately **not** exported from `levels_impl.dart`: other modules
/// navigate here through `LevelsLauncher`, never by naming a path.
final class LevelsRouteInfo {
  const LevelsRouteInfo._();

  static const root = AppRouteInfo(path: '/levels', name: 'levels');
}
