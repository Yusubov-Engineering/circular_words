import 'package:router_api/router_api.dart';

import 'cefr_level.dart';

/// {@template rosco_launcher}
/// The addresses this feature can be entered at.
///
/// A launcher *returns* a request rather than navigating, so the caller picks
/// the verb and the launcher stays `const` and dependency-free.
/// {@endtemplate}
abstract interface class RoscoLauncher {
  /// A round at [level].
  ///
  /// The only way into the game from outside this module: callers name a
  /// level, never a path.
  AppRouteRequest game({required CefrLevel level});
}
