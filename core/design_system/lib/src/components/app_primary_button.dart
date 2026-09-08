import 'package:flutter/widgets.dart';

import '../ext/app_theme_ext.dart';
import '../ext/font_weight_ext.dart';
import 'app_text.dart';

class const AppPrimaryButton({
  required final String title,
  final VoidCallback? onTap,
  final bool enabled = true,
  super.key,
}) extends StatefulWidget {
  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.enabled
        ? context.backgroundColors.bgBrand
        : context.backgroundColors.bgDisabled;

    final textColor = widget.enabled
        ? context.foregroundColors.fgWhite
        : context.foregroundColors.fgDisabled;

    final border = widget.enabled
        ? null
        : Border.all(color: context.borderColors.borderDisabledSubtle);

    // Without this a screen reader reads the label as loose text with no hint
    // that it does anything: `GestureDetector` contributes no semantics of its
    // own. `excludeSemantics` stops the inner `AppText` announcing the label a
    // second time.
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.title,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: widget.enabled
              ? () => setState(() => _isPressed = false)
              : null,
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedOpacity(
            opacity: _isPressed ? 0.7 : 1.0,
            duration: const Duration(milliseconds: 50),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(context.radii.radiusMd),
                border: border,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.spacing.spacingLg,
                ),
                child: Center(
                  child: AppText(
                    title: widget.title,
                    style: context.typography.textMd.semiBold.copyWith(
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
