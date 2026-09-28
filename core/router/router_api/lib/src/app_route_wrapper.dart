import 'package:flutter/widgets.dart';

/// An interface for route widgets that need to wrap themselves
/// in providers (like BlocProvider) before being pushed to the screen.
abstract interface class AppRouteWrapper {
  /// Returns the widget wrapped with its necessary dependencies.
  Widget wrappedRoute(BuildContext context);
}
