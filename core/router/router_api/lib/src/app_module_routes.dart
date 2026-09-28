// it is okey for routing system to declare general T type
// ignore_for_file: no_raw_types, strict_raw_type, unsafe_variance

import 'package:flutter/widgets.dart';

import 'app_route_arguments.dart';
import 'app_route_builder.dart';
import 'app_route_info.dart';
import 'app_route_presentation_mode.dart';
import 'app_route_wrapper.dart';
import 'app_shell_builder.dart';
import 'app_stateful_shell_builder.dart';

/// The base sealed class for all application routes.
sealed class AppModuleRoute {
  const AppModuleRoute();
}

/// Represents a standard screen or page in the application.
final class AppPageRoute<T> extends AppModuleRoute {
  /// Creates a route that builds a standard page.
  const AppPageRoute({
    required this.routeInfo,
    required this.argsParser,
    required this.routeBuilder,
    this.subRoutes = const [],
    this.presentationMode,
    this.useRootNavigator = false,
    this.fallbackRoute,
    this.fallbackPredicate,
  });

  /// The strongly-typed path and name information for this route.
  final AppRouteInfo routeInfo;

  /// Converts raw string-based URL arguments into the domain object [T].
  final T Function(AppRouteArguments rawArgs) argsParser;

  /// The builder function that constructs the widget for this route.
  ///
  /// If the returned widget implements [AppRouteWrapper], it will be
  /// automatically wrapped with its dependencies (e.g., BlocProviders)
  /// before being rendered.
  final AppRouteBuilder<T> routeBuilder;

  /// A list of nested child routes (e.g., `/parent/child`).
  final List<AppPageRoute> subRoutes;

  /// Defines how this route is visually presented on the screen.
  ///
  /// Used to display the route without transitions, with default native
  /// platform animations, or with a custom transition. Left `null`, the route
  /// uses the router's default, so an app sets its transition once rather
  /// than on every route.
  final AppRoutePresentationMode? presentationMode;

  /// Whether to push this route onto the root navigator.
  ///
  /// If `true`, this route will be pushed "full screen", completely covering
  /// any persistent UI (like a BottomNavigationBar or Sidebar) that exists
  /// in a parent shell route.
  final bool useRootNavigator;

  /// Optional validation check. Evaluated using the strongly-typed [T] arguments.
  final bool Function(T args)? fallbackPredicate;

  /// The route to redirect to if the [fallbackPredicate] fails or web refresh clears state.
  final AppRouteInfo? fallbackRoute;

  /// An internal helper used by the Mapper to safely resolve generics.
  Widget buildWidget(BuildContext context, AppRouteArguments rawArgs) {
    try {
      final parsedArgs = argsParser(rawArgs);
      return routeBuilder(context, parsedArgs);
    } catch (_) {
      rethrow;
    }
  }
}

/// Represents a nested navigation layout, such as a BottomNavigationBar or Sidebar.
///
/// The [shellBuilder] creates the UI wrapper, and the nested [subRoutes] will be
/// rendered inside the `child` parameter of the shell.
final class AppShellRoute extends AppModuleRoute {
  /// Creates a shell route for nested layouts.
  const AppShellRoute({required this.shellBuilder, required this.subRoutes});

  /// The builder that constructs the outer layout (the shell).
  final AppShellBuilder shellBuilder;

  /// The child routes that will be rendered within the shell.
  final List<AppModuleRoute> subRoutes;
}

/// Represents a single independent tab/branch in a StatefulShellRoute.
final class AppStatefulShellBranch {
  const AppStatefulShellBranch({required this.routes});

  /// The routes belonging to this specific branch's navigation stack.
  final List<AppModuleRoute> routes;
}

/// A route that maintains independent state and navigation stacks for its children.
final class AppStatefulShellRoute extends AppModuleRoute {
  const AppStatefulShellRoute({
    required this.shellBuilder,
    required this.branches,
  });

  /// Builds the outer UI (like the BottomNavigationBar).
  final AppStatefulShellBuilder shellBuilder;

  /// The isolated branches (tabs) for this stateful shell.
  final List<AppStatefulShellBranch> branches;
}
