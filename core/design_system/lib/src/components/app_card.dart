import 'package:flutter/widgets.dart';

import '../ext/app_theme_ext.dart';
import 'app_pressable.dart';

/// {@template app_card}
/// A raised surface, tappable when [onTap] is set.
///
/// [highlighted] tints it with the current accent — for the item that is
/// selected, current, or otherwise the one the eye should find first.
/// {@endtemplate}
class const AppCard({
  required final Widget child,
  final VoidCallback? onTap,
  final bool highlighted = false,
  final String? semanticsLabel,
  final EdgeInsetsGeometry? padding,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    final motion = context.motion;

    final surface = AnimatedContainer(
      duration: motion.medium,
      curve: motion.standard,
      padding: padding ?? EdgeInsets.all(context.spacing.spacingLg),
      decoration: BoxDecoration(
        color: highlighted
            ? accent.accentSoft
            : context.backgroundColors.bgSecondary,
        borderRadius: BorderRadius.circular(context.radii.radiusXl),
        border: Border.all(
          color: highlighted
              ? accent.accentSoftBorder
              : context.borderColors.borderSecondary,
        ),
      ),
      child: child,
    );

    if (onTap == null) {
      return semanticsLabel == null
          ? surface
          : Semantics(
              label: semanticsLabel,
              excludeSemantics: true,
              child: surface,
            );
    }

    return AppPressable(
      onTap: onTap,
      semanticsLabel: semanticsLabel,
      // A card is large; the full press scale reads as the whole row lurching.
      pressedScale: 1 - (1 - motion.pressedScale) / 2,
      child: surface,
    );
  }
}
