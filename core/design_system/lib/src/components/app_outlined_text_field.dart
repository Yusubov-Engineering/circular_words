import 'package:flutter/widgets.dart';

import '../ext/app_theme_ext.dart';
import '../ext/font_weight_ext.dart';

class AppOutlinedTextField extends StatefulWidget {
  const AppOutlinedTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.textStyle,
    this.cursorColor,
    this.obscureText = false,
    this.obscuringCharacter = '*',
    this.hintText,
    this.suffix,
  });
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextStyle? textStyle;
  final Color? cursorColor;
  final bool obscureText;
  final String obscuringCharacter;
  final String? hintText;
  final Widget? suffix;

  @override
  State<AppOutlinedTextField> createState() => _AppOutlinedTextFieldState();
}

class _AppOutlinedTextFieldState extends State<AppOutlinedTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.requestFocus(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColors.borderPrimary),
            borderRadius: BorderRadius.circular(context.radii.radiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.spacingLg,
            vertical: context.spacing.spacingMd,
          ),
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    if (widget.hintText != null)
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, child) {
                          if (value.text.isNotEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            widget.hintText!,
                            style: context.typography.textMd.regular.copyWith(
                              color: context.textColors.textPlaceHolder,
                            ),
                          );
                        },
                      ),
                    EditableText(
                      controller: _controller,
                      focusNode: _focusNode,
                      style:
                          widget.textStyle ??
                          context.typography.textMd.regular.copyWith(
                            color: context.textColors.textPrimary,
                          ),
                      cursorColor:
                          widget.cursorColor ?? const Color(0xFF000000),
                      backgroundCursorColor: const Color(0xFF000000),
                      obscureText: widget.obscureText,
                      obscuringCharacter: widget.obscuringCharacter,
                    ),
                  ],
                ),
              ),
              ?widget.suffix,
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }
}
