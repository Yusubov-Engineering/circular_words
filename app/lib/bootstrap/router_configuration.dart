import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:design_system/design_system.dart';
import 'package:levels_api/levels_api.dart';
import 'package:levels_impl/levels_impl.dart';
import 'package:rosco_impl/rosco_impl.dart';
import 'package:router_api/router_api.dart';
import 'package:router_impl/router_impl.dart';

/// {@template router_configuration}
/// Assembles every feature's routes into one router.
///
/// Feature facades are resolved *before* [AppNavigationService] is registered,
/// which is why a launcher must never hold one — it returns a request and
/// lets the caller navigate.
/// {@endtemplate}
final class RouterConfiguration._() {
  static AppRouterConfig initialize(DependencyContainer container) {
    final levels = container<LevelsApi>();

    final config = AppGoRouterConfig(
      initialLocation: levels.launcher.root().routeInfo,
      // Set once here rather than per route: every screen arrives the same
      // way, and a route overrides it only if it has a reason to differ.
      defaultPresentationMode: const CustomPresentationMode(
        transitionsBuilder: appFadeThrough,
        transitionDuration: appFadeThroughDuration,
        reverseTransitionDuration: appFadeThroughDuration,
      ),
      routerModules: [
        LevelsModuleRouter(),
        RoscoModuleRouter(),
        // <generated:feature-routers>
      ],
    );

    container.registerLazySingleton<AppNavigationService>(
      (_) => GoRouterNavigationService(config.config),
    );

    return config;
  }
}
