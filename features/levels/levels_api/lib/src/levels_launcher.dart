import 'package:router_api/router_api.dart';

/// {@template levels_launcher}
/// The addresses this feature can be entered at.
///
/// A launcher *returns* a request rather than navigating, so the caller picks
/// the verb and the launcher stays `const` and dependency-free.
/// {@endtemplate}
abstract interface class LevelsLauncher {
  /// The feature's entry point.
  AppRouteRequest root();
}
