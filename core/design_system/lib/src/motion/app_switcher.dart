import 'package:flutter/widgets.dart';

import '../ext/app_theme_ext.dart';

/// {@template app_switcher}
/// Cross-fades from one child to the next, the new one rising slightly into
/// place.
///
/// An `AnimatedSwitcher` with the app's timing already applied. As with any
/// switcher, it animates when the child's *key* or type changes — key the
/// child on the thing whose change is news (the letter, not the clue text),
/// or it will not animate at all.
/// {@endtemplate}
class const AppSwitcher({
  required final Widget child,
  final AlignmentGeometry alignment = Alignment.center,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final motion = context.motion;

    return AnimatedSwitcher(
      duration: motion.medium,
      switchInCurve: motion.standard,
      switchOutCurve: motion.exit,
      layoutBuilder: (current, previous) =>
          Stack(alignment: alignment, children: [...previous, ?current]),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, (1 - animation.value) * motion.enterOffset / 2),
            child: child,
          ),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
