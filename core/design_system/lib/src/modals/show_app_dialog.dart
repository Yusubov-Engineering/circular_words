// core/design_system/lib/src/dialogs/show_app_dialog.dart
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../design_system.dart';

/// A pure widgets.dart dialog launcher that enforces our design system's
/// animations, barriers, and routing rules.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color barrierColor = const Color(0x99000000),
}) {
  return showRawDialog<T>(
    context: context,
    builder: (context) {
      final maxAvailableWidth = context.width * 0.85;
      final safeWidth = min(maxAvailableWidth, 343).toDouble();

      return UnconstrainedBox(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: safeWidth),
          child: builder(context),
        ),
      );
    },
    routeBuilder: (routeContext, childBuilder) {
      return RawDialogRoute<T>(
        pageBuilder: (ctx, anim, secondaryAnim) => childBuilder(ctx),
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: 'Dismiss',
        transitionDuration: const Duration(milliseconds: 250),
        transitionBuilder: (ctx, anim, secondaryAnim, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
      );
    },
  );
}
