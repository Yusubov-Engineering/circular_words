import 'package:flutter/widgets.dart';

import '../components/app_text.dart';
import '../ext/app_theme_ext.dart';

/// {@template app_count_up}
/// Shows [value], counting up to it from zero on first build and from the
/// previous value whenever it changes.
///
/// Read aloud as the final number only: a screen reader announcing every
/// intermediate value would be noise.
/// {@endtemplate}
class const AppCountUp({
  required final int value,
  final TextStyle? style,
  final TextAlign? textAlign,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final motion = context.motion;

    return Semantics(
      label: '$value',
      excludeSemantics: true,
      child: TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: value),
        // Twice the arrival time: a count is read, not glanced at.
        duration: motion.slow * 2,
        curve: motion.standard,
        builder: (context, shown, _) =>
            AppText(title: '$shown', style: style, textAlign: textAlign),
      ),
    );
  }
}
