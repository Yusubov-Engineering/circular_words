import 'package:flutter/widgets.dart';

// Page transitions, as `RouteTransitionsBuilder`s the router can be handed.
//
// Kept free of any router type so the design system decides how screens
// *look* coming and going, and the app decides which routes use it.

/// How long an [appFadeThrough] takes. Passed to the router alongside it.
const appFadeThroughDuration = Duration(milliseconds: 360);

/// The outgoing screen fades away first; the incoming one then fades in
/// while growing slightly into place.
///
/// Suits screens that are not spatially related — a level list, a round,
/// a result — where a slide would imply a direction that does not exist.
/// Under reduced motion the screens simply cross-fade.
Widget appFadeThrough(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  if (reduced) return FadeTransition(opacity: animation, child: child);

  final incoming = CurvedAnimation(
    parent: animation,
    curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
    reverseCurve: const Interval(0.3, 1, curve: Curves.easeInCubic),
  );
  final outgoing = CurvedAnimation(
    parent: secondaryAnimation,
    curve: const Interval(0, 0.3, curve: Curves.easeInCubic),
    reverseCurve: const Interval(0, 0.3, curve: Curves.easeOutCubic),
  );

  return FadeTransition(
    opacity: ReverseAnimation(outgoing),
    child: FadeTransition(
      opacity: incoming,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(incoming),
        child: child,
      ),
    ),
  );
}
