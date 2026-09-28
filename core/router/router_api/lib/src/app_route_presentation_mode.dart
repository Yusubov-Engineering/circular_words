import 'package:flutter/widgets.dart';

/// Defines how a route is presented onto the screen.
sealed class AppRoutePresentationMode {
  const AppRoutePresentationMode();
}

/// The default platform routing animation (Slide up for Material, etc.)
class NativePresentationMode extends AppRoutePresentationMode {
  const NativePresentationMode();
}

/// Snaps to the screen instantly with no animation.
class NoTransitionPresentationMode extends AppRoutePresentationMode {
  const NoTransitionPresentationMode();
}

/// Animates the route in and out with a transition the app supplies.
///
/// The builder receives the route's own animation and the secondary animation
/// driven by the route pushed on top of it, exactly as a `PageRouteBuilder`
/// does, so a transition can move both the incoming and the outgoing screen.
class CustomPresentationMode extends AppRoutePresentationMode {
  const CustomPresentationMode({
    required this.transitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
  });

  final RouteTransitionsBuilder transitionsBuilder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
}
